defmodule WeChat.Refresher.DefaultSettings do
  @moduledoc """
  刷新 `AccessToken` 的方法
  """

  require Logger
  alias WeChat.{Account, WebPage, Component, MiniProgram, Work, Utils, Storage.Cache}

  @type key_name :: atom
  @type token :: String.t()
  @type expires_in :: non_neg_integer
  @type token_list :: [{key_name, token, expires_in}]
  @type refresh_fun_result ::
          {:ok, token, expires_in} | {:ok, token_list, expires_in} | {:error, any}
  @type refresh_fun :: (WeChat.client() -> refresh_fun_result)
  @type refresh_option :: {WeChat.Storage.Adapter.store_id(), key_name, refresh_fun}
  @type refresh_options :: [refresh_option]

  @doc """
  根据不同的 `client` 的 `app_type` & `by_component?` 输出不同的 `refresh_options`

  rules:
  - `by_component?` == `true`: `component_refresh_options/1`
  - `official_account`: `official_account_refresh_options/1`
  - `mini_program`: `mini_program_refresh_options/1`
  """
  @spec get_refresh_options_by_client(WeChat.client()) :: refresh_options
  def get_refresh_options_by_client(client) do
    if client.by_component?() do
      component_refresh_options(client)
    else
      if match?(:hub_client, client.server_role()) and match?(nil, client.storage()) do
        raise RuntimeError,
              "Not accept storage: nil when server_role: :hub_client, please set a module for :storage when defining #{inspect(client)}."
      end

      case client.app_type() do
        :official_account ->
          check_secret(client, :appsecret)
          official_account_refresh_options(client)

        :mini_program ->
          check_secret(client, :appsecret)
          mini_program_refresh_options(client)

        :work ->
          work_refresh_options(client)
      end
    end
  end

  defp check_secret(client, fun) do
    if client.server_role() != :hub_client do
      unless function_exported?(client, fun, 0) do
        raise RuntimeError, "Please set :appsecret when defining #{inspect(client)}."
      end
    end
  end

  @doc """
  输出[公众号]的 `refresh_options`

  刷新如下 `AccessToken`：
  - `access_token`
  - `js_api_ticket`
  - `wx_card_ticket`
  """
  @spec official_account_refresh_options(WeChat.client()) :: refresh_options
  def official_account_refresh_options(client) do
    appid = client.appid()

    [
      {appid, :access_token, &__MODULE__.refresh_access_token/1},
      {appid, :js_api_ticket, &__MODULE__.refresh_ticket("jsapi", &1)},
      {appid, :wx_card_ticket, &__MODULE__.refresh_ticket("wx_card", &1)}
    ]
  end

  @doc """
  输出[第三方平台]的 `refresh_options`

  刷新如下 `AccessToken`：
  - `component_access_token`
  - AuthorizerRefreshOptions (get by client.app_type())
  """
  @spec component_refresh_options(WeChat.client()) :: refresh_options
  def component_refresh_options(client) do
    component_appid = client.component_appid()
    appid = client.appid()

    case client.app_type() do
      :official_account ->
        check_secret(client, :component_appsecret)

        [
          {component_appid, :component_access_token,
           &__MODULE__.refresh_component_access_token/1},
          {appid, :access_token, &__MODULE__.refresh_authorizer_access_token/1},
          {appid, :js_api_ticket, &__MODULE__.refresh_ticket("jsapi", &1)},
          {appid, :wx_card_ticket, &__MODULE__.refresh_ticket("wx_card", &1)}
        ]

      :mini_program ->
        check_secret(client, :component_appsecret)

        [
          {component_appid, :component_access_token,
           &__MODULE__.refresh_component_access_token/1},
          {appid, :access_token, &__MODULE__.refresh_authorizer_access_token/1}
        ]

        # TODO
        # :work ->
        #   [
        #     {component_appid, :component_access_token,
        #      &__MODULE__.refresh_component_access_token/1},
        #     {appid, :access_token, &__MODULE__.refresh_authorizer_access_token/1}
        #   ]
    end
  end

  @doc """
  输出[小程序]的 `refresh_options`

  刷新如下 `AccessToken`：
  - `access_token`
  """
  @spec mini_program_refresh_options(Work.client()) :: refresh_options
  def mini_program_refresh_options(client),
    do: [
      {client.appid(), :access_token, &__MODULE__.refresh_mini_program_access_token/1}
    ]

  @doc """
  输出[企业微信]的 `refresh_options`

  刷新如下 `AccessToken`：
  - `access_token`
  """
  @spec work_refresh_options(WeChat.client()) :: refresh_options
  def work_refresh_options(client) do
    Enum.flat_map(client.agents(), fn %{
                                        id: agent_id,
                                        cache_id: cache_id,
                                        secret: secret,
                                        refresh_list: refresh_list
                                      } ->
      unless secret do
        raise RuntimeError,
              "Please set :secret for agent:#{agent_id} when defining #{inspect(client)}."
      end

      list =
        refresh_list
        |> List.wrap()
        |> Enum.map(fn
          store_key = :js_api_ticket ->
            {cache_id, store_key,
             &__MODULE__.refresh_work_jsapi_ticket(&1, cache_id, agent_id, store_key, false)}

          store_key = :agent_js_api_ticket ->
            {cache_id, store_key,
             &__MODULE__.refresh_work_jsapi_ticket(&1, cache_id, agent_id, store_key, true)}
        end)

      [
        {cache_id, :access_token, &__MODULE__.refresh_work_access_token(&1, cache_id, agent_id)}
        | list
      ]
    end)
  end

  @spec refresh_access_token(WeChat.client()) :: refresh_fun_result
  def refresh_access_token(client) do
    with :ignore <- get_token_for_hub_client(client, :access_token),
         {:ok, %{status: 200, body: data}} <- Account.get_access_token(client),
         %{"access_token" => access_token, "expires_in" => expires_in} <- data do
      {:ok, access_token, expires_in}
    end
  end

  defp get_store_key_by_ticket_type("jsapi"), do: :js_api_ticket
  defp get_store_key_by_ticket_type("wx_card"), do: :wx_card_ticket

  @spec refresh_ticket(WeChat.WebPage.js_api_ticket_type(), WeChat.client()) :: refresh_fun_result
  def refresh_ticket(ticket_type, client) do
    with store_key <- get_store_key_by_ticket_type(ticket_type),
         :ignore <- get_token_for_hub_client(client, store_key),
         {:ok, %{status: 200, body: data}} <- WebPage.get_ticket(client, ticket_type),
         %{"ticket" => ticket, "expires_in" => expires_in} <- data do
      {:ok, ticket, expires_in}
    end
  end

  @spec refresh_component_access_token(WeChat.client()) :: refresh_fun_result
  def refresh_component_access_token(client) do
    component_appid = client.component_appid()

    with :ignore <- get_token_for_hub_client(client, component_appid, :component_access_token),
         ticket when ticket != nil <- ensure_component_verify_ticket(client),
         {:ok, %{status: 200, body: data}} <- Component.get_component_token(client, ticket),
         %{"component_access_token" => component_access_token, "expires_in" => expires_in} <- data do
      {:ok, component_access_token, expires_in}
    end
  end

  defp ensure_component_verify_ticket(client) do
    store_id = client.component_appid()
    store_key = :component_verify_ticket

    case Cache.get_cache(store_id, store_key) do
      nil ->
        with storage when storage != nil <- client.storage(),
             {:ok, %{"value" => ticket, "expired_time" => expires} = store_map} <-
               storage.restore(store_id, store_key),
             diff <- expires - Utils.now_unix(),
             true <- diff > 0 do
          Cache.put_cache(store_id, store_key, ticket)
          Cache.put_cache({:store_map, store_id}, store_key, store_map)

          Logger.info(
            "Call #{inspect(storage)}.restore(#{store_id}, #{store_key}) succeed, the expires_in is: #{diff}s."
          )

          ticket
        else
          _ -> nil
        end

      ticket ->
        ticket
    end
  end

  @spec refresh_authorizer_access_token(WeChat.client()) :: refresh_fun_result
  def refresh_authorizer_access_token(client) do
    with :ignore <- get_token_for_hub_client(client, :access_token),
         {:ok, %{status: 200, body: data}} <- Component.authorizer_token(client),
         %{
           "authorizer_access_token" => authorizer_access_token,
           "authorizer_refresh_token" => authorizer_refresh_token,
           "expires_in" => expires_in
         } <- data do
      list = [
        {:access_token, authorizer_access_token, expires_in},
        # 官网并未说明有效期是多少，暂定30天有效期
        {:authorizer_refresh_token, authorizer_refresh_token, 30 * 24 * 60 * 60}
      ]

      {:ok, list, expires_in}
    end
  end

  @spec refresh_mini_program_access_token(WeChat.client()) :: refresh_fun_result
  def refresh_mini_program_access_token(client) do
    with :ignore <- get_token_for_hub_client(client, :access_token),
         {:ok, %{status: 200, body: data}} <- MiniProgram.Auth.get_access_token(client),
         %{"access_token" => access_token, "expires_in" => expires_in} <- data do
      {:ok, access_token, expires_in}
    end
  end

  @spec refresh_work_access_token(Work.client(), Cache.cache_id(), Work.agent_id()) ::
          refresh_fun_result
  def refresh_work_access_token(client, cache_id, agent_id) do
    with :ignore <- get_token_for_hub_client(client, cache_id, :access_token),
         {:ok, %{status: 200, body: data}} <- Work.get_access_token(client, agent_id),
         %{"access_token" => access_token, "expires_in" => expires_in} <- data do
      {:ok, access_token, expires_in}
    end
  end

  @spec refresh_work_jsapi_ticket(
          Work.client(),
          Cache.cache_id(),
          Work.agent_id(),
          Cache.cache_sub_key(),
          is_agent :: boolean
        ) :: refresh_fun_result
  def refresh_work_jsapi_ticket(client, cache_id, agent_id, store_key, is_agent) do
    with :ignore <- get_token_for_hub_client(client, cache_id, store_key),
         {:ok, %{status: 200, body: data}} <- Work.get_jsapi_ticket(client, agent_id, is_agent),
         %{"ticket" => ticket, "expires_in" => expires_in} <- data do
      {:ok, ticket, expires_in}
    end
  end

  # return token for hub_client role
  defp get_token_for_hub_client(client, store_id \\ nil, store_key) do
    store_id = store_id || client.appid()

    if match?(:hub_client, client.server_role()) do
      with storage when storage != nil <- client.storage(),
           {:ok, %{"value" => access_token, "expired_time" => expired_time}} <-
             storage.restore(store_id, store_key) do
        expires_in = expired_time - Utils.now_unix()
        {:ok, access_token, expires_in}
      end
    else
      :ignore
    end
  end
end
