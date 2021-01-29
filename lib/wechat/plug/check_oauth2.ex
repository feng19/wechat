if Code.ensure_loaded?(Plug) do
  defmodule WeChat.Plug.CheckOauth2 do
    @moduledoc """
    检查是否有网页授权

    ## Usage

    ### 服务器角色为 `client`：

        plug WeChat.Plug.CheckOauth2, client: Client, path_prefix: "/wx/oauth2", scope: "snsapi_base", state: ""

    可选参数：

    - `:path_prefix`: 默认值为 `"/wx/oauth2"`
    - `:scope`: `"snsapi_base"` | `"snsapi_userinfo"`， 默认值为 `"snsapi_base"`
    - `:state`: 默认值为 `""`

    检测到未授权将会跳转到下面这个链接：

        /wx/oauth2/:code_name/callback/*path?xx=xx

    ### 服务器角色为 `hub_client`：

        plug WeChat.Plug.CheckOauth2, client: Client

    检测到未授权将会跳转到下面这个链接：

        HubOauth2Url <> "*path?xx=xx"

    """
    import Plug.Conn
    alias WeChat.Plug.WebPageOAuth2

    def init(options) do
      options =
        case options do
          client when is_atom(client) ->
            %{client: client}

          options when is_list(options) ->
            Map.new(options)
        end

      client = options.client

      case client.server_role() do
        :hub_client ->
          [
            appid: client.appid(),
            redirect_fun: &WebPageOAuth2.hub_client_oauth2(&1, &1.query_params, client)
          ]

        :client ->
          path_prefix = Map.get(options, :path_prefix, "/wx/oauth2")
          path_prefix = Path.join([path_prefix, client.code_name(), "callback"])
          scope = Map.get(options, :scope, "snsapi_base")
          state = Map.get(options, :state, "")

          redirect_fun = fn conn ->
            [pre, tail] =
              request_url(conn)
              |> String.split(conn.request_path)

            callback_url = pre <> path_prefix <> conn.request_path <> tail

            redirect_to_url =
              WeChat.WebPage.oauth2_authorize_url(client, callback_url, scope, state)

            WebPageOAuth2.redirect(conn, redirect_to_url)
          end

          [appid: client.appid(), redirect_fun: redirect_fun]
      end
    end

    def call(conn, appid: appid, redirect_fun: redirect_fun) do
      with openid when openid != nil <- get_session(conn, "openid"),
           ^appid <- get_session(conn, "appid") do
        conn
      else
        _ ->
          conn
          |> redirect_fun.()
          |> halt()
      end
    end
  end
end
