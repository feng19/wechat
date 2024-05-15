if Code.ensure_loaded?(Plug) do
  defmodule WeChat.Plug.HubExposer do
    @moduledoc """
    用于 `Hub`(中控服务器) 提供查询 `AccessToken` 的 `HTTP` 接口

    `Hub Client` 会定期从 `Hub`(中控服务器) 的接口中获取 `AccessToken`

    使用 `Phoenix` 时，将下面的代码加到 `router` 里面：

        get "/hub/expose/:store_id/:store_key", #{inspect(__MODULE__)}, clients: [ClientsA, ...]

    使用 `PlugCowboy` 时，将下面的代码加到 `router` 里面：

        get "/hub/expose/:store_id/:store_key",
          to: #{inspect(__MODULE__)},
          init_opts: [clients: [ClientsA, ...]]

    ** 注意 **, 在暴露接口的同时，请注意安全合规使用，建议在使用前增加安全防护，例如：

        import Plug.BasicAuth
        plug :basic_auth, username: "hello", password: "secret"

        get "/hub/expose/:store_id/:store_key", #{inspect(__MODULE__)}, clients: [ClientsA, ...]

    参数说明:
      - `%{clients: clients}`: 指定 clients 相当于设置白名单
      - `%{clients: {:runtime, persistent_id}}`: 在运行时获取白名单, `:persistent_term.get(persistent_id)` 返回的为 client 列表
      - `%{runtime: persistent_id, clients: clients}`: 在运行时获取白名单, `:persistent_term.get(persistent_id)` 返回的为 transform_clients 后的值
    """
    import WeChat.Plug.Helper,
      only: [json: 2, not_found: 1, get_runtime_value: 1, get_runtime_value: 2]

    alias WeChat.Work.Agent, as: WorkAgent
    @behaviour Plug

    @valid_keys [
      "access_token",
      "js_api_ticket",
      "agent_js_api_ticket",
      "wx_card_ticket",
      "component_access_token"
    ]

    @doc false
    def init(opts) do
      opts = Map.new(opts)

      maybe_runtime = fn clients ->
        case Map.get(opts, :runtime, false) do
          true ->
            if persistent_id = Map.get(opts, :persistent_id) do
              %{runtime: persistent_id, clients: clients}
            else
              raise ArgumentError,
                    "please set persistent_id when runtime: true for using #{inspect(__MODULE__)}"
            end

          false ->
            %{clients: transform_clients(clients)}

          persistent_id ->
            %{runtime: persistent_id, clients: clients}
        end
      end

      case Map.get(opts, :clients) do
        {:runtime, persistent_id} ->
          %{clients: {:runtime, persistent_id}}

        nil ->
          raise ArgumentError, "please set clients when using #{inspect(__MODULE__)}"

        client when is_atom(client) ->
          maybe_runtime.([client])

        [] ->
          raise ArgumentError, "please set clients when using #{inspect(__MODULE__)}"

        clients when is_list(clients) ->
          maybe_runtime.(clients)
      end
    end

    @doc false
    def call(%{path_params: %{"store_id" => store_id, "store_key" => store_key}} = conn, options) do
      case options do
        %{runtime: persistent_id, clients: clients} ->
          get_runtime_value({:runtime, persistent_id}, fn -> transform_clients(clients) end)

        %{clients: {:runtime, persistent_id}} ->
          with clients when clients != :error <- get_runtime_value({:runtime, persistent_id}) do
            transform_clients(clients)
          end

        %{clients: clients} ->
          clients
      end
      |> case do
        :error ->
          not_found(conn)

        clients ->
          in_scope? =
            case Map.fetch(clients, store_id) do
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
      end
    rescue
      ArgumentError -> json(conn, %{error: 404, msg: "not found"})
    end

    def call(conn, _), do: not_found(conn)

    def transform_clients(clients) do
      List.wrap(clients) |> Enum.reduce(%{}, &transform_client/2)
    end

    defp transform_client(client, acc) when is_atom(client) do
      transform_client({client, :all}, acc)
    end

    defp transform_client({client, :all}, acc) do
      if match?(:work, client.app_type()) do
        Enum.into(client.agents(), acc, &{&1.cache_id, :all})
      else
        Map.put(acc, client.appid(), :all)
      end
    end

    defp transform_client({client, scope_list}, acc) when is_list(scope_list) do
      if match?(:work, client.app_type()) do
        Enum.into(scope_list, acc, fn
          {agent, :all} ->
            {WorkAgent.fetch_agent_cache_id!(client, agent), :all}

          {agent, scope_list} when is_list(scope_list) ->
            {WorkAgent.fetch_agent_cache_id!(client, agent), scope_list}
        end)
      else
        Map.put(acc, client.appid(), scope_list)
      end
    end
  end
end
