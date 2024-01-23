if Code.ensure_loaded?(Plug) do
  defmodule WeChat.Plug.OAuth2Checker do
    @moduledoc """
    网页授权

    [官方文档](https://developers.weixin.qq.com/doc/offiaccount/OA_Web_Apps/Wechat_webpage_authorization.html){:target="_blank"}

    工作流程:

    1. 检查 `session`, 判断是否已经有授权，有则继续执行后续的 plug, 没有则跳到步骤 2;
    2. 检查 `query` 是否有 `code`, 有则执行 `oauth2_callback_fun` 函数, 没有则跳到步骤 3;
    3. 执行 `authorize_url_fun` 函数，跳转到 `authorize_url`.

    可选参数:

    - `:oauth2_callback_fun`:
      [定义](`t:oauth2_callback_fun/0`), 默认值: [&oauth2_callback/5](`oauth2_callback/5`)
    - `:authorize_url_fun`:
      [定义](`t:authorize_url_fun/0`), 默认值: [&authorize_url_by_server_role/4](`authorize_url_by_server_role/4`)

    ** 注意 **: 服务器角色为 `hub_client` 时，请确保已经配置 `hub_springboard_url`:

        WeChat.HubClient.set_hub_springboard_url(Client, "https://wx.example.com")

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
          # 在PC端授权访问网页
          get "/:qr/your_path", YourController, :your_action
          # 在企业微信内授权访问网页
          get "/your_path", YourController, :your_action
        end
    """

    import Plug.Conn
    import WeChat.Plug.Helper
    require Logger
    alias WeChat.{Utils, WebPage, Work, HubClient}
    @behaviour Plug

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
      opts
      |> Map.new()
      |> init_plug_clients(__MODULE__)
      |> init_common_funs()
    end

    defp init_common_funs(options) do
      oauth2_callback_fun =
        with {:ok, fun} <- Map.fetch(options, :oauth2_callback_fun),
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
        with {:ok, fun} <- Map.fetch(options, :authorize_url_fun),
             true <- is_function(fun, 4) do
          fun
        else
          :error ->
            &__MODULE__.authorize_url_by_server_role/4

          false ->
            raise ArgumentError,
                  "the :event_parser must arg 4 function when using #{inspect(__MODULE__)}"
        end

      Map.merge(options, %{
        oauth2_callback_fun: oauth2_callback_fun,
        authorize_url_fun: authorize_url_fun
      })
    end

    @doc false
    # process flow:
    # 1. check session
    # 2. check code
    # 3. redirect to authorize_url
    def call(conn, options) do
      case setup_plug(conn, options) do
        {:work, client, agent} -> call_work(conn, client, agent, options)
        {:normal, client, _agent} -> call_normal(conn, client, options)
        conn -> conn
      end
    end

    defp call_work(conn, client, agent, options) do
      conn = fetch_session(conn)

      with appid <- client.appid(),
           ^appid <- get_session(conn, "appid"),
           agent_id <- agent.id,
           ^agent_id <- get_session(conn, "agent_id") do
        conn
      else
        _ -> check_code(conn, options, :work, client, agent)
      end
    end

    defp call_normal(conn, client, options) do
      conn = fetch_session(conn)

      with appid <- client.appid(),
           ^appid <- get_session(conn, "appid") do
        conn
      else
        _ -> check_code(conn, options, :normal, client, nil)
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
        auth_success(conn, client, agent, info)
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

    def auth_success(conn, client, agent, info) do
      timestamp = Utils.now_unix()
      info = Map.put(info, "timestamp", timestamp)

      conn
      |> fetch_session()
      |> put_session(:appid, client.appid())
      |> put_session(:agent_id, agent.id)
      |> put_session(:access_info, info)
    end

    def auth_fail(conn) do
      html(
        conn,
        ~s(<div style="margin-top: 50%;font-size: 60px; text-align: center;">抱歉，授权失败！</div>)
      )
    end

    defp redirect2auth(conn, %{authorize_url_fun: authorize_url_fun}, :normal, client, agent) do
      url = authorize_url_fun.(:normal, conn, client, agent)
      redirect(conn, url)
    end

    defp redirect2auth(conn, %{authorize_url_fun: authorize_url_fun}, :work, client, agent) do
      case Map.get(conn.path_params, "qr") do
        nil -> :work
        _ -> :work_qr
      end
      |> authorize_url_fun.(conn, client, agent)
      |> case do
        :not_found -> not_found(conn)
        url -> redirect(conn, url)
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
      if hub_springboard_url = HubClient.get_hub_springboard_url(client) do
        scope = Map.get(query_params, "scope", "snsapi_base")
        state = Map.get(query_params, "state", "")
        callback_uri = hub_springboard_callback_uri(conn, hub_springboard_url)
        WebPage.oauth2_authorize_url(client, callback_uri, scope, state)
      else
        :not_found
      end
    end

    defp hub_springboard_authorize_url(:work, conn, client, _agent = %{id: agent_id}) do
      if hub_springboard_url = HubClient.get_hub_springboard_url(client, agent_id) do
        state = Map.get(conn.query_params, "state", "")
        callback_uri = hub_springboard_callback_uri(conn, hub_springboard_url)
        WebPage.oauth2_authorize_url(client, callback_uri, "snsapi_base", state)
      else
        :not_found
      end
    end

    defp hub_springboard_authorize_url(:work_qr, conn, client, _agent = %{id: agent_id}) do
      if hub_springboard_url = HubClient.get_hub_springboard_url(client, agent_id) do
        state = Map.get(conn.query_params, "state", "")
        callback_uri = hub_springboard_callback_uri(conn, hub_springboard_url)
        Work.App.qr_connect_url(client, agent_id, callback_uri, state)
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
  end
end
