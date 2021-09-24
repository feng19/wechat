if Code.ensure_loaded?(Plug) do
  defmodule WeChat.Plug.Helper do
    @moduledoc false
    import Plug.Conn

    @spec not_found(Plug.Conn.t()) :: Plug.Conn.t()
    def not_found(conn) do
      conn
      |> put_resp_content_type("text/plain")
      |> send_resp(404, "not_found")
      |> halt()
    end

    @spec redirect(Plug.Conn.t(), String.t()) :: Plug.Conn.t()
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

    @spec html(Plug.Conn.t(), iodata) :: Plug.Conn.t()
    def html(conn, body) do
      conn
      |> put_resp_content_type("text/html")
      |> send_resp(200, body)
      |> halt()
    end

    @spec json(Plug.Conn.t(), term) :: Plug.Conn.t()
    def json(conn, data) do
      conn
      |> put_resp_content_type("application/json")
      |> send_resp(conn.status || 200, Jason.encode_to_iodata!(data))
    end
  end
end
