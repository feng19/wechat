defmodule WeChat.Plug.CheckOauth2 do
  @moduledoc """
  检查是否有网页授权

  ## Usage

  - 服务器角色为 `client`：

    ```elixir
    plug WeChat.Plug.CheckOauth2, client: Client, path_prefix: "/wx/oauth2", scope: "snsapi_base", state: "xxx"
    ```

    可选参数：

    - scope: "snsapi_base" | "snsapi_userinfo"， 默认为 "snsapi_base"
    - state: 默认为 ""

    `/wx/oauth2/:code_name/callback/*path?xx=xx`

  - 服务器角色为 `hub_client`：

    ```elixir
    plug WeChat.Plug.CheckOauth2, client: Client
    ```

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
        unless Map.has_key?(options, :path_prefix) and is_binary(options.path_prefix) do
          raise ArgumentError,
                "please set a available value for the :path_prefix when using #{
                  inspect(__MODULE__)
                }"
        end

        scope = Map.get(options, :scope, "snsapi_base")
        state = Map.get(options, :state, "")

        path_prefix = Path.join([options.path_prefix, client.code_name(), "callback"])

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
