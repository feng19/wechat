if Code.ensure_loaded?(Plug) do
  defmodule WeChat.Plug.WebPageOAuth2 do
    @moduledoc """
    网页授权

    [官方文档](https://developers.weixin.qq.com/doc/offiaccount/OA_Web_Apps/Wechat_webpage_authorization.html){:target="_blank"}

    ## Usage

    将下面的代码加到 `router` 里面：

    - 单一应用的情况：

      ```elixir
      scope "/wx/oauth2", WeChat.Plug do
        get "/callback/*path", WebPageOAuth2, client: Client, action: :oauth2_callback
        get "/*path", WebPageOAuth2, client: Client, action: :oauth2
      end
      ```

    - 多个应用的情况：

      ```elixir
      scope "/wx/oauth2/:code_name", WeChat.Plug do
        get "/callback/*path", WebPageOAuth2, :oauth2_callback
        get "/*path", WebPageOAuth2, :oauth2
      end
      ```

    - 服务器角色为 `hub`：

      ```elixir
      get "/wx/oauth2/:env/callback/*path", WeChat.Plug.WebPageOAuth2, client: Client, action: :hub_oauth2_callback
      # or
      get "/wx/oauth2/:code_name/:env/callback/*path", WeChat.Plug.WebPageOAuth2, :hub_oauth2_callback
      ```

    - 服务器角色为 `hub_client`：

      ```elixir
      scope "/wx/oauth2", WeChat.Plug do
        get "/callback/*path", WebPageOAuth2, client: Client, action: :oauth2_callback
        get "/*path", WebPageOAuth2, client: Client, action: :hub_client_oauth2
      end
      # or
      scope "/wx/oauth2/:code_name", WeChat.Plug do
        get "/callback/*path", WebPageOAuth2, :oauth2_callback
        get "/*path", WebPageOAuth2, :hub_client_oauth2
      end
      ```

    用户在微信进入下面这个链接：

        "/wx/oauth2/*path?xx=xx"
        # or
        "/wx/oauth2/:code_name/*path?xx=xx"

    经过 `plug` 之后，会跳转到微信的网页授权：

        "https://open.weixin.qq.com/connect/oauth2/authorize?appid=APPID&redirect_uri=REDIRECT_URI&response_type=code&scope=snsapi_userinfo&state=STATE#wechat_redirect"

    用户完成授权之后，微信会跳转回 `REDIRECT_URI/?code=CODE&state=STATE`，即：

        "/wx/oauth2/callback/*path?xx=xx"
        # or
        "/wx/oauth2/:code_name/callback/*path?xx=xx"

    默认的 `oauth2_callback` 函数拿到 `query` 里面的 `code` 换取 `access_token`，
    成功之后将 `openid` 和 `appid` 写入到 `session`，之后跳转到路径：

        "/*path?xx=xx"
    """
    import Plug.Conn
    require Logger
    alias WeChat.{WebPage, Storage.Cache}

    @doc false
    def init(action) when is_atom(action), do: action

    def init(options) do
      options = Map.new(options)

      unless Map.has_key?(options, :action) and is_atom(options.action) do
        raise ArgumentError,
              "please set a available for :action when using #{inspect(__MODULE__)}"
      end

      if Map.has_key?(options, :client) do
        options
      else
        options.action
      end
    end

    @doc false
    def call(%{path_params: %{"code_name" => code_name}} = conn, action) when is_atom(action) do
      if client = Cache.search_client_by_name(code_name) do
        apply(__MODULE__, action, [conn, conn.query_params, client])
      else
        not_found(conn)
      end
    end

    def call(conn, %{action: action, client: client}) do
      apply(__MODULE__, action, [conn, conn.query_params, client])
    end

    @doc doc_group: :action
    def oauth2(conn, query_params, client) do
      {scope, query_params} = Map.pop(query_params, "scope", "snsapi_base")
      {state, query_params} = Map.pop(query_params, "state", "")
      redirect_uri = get_callback_url(%{conn | query_params: query_params})
      oauth2_authorize_url = WebPage.oauth2_authorize_url(client, redirect_uri, scope, state)
      redirect(conn, oauth2_authorize_url)
    end

    @doc doc_group: :action
    def oauth2_callback(conn, %{"code" => code} = query_params, client) do
      timestamp = WeChat.Utils.now_unix()

      with {:ok, %{status: 200, body: info}} <- WebPage.code2access_token(client, code),
           access_token when access_token != nil <- info["access_token"],
           openid when openid != nil <- info["openid"] do
        info = Map.put(info, "timestamp", timestamp)
        path = Path.join(["/" | conn.path_params["path"]])

        redirect_path =
          query_params
          |> Map.delete("code")
          |> URI.encode_query()
          |> case do
            "" -> path
            qs -> path <> "?" <> qs
          end

        conn
        |> fetch_session()
        |> put_session(:openid, openid)
        |> put_session(:appid, client.appid())
        |> put_session(:access_info, info)
        |> redirect(redirect_path)
      else
        error ->
          Logger.info("oauth2_callback failed, #{inspect(error)}")

          body =
            "<div style=\"margin-top: 50%;font-size: 60px; text-align: center;\">抱歉，授权失败！</div>"

          conn
          |> put_resp_content_type("text/html")
          |> send_resp(200, body)
      end
    end

    def oauth2_callback(conn, _, _options) do
      not_found(conn)
    end

    @doc doc_group: :action
    def hub_oauth2_callback(conn, %{"code" => _} = _query_params, client) do
      path_params = conn.path_params

      if client_oauth2_callback_url = WeChat.get_oauth2_env_url(client, path_params["env"]) do
        request_url = Path.join([client_oauth2_callback_url | path_params["path"]])

        redirect_uri =
          case conn.query_string do
            "" -> request_url
            qs -> request_url <> "?" <> qs
          end

        redirect(conn, redirect_uri)
      else
        not_found(conn)
      end
    end

    def hub_oauth2_callback(conn, _query_params, _client) do
      not_found(conn)
    end

    @doc false
    def not_found(conn) do
      conn
      |> put_resp_content_type("text/plain")
      |> send_resp(404, "not_found")
    end

    @doc false
    def redirect(conn, url) do
      html = Plug.HTML.html_escape(url)
      body = "<html><body>You are being <a href=\"#{html}\">redirected</a>.</body></html>"

      conn
      |> put_resp_header("location", url)
      |> put_resp_content_type("text/html")
      |> send_resp(302, body)
    end

    # callback_uri => "/wx/oauth2/callback/*path?xx=xx"
    # callback_uri => "/wx/oauth2/:code_name/callback/*path?xx=xx"
    defp get_callback_url(conn) do
      request_url = request_url(%{conn | query_string: ""})

      {prefix_path, path} =
        case conn.path_params["path"] do
          [] ->
            {String.trim_trailing(request_url, "/"), ""}

          path ->
            path = Enum.join(path, "/")
            tail_length = String.length(path)
            prefix_path = String.slice(request_url, 0..-(tail_length + 2))
            {prefix_path, path}
        end

      query_string =
        case URI.encode_query(conn.query_params) do
          "" -> ""
          qs -> "?" <> qs
        end

      IO.iodata_to_binary([prefix_path, "/callback/", path, query_string])
    end
  end
end
