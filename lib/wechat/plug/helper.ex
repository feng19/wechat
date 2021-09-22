defmodule WeChat.Plug.Helper do
  @moduledoc false
  import Plug.Conn

  def not_found(conn) do
    conn
    |> put_resp_content_type("text/plain")
    |> send_resp(404, "not_found")
    |> halt()
  end

  def redirect(conn, url) do
    html = Plug.HTML.html_escape(url)

    conn
    |> put_resp_header("location", url)
    |> put_resp_content_type("text/html")
    |> send_resp(
      302,
      "<html><body>You are being <a href=\"#{html}\">redirected</a>.</body></html>"
    )
    |> halt()
  end

  def html(conn, body) do
    conn
    |> put_resp_content_type("text/html")
    |> send_resp(200, body)
    |> halt()
  end
end
