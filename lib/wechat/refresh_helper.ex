defmodule WeChat.RefreshHelper do
  @moduledoc """
  帮助模块： 输出刷新 `token` 的列表
  """

  @type store_id_type :: :appid | :component_appid
  @type key_name :: atom
  @type token :: String.t()
  @type expires_in :: non_neg_integer
  @type token_list :: [{key_name, token, expires_in}]
  @type refresh_fun_result ::
          {:ok, token, expires_in} | {:ok, token_list, expires_in} | {:error, any}
  @type refresh_fun :: (WeChat.client() -> refresh_fun_result)
  @type refresh_option :: {store_id_type, key_name, refresh_fun}
  @type refresh_options :: [refresh_option]

  alias WeChat.{Account, WebApp, Component, MiniProgram}

  @doc """
  根据不同的 `client` 的 `role` 输出不同的 `refresh_options`

  role:
  - official_account: `official_account_refresh_options/0`
  - component: `component_refresh_options/1`
  - mini_program: `mini_program_refresh_options/0`
  """
  @spec get_refresh_options_by_client(WeChat.client()) :: refresh_options
  def get_refresh_options_by_client(client) do
    case client.role() do
      :official_account ->
        official_account_refresh_options()

      :component ->
        component_refresh_options(client)

      :mini_program ->
        mini_program_refresh_options()
    end
  end

  @doc """
  输出[公众号]的 `refresh_options`

  刷新如下`token`：
  - `access_token`
  - `js_api_ticket`
  - `wx_card_ticket`
  """
  @spec official_account_refresh_options() :: refresh_options
  def official_account_refresh_options,
    do: [
      {:appid, :access_token, &__MODULE__.refresh_access_token/1},
      {:appid, :js_api_ticket, &__MODULE__.refresh_ticket("jsapi", &1)},
      {:appid, :wx_card_ticket, &__MODULE__.refresh_ticket("wx_card", &1)}
    ]

  @doc """
  输出[第三方平台]的 `refresh_options`

  刷新如下`token`：
  - `component_access_token`
  - AuthorizerRefreshOptions (get by client.app_type())
  """
  @spec component_refresh_options(WeChat.client()) :: refresh_options
  def component_refresh_options(client) do
    authorizer_refresh_options =
      case client.app_type do
        :official_account -> official_account_refresh_options()
        :mini_program -> mini_program_refresh_options()
      end

    [
      {:component_appid, :component_access_token, &__MODULE__.refresh_component_access_token/1}
      | authorizer_refresh_options
    ]
  end

  @doc """
  输出[小程序]的 `refresh_options`

  刷新如下`token`：
  - `access_token`
  """
  @spec mini_program_refresh_options() :: refresh_options
  def mini_program_refresh_options,
    do: [
      {:appid, :access_token, &__MODULE__.refresh_mini_program_access_token/1}
    ]

  @spec refresh_access_token(WeChat.client()) :: refresh_fun_result
  def refresh_access_token(client) do
    with {:ok, %{status: 200, body: data}} <- Account.get_access_token(client),
         %{"access_token" => access_token, "expires_in" => expires_in} <- data do
      {:ok, access_token, expires_in}
    end
  end

  @spec refresh_ticket(WeChat.WebApp.js_api_ticket_type(), WeChat.client()) :: refresh_fun_result
  def refresh_ticket(ticket_type, client) do
    with {:ok, %{status: 200, body: data}} <- WebApp.get_ticket(client, ticket_type),
         %{"ticket" => ticket, "expires_in" => expires_in} <- data do
      {:ok, ticket, expires_in}
    end
  end

  @spec refresh_component_access_token(WeChat.client()) :: refresh_fun_result
  def refresh_component_access_token(client) do
    with {:ok, %{status: 200, body: data}} <- Component.get_component_token(client),
         %{"component_access_token" => component_access_token, "expires_in" => expires_in} <- data do
      {:ok, component_access_token, expires_in}
    end
  end

  @spec refresh_authorizer_access_token(WeChat.client()) :: refresh_fun_result
  def refresh_authorizer_access_token(client) do
    with {:ok, %{status: 200, body: data}} <- Component.authorizer_token(client),
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
    with {:ok, %{status: 200, body: data}} <- MiniProgram.Auth.get_access_token(client),
         %{"access_token" => access_token, "expires_in" => expires_in} <- data do
      {:ok, access_token, expires_in}
    end
  end
end
