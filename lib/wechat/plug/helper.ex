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
        {client, agent_string_list} ->
          get_agent_by_path(conn, client, agent_string_list)
      end
    end

    def get_client_agent_by_path(conn, _options), do: not_found(conn)

    def get_agent_by_path(conn, client, :all) do
      case Map.get(conn.path_params, "agent") do
        nil ->
          not_found(conn)

        "" ->
          not_found(conn)

        agent_str ->
          case WeChat.get_client_agent(client.appid(), agent_str) do
            {_, agent} -> {:work, client, agent}
            _ -> not_found(conn)
          end
      end
    end

    def get_agent_by_path(conn, client, agent_string_list) when is_list(agent_string_list) do
      with agent_str when agent_str != nil <- Map.get(conn.path_params, "agent"),
           true <- agent_str in agent_string_list,
           {_, agent} <- WeChat.get_client_agent(client.appid(), agent_str) do
        {:work, client, agent}
      else
        _ -> not_found(conn)
      end
    end

    # enable_for_all
    def init_plug_clients(%{enable_for_all: true}, _plug), do: %{enable_for_all: true}

    # special client & single agent
    def init_plug_clients(opts = %{client: client, agent: agent}, _plug)
        when is_atom(client) and is_atom(agent) do
      opts
    end

    # special client but runtime agents
    def init_plug_clients(opts = %{client: client, agents: :runtime}, plug)
        when is_atom(client) do
      if Map.get(opts, :persistent_id) do
        opts
      else
        raise ArgumentError,
              "please set persistent_id when agents: :runtime for using #{inspect(plug)}"
      end
    end

    # special client & agents
    def init_plug_clients(opts = %{client: client, agents: agents}, _plug)
        when is_atom(client) and is_list(agents) do
      agent_string_list = agent_string_list(client, agents)
      %{opts | agents: agent_string_list}
    end

    # special client & all agents
    def init_plug_clients(opts = %{client: client, agents: :all}, _plug) when is_atom(client) do
      opts
    end

    # special client
    def init_plug_clients(opts = %{client: client}, _plug) when is_atom(client) do
      if match?(:work, client.app_type()) do
        Map.put(opts, :agents, :all)
      else
        opts
      end
    end

    # special clients
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
          if persistent_id = Map.get(opts, :persistent_id) do
            {persistent_id, clients}
          else
            raise ArgumentError,
                  "please set persistent_id when runtime: true for using #{inspect(plug)}"
          end
        else
          {nil, transform_clients(clients)}
        end

      %{runtime: runtime, persistent_id: persistent_id, clients: clients}
    end

    def setup_plug(%{path_params: %{"app" => app}} = conn, %{enable_for_all: true}) do
      case WeChat.get_client(app) do
        nil ->
          not_found(conn)

        client ->
          if match?(:work, client.app_type()) do
            get_agent_by_path(conn, client, :all)
          else
            {:normal, client, nil}
          end
      end
    end

    def setup_plug(conn, %{client: client, agents: :all} = _options) do
      get_agent_by_path(conn, client, :all)
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
          agent_string_list = agent_string_list(client)
          :persistent_term.put(persistent_id, agent_string_list)
          agent_string_list
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
          transform_clients(options.clients)
          |> tap(&:persistent_term.put(persistent_id, &1))
        end

      get_client_agent_by_path(conn, %{options | clients: clients})
    end

    def setup_plug(conn, options) do
      get_client_agent_by_path(conn, options)
    end

    defp transform_clients(clients) do
      Enum.reduce(clients, %{}, &transform_client/2)
    end

    defp transform_client(client, acc) when is_atom(client) do
      if match?(:work, client.app_type()) do
        transform_client({client, :all}, acc)
      else
        Map.merge(acc, %{client.appid() => client, client.code_name() => client})
      end
    end

    defp transform_client({client, :all}, acc) do
      Map.merge(acc, %{
        client.appid() => {client, :all},
        client.code_name() => {client, :all}
      })
    end

    defp transform_client({client, agents}, acc) do
      value =
        if match?(:work, client.app_type()) do
          agents = agents |> List.wrap() |> Enum.uniq()
          agent_string_list = agent_string_list(client, agents)

          if Enum.empty?(agent_string_list) do
            raise ArgumentError, "please set agents for client: #{inspect(client)}"
          end

          {client, agent_string_list}
        else
          client
        end

      Map.merge(acc, %{client.appid() => value, client.code_name() => value})
    end

    defp agent_string_list(client) do
      Enum.flat_map(client.agents(), fn agent ->
        [to_string(agent.id), to_string(agent.name)]
      end)
      |> Utils.uniq_and_sort()
    end

    defp agent_string_list(client, agents) when is_list(agents) do
      Enum.reduce(client.agents(), [], fn agent, acc ->
        agent_id = agent.id
        name = agent.name

        if agent_id in agents or name in agents do
          [to_string(agent.id), to_string(agent.name) | acc]
        else
          acc
        end
      end)
      |> Utils.uniq_and_sort()
    end
  end
end
