if Code.ensure_loaded?(Plug) do
  defmodule WeChat.Plug.HubExposer do
    @moduledoc """
    用于 Hub 暴露 token 等

    使用 Phoenix 时，将下面的代码加到 `router` 里面：

        get "/hub/expose/:store_id/:store_key", #{inspect(__MODULE__)}, clients: [ClientsA, ...]

    使用 PlugCowboy 时，将下面的代码加到 `router` 里面：

        get "/hub/expose/:store_id/:store_key",
          to: #{inspect(__MODULE__)},
          init_opts: [clients: [ClientsA, ...]]

    在暴露接口的同时，请注意安全合规使用，建议在使用前增加安全防护，例如：

        import Plug.BasicAuth
        plug :basic_auth, username: "hello", password: "secret"

        get "/hub/expose/:store_id/:store_key", #{inspect(__MODULE__)}, clients: [ClientsA, ...]
    """
    import WeChat.Plug.Helper

    @valid_keys [
      "access_token",
      "js_api_ticket",
      "agent_js_api_ticket",
      "wx_card_ticket",
      "component_access_token"
    ]

    @doc false
    def init(opts) do
      Map.new(opts)
      |> Map.get(:clients)
      |> List.wrap()
      |> case do
        [] -> raise ArgumentError, "please set clients when using #{inspect(__MODULE__)}"
        list -> list
      end
      |> Enum.reduce(%{}, &transfer_client/2)
    end

    defp transfer_client(client, acc) when is_atom(client) do
      transfer_client({client, :all}, acc)
    end

    defp transfer_client({client, :all}, acc) do
      if match?(:work, client.app_type()) do
        Enum.into(client.agents(), acc, fn agent ->
          {client.agent2cache_id(agent.id), :all}
        end)
      else
        Map.put(acc, client.appid(), :all)
      end
    end

    defp transfer_client({client, scope_list}, acc) when is_list(scope_list) do
      if match?(:work, client.app_type()) do
        Enum.into(scope_list, acc, fn
          {agent, :all} ->
            {client.agent2cache_id(agent), :all}

          {agent, scope_list} when is_list(scope_list) ->
            {client.agent2cache_id(agent), scope_list}
        end)
      else
        Map.put(acc, client.appid(), scope_list)
      end
    end

    @doc false
    def call(%{path_params: %{"store_id" => store_id, "store_key" => store_key}} = conn, opts) do
      in_scope? =
        case Map.fetch(opts, store_id) do
          {:ok, :all} -> true
          {:ok, scope_list} when is_list(scope_list) -> store_key in scope_list
          _ -> false
        end

      json =
        with true <- in_scope?,
             true <- store_key in @valid_keys,
             store_key <- String.to_existing_atom(store_key),
             store_map when store_map != nil <-
               WeChat.Storage.Cache.get_cache({:store_map, store_id}, store_key) do
          %{error: 0, msg: "success", store_map: store_map}
        else
          _ -> %{error: 404, msg: "not found"}
        end

      json(conn, json)
    rescue
      ArgumentError -> json(conn, %{error: 404, msg: "not found"})
    end

    def call(conn, _), do: not_found(conn)
  end
end
