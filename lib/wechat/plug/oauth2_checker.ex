if Code.ensure_loaded?(Plug) do
  defmodule WeChat.Plug.OAuth2Checker do
    @moduledoc """
    网页授权

    [官方文档](https://developers.weixin.qq.com/doc/offiaccount/OA_Web_Apps/Wechat_webpage_authorization.html){:target="_blank"}

    工作流程:
    1. 检查 `session`, 判断是否已经有授权，有则继续执行后续的 plug, 没有则跳到步骤 2;
    2. 检查 `query` 是否有 `code`, 有则执行 `oauth2_callback_fun` 函数, 没有则跳到步骤 3;
    3. 执行 `authorize_url_fun` 函数，跳转到 `authorize_url`.

    ## Usage

        plug #{inspect(__MODULE__)}, clients: [Client]

    可选参数:

    - `:oauth2_callback_fun`: `t:__MODULE__.oauth2_callback_fun/5`
    - `:authorize_url_fun`: `t:__MODULE__.authorize_url_fun/4`

    ** 注意 **: 服务器角色为 `hub_client` 时，请确保已经配置 `hub_springboard_url`:

        WeChat.set_hub_springboard_url(Client, "https://wx.example.com")

    ## Usage

    将下面的代码加到 `router` 里面：

      ```elixir
      pipeline :oauth2_checker do
        plug #{inspect(__MODULE__)}, clients: [Client, ...]
      end

      # for normal
      scope "/:app" do
        pipe_through :oauth2_checker
        get "/path", YourController, :your_action
      end

      # for work
      scope "/:app/:agent" do
        pipe_through :oauth2_checker
        get "/path", YourController, :your_action
      end
      ```
    """

    import Plug.Conn
    require Logger
    alias WeChat.{Utils, WebPage, Work, Plug.Helper}

    @typedoc "授权回调处理函数"
    @type oauth2_callback_fun ::
            (:normal | :work, Plug.Conn.t(), WebPage.code(), WeChat.client(), Work.Agent.t() ->
               Plug.Conn.t())
    @typedoc "获取授权链接函数"
    @type authorize_url_fun ::
            (:normal | :work | :work_qr, Plug.Conn.t(), WeChat.client(), Work.Agent.t() ->
               authorize_url :: String.t())

    @doc false
    def init(opts) do
      opts = Map.new(opts)

      {app_ids, clients} =
        Map.get(opts, :clients)
        |> List.wrap()
        |> case do
          [] -> raise "please set clients when using #{inspect(__MODULE__)}"
          list -> list
        end
        |> Enum.map_reduce(%{}, &transfer_client/2)

      oauth2_callback_fun =
        with {:ok, fun} <- Map.fetch(opts, :oauth2_callback_fun),
             true <- is_function(fun, 5) do
          fun
        else
          :error ->
            &oauth2_callback/5

          false ->
            raise ArgumentError,
                  "the :oauth2_callback_fun must arg 5 function when using #{inspect(__MODULE__)}"
        end

      authorize_url_fun =
        with {:ok, fun} <- Map.fetch(opts, :authorize_url_fun),
             true <- is_function(fun, 4) do
          fun
        else
          :error ->
            &authorize_url_by_server_role/4

          false ->
            raise ArgumentError,
                  "the :event_parser must arg 4 function when using #{inspect(__MODULE__)}"
        end

      %{
        app_ids: app_ids,
        clients: clients,
        oauth2_callback_fun: oauth2_callback_fun,
        authorize_url_fun: authorize_url_fun
      }
    end

    defp transfer_client(client, acc) when is_atom(client),
      do: transfer_client({client, :all}, acc)

    defp transfer_client({client, :all}, acc) do
      agents = Enum.map(client.agents, & &1.id)
      transfer_client({client, agents}, acc)
    end

    defp transfer_client({client, agents}, acc) do
      appid = client.appid()

      value =
        if match?(:work, client.app_type()) do
          agent_flag_list = transfer_agents(client, agents)
          {client, agent_flag_list}
        else
          client
        end

      acc = Enum.into([{appid, value}, {client.code_name(), value}], acc)
      {appid, acc}
    end

    defp transfer_agents(client, agents) when is_list(agents) do
      Enum.reduce(client.agents(), %{}, fn agent, acc ->
        agent_id = agent.id
        name = agent.name

        if agent_id in agents or name in agents do
          Enum.uniq([agent_id, name, to_string(agent_id), to_string(name)]) ++ acc
        else
          acc
        end
      end)
    end

    defp transfer_agents(client, agents) do
      raise ArgumentError,
            "error agents: #{inspect(agents)} for client: #{inspect(client)} when using #{inspect(__MODULE__)}"
    end

    @doc false
    # process flow:
    # 1. check session
    # 2. check code
    # 3. redirect to authorize_url
    def call(conn, options) do
      conn = fetch_session(conn)

      with appid when appid != nil <- get_session(conn, "appid"),
           true <- appid in options.app_ids do
        case Map.get(options.clients, appid) do
          {_client, agent_flag_list} ->
            with agent_id when agent_id != nil <- get_session(conn, "agent_id"),
                 true <- agent_id in agent_flag_list do
              conn
            end

          _client ->
            conn
        end
      else
        _ ->
          case conn.query_params do
            %{"code" => code} -> check_code(conn, code, options)
            _ -> redirect2auth(conn, options)
          end
      end
    end

    def check_code(conn, code, %{clients: clients, oauth2_callback_fun: oauth2_callback_fun}) do
      case conn.path_params do
        %{"app" => app} -> Map.get(clients, app)
        _ -> nil
      end
      |> case do
        nil ->
          Helper.not_found(conn)

        client when is_atom(client) ->
          oauth2_callback_fun.(:normal, conn, code, client, nil)

        # for work
        {client, agent_flag_list} ->
          with agent_flag when agent_flag != nil <- Map.get(conn.path_params, "agent"),
               true <- agent_flag in agent_flag_list,
               {_, agent} <- WeChat.get_client_agent(client.appid(), agent_flag) do
            oauth2_callback_fun.(:work, conn, code, client, agent)
          else
            _ -> Helper.not_found(conn)
          end
      end
    end

    defp oauth2_callback(:normal, conn, code, client, _) do
      with {:ok, %{status: 200, body: info}} <- WebPage.code2access_token(client, code),
           access_token when access_token != nil <- info["access_token"] do
        auth_success(conn, client, info)
      else
        error ->
          Logger.info("oauth2_callback failed, #{inspect(error)}")
          auth_fail(conn)
      end
    end

    defp oauth2_callback(:work, conn, code, client, agent) do
      with {:ok, %{status: 200, body: info}} <- Work.App.sso_user_info(client, agent.id, code),
           0 <- info["errcode"] do
        auth_success(conn, client, info)
      else
        error ->
          Logger.info("oauth2_callback failed, #{inspect(error)}")
          auth_fail(conn)
      end
    end

    def auth_success(conn, client, info) do
      timestamp = Utils.now_unix()
      info = Map.put(info, "timestamp", timestamp)

      conn
      |> fetch_session()
      |> put_session(:appid, client.appid())
      |> put_session(:access_info, info)
    end

    def auth_fail(conn) do
      Helper.html(
        conn,
        ~s(<div style="margin-top: 50%;font-size: 60px; text-align: center;">抱歉，授权失败！</div>)
      )
    end

    defp redirect2auth(conn, %{clients: clients, authorize_url_fun: authorize_url_fun}) do
      case conn.path_params do
        %{"app" => app} -> Map.get(clients, app)
        _ -> nil
      end
      |> case do
        nil ->
          Helper.not_found(conn)

        client when is_atom(client) ->
          url = authorize_url_fun.(:normal, conn, client, nil)
          Helper.redirect(conn, url)

        # for work
        {client, agent_flag_list} ->
          with agent_flag when agent_flag != nil <- Map.get(conn.path_params, "agent"),
               true <- agent_flag in agent_flag_list,
               {_client, agent} <- WeChat.get_client_agent(client.appid(), agent_flag) do
            url =
              case Map.get(conn.path_params, "qr") do
                nil -> :work
                _ -> :work_qr
              end
              |> authorize_url_fun.(conn, client, agent)

            Helper.redirect(conn, url)
          else
            _ -> Helper.not_found(conn)
          end
      end
    end

    defp authorize_url_by_server_role(type, conn, client, agent) do
      if match?(:hub_client, client.server_role) do
        hub_springboard_authorize_url(type, conn, client, agent)
      else
        authorize_url(type, conn, client, agent)
      end
    end

    defp authorize_url(:normal, conn = %{query_params: query_params}, client, _) do
      scope = Map.get(query_params, "scope", "snsapi_base")
      state = Map.get(query_params, "state", "")
      WebPage.oauth2_authorize_url(client, callback_uri(conn), scope, state)
    end

    defp authorize_url(:work, conn, client, _agent) do
      state = Map.get(conn.query_params, "state", "")
      WebPage.oauth2_authorize_url(client, callback_uri(conn), "snsapi_base", state)
    end

    defp authorize_url(:work_qr, conn, client, agent) do
      state = Map.get(conn.query_params, "state", "")
      Work.App.qr_connect_url(client, agent.id, callback_uri(conn), state)
    end

    def callback_uri(conn) do
      query_string =
        conn.query_params
        |> Map.drop(["scope", "code", "state"])
        |> URI.encode_query()

      request_url(%{conn | query_string: query_string})
    end

    defp hub_springboard_authorize_url(:normal, conn = %{query_params: query_params}, client, _) do
      if hub_springboard_url = WeChat.get_hub_springboard_url(client) do
        scope = Map.get(query_params, "scope", "snsapi_base")
        state = Map.get(query_params, "state", "")
        callback_uri = hub_springboard_callback_uri(conn, hub_springboard_url)
        WebPage.oauth2_authorize_url(client, callback_uri, scope, state)
      else
        Helper.not_found(conn)
      end
    end

    defp hub_springboard_authorize_url(:work, conn, client, agent) do
      if hub_springboard_url = WeChat.get_hub_springboard_url(client, agent.id) do
        state = Map.get(conn.query_params, "state", "")
        callback_uri = hub_springboard_callback_uri(conn, hub_springboard_url)
        WebPage.oauth2_authorize_url(client, callback_uri, "snsapi_base", state)
      else
        Helper.not_found(conn)
      end
    end

    defp hub_springboard_authorize_url(:work_qr, conn, client, agent) do
      if hub_springboard_url = WeChat.get_hub_springboard_url(client, agent.id) do
        state = Map.get(conn.query_params, "state", "")
        callback_uri = hub_springboard_callback_uri(conn, hub_springboard_url)
        Work.App.qr_connect_url(client, agent, callback_uri, state)
      else
        Helper.not_found(conn)
      end
    end

    # hub_springboard_url <> "/" <> conn.request_path <> "?" <> query_string
    def hub_springboard_callback_uri(conn, hub_springboard_url) do
      query_string =
        conn.query_params
        |> Map.drop(["scope", "code", "state"])
        |> URI.encode_query()

      url = Path.join([hub_springboard_url, conn.request_path])

      if match?("", query_string) do
        url
      else
        url <> "?" <> query_string
      end
    end
  end
end
