if Code.ensure_loaded?(Plug) do
  defmodule WeChat.Plug.Helper do
    @moduledoc false
    import Plug.Conn
    alias WeChat.Utils

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

    def init_plug_clients(opts, plug) when is_map(opts) do
      runtime = Map.get(opts, :runtime, false)

      clients =
        Map.get(opts, :clients)
        |> List.wrap()
        |> case do
          [] -> raise ArgumentError, "please set clients when using #{inspect(plug)}"
          list -> list
        end

      {persistent_id, clients} =
        if runtime do
          persistent_id = Map.get(opts, :persistent_id)

          unless persistent_id do
            raise ArgumentError,
                  "please set persistent_id when runtime: true for using #{inspect(plug)}"
          end

          {persistent_id, clients}
        else
          {nil, Utils.transfer_clients(clients)}
        end

      %{runtime: runtime, persistent_id: persistent_id, clients: clients}
    end

    def setup_clients_for_plug(options) do
      if options.runtime do
        persistent_id = options.persistent_id

        clients =
          with nil <- :persistent_term.get(persistent_id, nil) do
            Utils.transfer_clients(options.clients)
            |> tap(&:persistent_term.put(persistent_id, &1))
          end

        %{options | clients: clients}
      else
        options
      end
    end
  end
end
