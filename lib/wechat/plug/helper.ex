if Code.ensure_loaded?(Plug) do
  defmodule WeChat.Plug.Helper do
    @moduledoc false
    import Plug.Conn
    alias WeChat.{Work, Utils}

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

    def get_client_agent_by_path(%{path_params: %{"app" => app}} = conn, options) do
      case Map.get(options.clients, app) do
        nil ->
          not_found(conn)

        client when is_atom(client) ->
          {:normal, client, nil}

        # for work
        {client, agent_flag_list} ->
          get_agent_by_path(conn, client, agent_flag_list)
      end
    end

    def get_client_agent_by_path(conn, _options), do: not_found(conn)

    def get_agent_by_path(conn, client, agent_flag_list) do
      with agent_flag when agent_flag != nil <- Map.get(conn.path_params, "agent"),
           true <- agent_flag in agent_flag_list,
           {_, agent} <- WeChat.get_client_agent(client.appid(), agent_flag) do
        {:work, client, agent}
      else
        _ -> not_found(conn)
      end
    end

    def init_plug_clients(opts = %{client: client, agent: agent}, _plug)
        when is_atom(client) and is_atom(agent) do
      opts
    end

    def init_plug_clients(opts = %{client: client, agents: :runtime}, plug)
        when is_atom(client) do
      persistent_id = Map.get(opts, :persistent_id)

      unless persistent_id do
        raise ArgumentError,
              "please set persistent_id when agents: :runtime for using #{inspect(plug)}"
      end

      opts
    end

    def init_plug_clients(opts = %{client: client, agents: agents}, _plug)
        when is_atom(client) and (is_list(agents) or agents == :all) do
      [{_client_flag, {_client, agent_flag_list}} | _] = Utils.transform_client({client, agents})
      %{opts | agents: agent_flag_list}
    end

    def init_plug_clients(opts = %{client: client}, _plug) when is_atom(client) do
      if match?(:work, client.app_type()) do
        [{_client_flag, {_client, agent_flag_list}} | _] = Utils.transform_client({client, :all})
        Map.put(opts, :agents, agent_flag_list)
      else
        opts
      end
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
          {nil, Utils.transform_clients(clients)}
        end

      %{runtime: runtime, persistent_id: persistent_id, clients: clients}
    end

    def setup_plug(conn, %{client: client, agent: agent_or_id} = _options) do
      if agent = Work.Agent.find_agent(client, agent_or_id) do
        {:work, client, agent}
      else
        not_found(conn)
      end
    end

    def setup_plug(
          conn,
          %{client: client, agents: :runtime, persistent_id: persistent_id} = options
        ) do
      agents =
        with nil <- :persistent_term.get(persistent_id, nil) do
          [{_client_flag, {_client, agent_flag_list}} | _] =
            Utils.transform_client({client, :all})

          :persistent_term.put(persistent_id, agent_flag_list)
          agent_flag_list
        end

      setup_plug(conn, %{options | agents: agents})
    end

    def setup_plug(conn, %{client: client, agents: agents} = _options) do
      get_agent_by_path(conn, client, agents)
    end

    def setup_plug(_conn, %{client: client} = _options) do
      {:normal, client, nil}
    end

    def setup_plug(conn, %{runtime: true, persistent_id: persistent_id} = options) do
      clients =
        with nil <- :persistent_term.get(persistent_id, nil) do
          Utils.transform_clients(options.clients)
          |> tap(&:persistent_term.put(persistent_id, &1))
        end

      get_client_agent_by_path(conn, %{options | clients: clients})
    end

    def setup_plug(conn, options) do
      get_client_agent_by_path(conn, options)
    end
  end
end
