if Code.ensure_loaded?(Plug) do
  defmodule WeChat.Plug.OAuth2Checker do
    @moduledoc """
    网页授权

    [官方文档](https://developers.weixin.qq.com/doc/offiaccount/OA_Web_Apps/Wechat_webpage_authorization.html){:target="_blank"}

    工作流程

    1. 检查 `session`, 判断是否已经有授权，有则继续执行后续的 plug, 没有则跳到步骤 2;
    2. 检查 `query` 是否有 `code`, 有则执行 `oauth2_callback_fun` 函数, 没有则跳到步骤 3;
    3. 执行 `authorize_url_fun` 函数，跳转到 `authorize_url`.

    可选参数:

    - `:oauth2_callback_fun`: `t:#{inspect(__MODULE__)}.oauth2_callback_fun/0`, 默认: `#{inspect(__MODULE__)}.oauth2_callback/5`
    - `:authorize_url_fun`: `t:#{inspect(__MODULE__)}.authorize_url_fun/0`, 默认: `#{inspect(__MODULE__)}.authorize_url_by_server_role/4`

    ** 注意 **: 服务器角色为 `hub_client` 时，请确保已经配置 `hub_springboard_url`:

        WeChat.set_hub_springboard_url(Client, "https://wx.example.com")

    ## Usage

    将下面的代码加到 `router` 里面：

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

      clients =
        Map.get(opts, :clients)
        |> List.wrap()
        |> case do
          [] -> raise "please set clients when using #{inspect(__MODULE__)}"
          list -> list
        end
        |> Enum.reduce(%{}, &transfer_client/2)

      oauth2_callback_fun =
        with {:ok, fun} <- Map.fetch(opts, :oauth2_callback_fun),
             true <- is_function(fun, 5) do
          fun
        else
          :error ->
            &__MODULE__.oauth2_callback/5

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
            &__MODULE__.authorize_url_by_server_role/4

          false ->
            raise ArgumentError,
                  "the :event_parser must arg 4 function when using #{inspect(__MODULE__)}"
        end

      %{
        clients: clients,
        oauth2_callback_fun: oauth2_callback_fun,
        authorize_url_fun: authorize_url_fun
      }
    end

    defp transfer_client(client, acc) when is_atom(client) do
      if match?(:work, client.app_type()) do
        transfer_client({client, :all}, acc)
      else
        transfer_client({client, nil}, acc)
      end
    end

    defp transfer_client({client, :all}, acc) do
      agents = Enum.map(client.agents(), & &1.id)
      transfer_client({client, agents}, acc)
    end

    defp transfer_client({client, agents}, acc) do
      value =
        if match?(:work, client.app_type()) do
          agent_flag_list = transfer_agents(client, agents)
          {client, agent_flag_list}
        else
          client
        end

      Enum.into([{client.appid(), value}, {client.code_name(), value}], acc)
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
      case get_client_agent_by_path(conn, options) do
        {:work, client, agent} ->
          conn = fetch_session(conn)

          with appid <- client.appid(),
               ^appid <- get_session(conn, "appid"),
               agent_id <- agent.id,
               ^agent_id <- get_session(conn, "agent_id") do
            conn
          else
            _ -> check_code(conn, options, :work, client, agent)
          end

        {type, client, agent} ->
          conn = fetch_session(conn)

          with appid <- client.appid(),
               ^appid <- get_session(conn, "appid") do
            conn
          else
            _ -> check_code(conn, options, type, client, agent)
          end

        conn ->
          conn
      end
    end

    def check_code(
          %{query_params: %{"code" => code}} = conn,
          %{oauth2_callback_fun: oauth2_callback_fun},
          type,
          client,
          agent
        ) do
      oauth2_callback_fun.(type, conn, code, client, agent)
    end

    def check_code(conn, options, type, client, agent),
      do: redirect2auth(conn, options, type, client, agent)

    def oauth2_callback(:normal, conn, code, client, _) do
      with {:ok, %{status: 200, body: info}} <- WebPage.code2access_token(client, code),
           access_token when access_token != nil <- info["access_token"] do
        auth_success(conn, client, info)
      else
        error ->
          Logger.info("oauth2_callback failed, #{inspect(error)}")
          auth_fail(conn)
      end
    end

    def oauth2_callback(:work, conn, code, client, agent) do
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

    defp redirect2auth(conn, %{authorize_url_fun: authorize_url_fun}, :normal, client, agent) do
      url = authorize_url_fun.(:normal, conn, client, agent)
      Helper.redirect(conn, url)
    end

    defp redirect2auth(conn, %{authorize_url_fun: authorize_url_fun}, :work, client, agent) do
      case Map.get(conn.path_params, "qr") do
        nil -> :work
        _ -> :work_qr
      end
      |> authorize_url_fun.(conn, client, agent)
      |> case do
        :not_found -> Helper.not_found(conn)
        url -> Helper.redirect(conn, url)
      end
    end

    def authorize_url_by_server_role(type, conn, client, agent) do
      if match?(:hub_client, client.server_role()) do
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
        :not_found
      end
    end

    defp hub_springboard_authorize_url(:work, conn, client, agent) do
      if hub_springboard_url = WeChat.get_hub_springboard_url(client, agent.id) do
        state = Map.get(conn.query_params, "state", "")
        callback_uri = hub_springboard_callback_uri(conn, hub_springboard_url)
        WebPage.oauth2_authorize_url(client, callback_uri, "snsapi_base", state)
      else
        :not_found
      end
    end

    defp hub_springboard_authorize_url(:work_qr, conn, client, agent) do
      if hub_springboard_url = WeChat.get_hub_springboard_url(client, agent.id) do
        state = Map.get(conn.query_params, "state", "")
        callback_uri = hub_springboard_callback_uri(conn, hub_springboard_url)
        Work.App.qr_connect_url(client, agent, callback_uri, state)
      else
        :not_found
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

    def get_client_agent_by_path(%{path_params: %{"app" => app} = path_params} = conn, options) do
      case Map.get(options.clients, app) do
        nil ->
          Helper.not_found(conn)

        client when is_atom(client) ->
          {:normal, client, nil}

        # for work
        {client, agent_flag_list} ->
          with agent_flag when agent_flag != nil <- Map.get(path_params, "agent"),
               true <- agent_flag in agent_flag_list,
               {_, agent} <- WeChat.get_client_agent(client.appid(), agent_flag) do
            {:work, client, agent}
          else
            _ -> Helper.not_found(conn)
          end
      end
    end

    def get_client_agent_by_path(conn, _options), do: Helper.not_found(conn)
  end
end
