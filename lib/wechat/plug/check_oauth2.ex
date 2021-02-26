if Code.ensure_loaded?(Plug) do
  defmodule WeChat.Plug.CheckOauth2 do
    @moduledoc """
    检查是否有网页授权

    ## Usage

        plug WeChat.Plug.CheckOauth2, client: Client

    可选参数:

    - `:oauth2_callback_path`: 默认值为 `"/wx/oauth2/callback"`
    - `:need_code_name`: 默认值为 `false`, `oauth2_callback_path` 是多个应用的话，请设置为 `true`,
    如上面的配置 `:oauth2_callback_path` 已经包含 `code_name`, `:need_code_name` 请不要设置为 `true`
    - `:env`: `Client` 的 `server_role=hub_client` 时，可以配置此 `env`
    - `:scope`: `"snsapi_base"` | `"snsapi_userinfo"`， 默认值为 `"snsapi_base"`
    - `:state`: 默认值为 `""`

    ** 注意 **: 服务器角色为 `hub_client` 时，请确保已经配置 `hub_url`:

        WeChat.set_hub_url(Client, "https://wx.example.com")

    检测到未授权将会跳转到下面这个链接:

        "/wx/oauth2/callback/*path?xx=xx"
        # or
        "/wx/oauth2/:code_name/callback/*path?xx=xx"
        # or
        HubUrl <> "/wx/oauth2/:code_name/:env/callback/*path?xx=xx"
    """
    import Plug.Conn
    alias WeChat.Plug.WebPageOAuth2

    @doc false
    def init(options) do
      options =
        case options do
          client when is_atom(client) ->
            %{client: client}

          options when is_list(options) ->
            Map.new(options)
        end

      client = options.client
      server_role = client.server_role()

      oauth2_callback_path =
        if Map.get(options, :need_code_name, false) do
          options
          |> Map.get(:oauth2_callback_path, "/wx/oauth2/callback")
          |> String.trim_trailing("/callback")
          |> Path.join("/" <> client.code_name() <> "/callback")
        else
          Map.get(options, :oauth2_callback_path, "/wx/oauth2/callback")
        end

      oauth2_callback_path =
        if server_role == :hub_client do
          case Map.get(options, :env) do
            nil ->
              oauth2_callback_path

            env when is_binary(env) or is_atom(env) ->
              oauth2_callback_path
              |> String.trim_trailing("/callback")
              |> Path.join("/" <> to_string(env) <> "/callback")
          end
        else
          oauth2_callback_path
        end

      scope = Map.get(options, :scope, "snsapi_base")
      state = Map.get(options, :state, "")

      redirect_fun =
        case server_role do
          :hub_client -> &__MODULE__.hub_client_oauth2/5
          # [:client, :hub]
          _ -> &__MODULE__.client_oauth2/5
        end

      %{
        appid: client.appid(),
        client: client,
        oauth2_callback_path: oauth2_callback_path,
        scope: scope,
        state: state,
        redirect_fun: redirect_fun
      }
    end

    @doc false
    def call(conn, %{appid: appid} = options) do
      with openid when openid != nil <- get_session(conn, "openid"),
           ^appid <- get_session(conn, "appid") do
        conn
      else
        _ ->
          redirect_fun = options.redirect_fun

          conn
          |> redirect_fun.(
            options.client,
            options.oauth2_callback_path,
            options.scope,
            options.state
          )
          |> halt()
      end
    end

    def client_oauth2(conn, client, oauth2_callback_path, scope, state) do
      host = request_url(%{conn | query_string: "", request_path: ""})

      Path.join([host, oauth2_callback_path, conn.request_path])
      |> oauth2_authorize_url(conn, client, scope, state)
    end

    def hub_client_oauth2(conn, client, oauth2_callback_path, scope, state) do
      if hub_url = WeChat.get_hub_url(client) do
        Path.join([hub_url, oauth2_callback_path, conn.request_path])
        |> oauth2_authorize_url(conn, client, scope, state)
      else
        WebPageOAuth2.not_found(conn)
      end
    end

    defp oauth2_authorize_url(callback_url_prefix, conn, client, scope, state) do
      {scope, query_params} = Map.pop(conn.query_params, "scope", scope)
      {state, query_params} = Map.pop(query_params, "state", state)

      callback_url =
        case URI.encode_query(query_params) do
          "" -> callback_url_prefix
          qs -> callback_url_prefix <> "?" <> qs
        end

      oauth2_authorize_url =
        WeChat.WebPage.oauth2_authorize_url(client, callback_url, scope, state)

      WebPageOAuth2.redirect(conn, oauth2_authorize_url)
    end
  end
end
