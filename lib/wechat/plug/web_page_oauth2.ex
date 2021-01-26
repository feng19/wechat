defmodule WeChat.Plug.WebPageOAuth2 do
  @moduledoc """
  网页授权

  [API Docs Link](https://developers.weixin.qq.com/doc/offiaccount/OA_Web_Apps/Wechat_webpage_authorization.html){:target="_blank"}

  ## Usage

  将下面的一句代码加到 `router` 里面：

  ```elixir
  forward "/wx/oauth2", WeChat.Plug.WebPageOAuth2, path_prefix: "/wx/oauth2"
  ```

  用户在微信进入下面这个链接：

      /wx/oauth2/:code_name/*path?xx=xx

  经过 `plug` 之后，会跳转到微信的网页授权：

      https://open.weixin.qq.com/connect/oauth2/authorize?appid=APPID&redirect_uri=REDIRECT_URI&response_type=code&scope=snsapi_userinfo&state=STATE#wechat_redirect

  用户完成授权之后，微信会跳转回 `REDIRECT_URI/?code=CODE&state=STATE`，即：

      /wx/oauth2/:code_name/callback/*path?xx=xx

  默认的 `oauth2_callback` 函数拿到 `query` 里面的 `code` 换取 `access_token`，
  成功之后将 `openid` 和 `appid` 写入到 `session`，之后跳转到路径：

      /*path?xx=xx

  """
  use Plug.Router
  alias WeChat.{WebPage, Storage.Cache}
  require Logger

  plug :match
  plug :dispatch

  def init(options) do
    options = Map.new(options)

    unless Map.has_key?(options, :path_prefix) do
      raise ArgumentError, "must have :path_prefix setting for using #{inspect(__MODULE__)}"
    end

    path_prefix = "/" <> String.trim(options.path_prefix, "/") <> "/"

    Map.merge(
      %{oauth2_callback: &__MODULE__.oauth2_callback/2},
      %{options | path_prefix: path_prefix}
    )
  end

  get "/:code_name/callback/*path" do
    oauth2_callback = opts.oauth2_callback
    oauth2_callback.(conn, opts)
  end

  get "/:code_name/*path" do
    oauth2(conn, opts)
  end

  match _ do
    not_found(conn)
  end

  def oauth2(
        %{path_params: %{"code_name" => code_name, "path" => path}, query_params: query_params} =
          conn,
        options
      ) do
    if client = Cache.search_client_by_name(code_name) do
      {scope, query_params} = Map.pop(query_params, "scope", "snsapi_base")
      {state, query_params} = Map.pop(query_params, "state", "")
      query_string = URI.encode_query(query_params)
      # callback_uri => "/wx/oauth2/AppCodeName/callback/*path?xx=xx"
      callback_uri =
        IO.iodata_to_binary([
          to_string(conn.scheme),
          "://",
          conn.host,
          request_url_port(conn.scheme, conn.port),
          options.path_prefix,
          code_name,
          "/callback/",
          Enum.join(path, "/"),
          request_url_qs(query_string)
        ])

      oauth2_authorize_url = WebPage.oauth2_authorize_url(client, callback_uri, scope, state)
      redirect(conn, oauth2_authorize_url)
    else
      not_found(conn)
    end
  end

  # oauth2 callback
  def oauth2_callback(
        %{
          query_params: %{"code" => code} = query_params,
          path_params: %{"code_name" => code_name, "path" => path}
        } = conn,
        _options
      ) do
    with client when client != nil <- Cache.search_client_by_name(code_name),
         {:ok, %{status: 200, body: info}} <- WebPage.code2access_token(client, code),
         access_token when access_token != nil <- info["access_token"],
         openid when openid != nil <- info["openid"] do
      query_string = query_params |> Map.delete("code") |> URI.encode_query()
      path = IO.iodata_to_binary(["/", Enum.join(path, "/"), request_url_qs(query_string)])

      conn
      |> fetch_session()
      |> put_session(:openid, openid)
      |> put_session(:appid, client.appid())
      |> redirect(path)
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

  def oauth2_callback(conn, _options) do
    not_found(conn)
  end

  defp not_found(conn) do
    conn
    |> put_resp_content_type("text/plain")
    |> send_resp(404, "not_found")
  end

  defp redirect(conn, url) do
    html = Plug.HTML.html_escape(url)
    body = "<html><body>You are being <a href=\"#{html}\">redirected</a>.</body></html>"

    conn
    |> put_resp_header("location", url)
    |> put_resp_content_type("text/html")
    |> send_resp(302, body)
  end

  defp request_url_port(:http, 80), do: ""
  defp request_url_port(:https, 443), do: ""
  defp request_url_port(_, port), do: [?:, Integer.to_string(port)]

  defp request_url_qs(""), do: ""
  defp request_url_qs(qs), do: [??, qs]
end
