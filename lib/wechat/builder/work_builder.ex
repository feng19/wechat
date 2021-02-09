defmodule WeChat.WorkBuilder do
  @moduledoc false

  @default_opts [
    server_role: :client,
    by_component?: false,
    storage: WeChat.Storage.File,
    requester: WeChat.WorkRequester
  ]

  defmacro __using__(options \\ []) do
    opts = Macro.prewalk(options, &Macro.expand(&1, __CALLER__))
    default_opts = Keyword.merge(@default_opts, opts)

    corp_id =
      case Keyword.get(default_opts, :corp_id) do
        corp_id when is_binary(corp_id) -> corp_id
        _ -> raise ArgumentError, "please set corp_id option"
      end

    agents =
      case Keyword.get(default_opts, :agents) do
        [] ->
          raise ArgumentError, "please set at least one Work.Agent for :agents option"

        agents when is_list(agents) ->
          agents
          |> Code.eval_quoted()
          |> elem(0)
          |> Enum.all?(&is_struct(&1, WeChat.Work.Agent))
          |> unless do
            raise ArgumentError, "please set Work.Agent struct for :agents option"
          end

          agents

        nil ->
          raise ArgumentError, "please set :agents option"
      end

    storage = Keyword.get(default_opts, :storage)
    requester = Keyword.get(default_opts, :requester)
    server_role = Keyword.get(default_opts, :server_role)
    by_component? = false

    base =
      quote location: :keep do
        def appid, do: unquote(corp_id)
        def app_type, do: :work
        def storage, do: unquote(storage)
        def server_role, do: unquote(server_role)
        def by_component?, do: unquote(by_component?)
        def agents, do: unquote(agents)

        def get_access_token(agent) do
          agent
          |> agent2cache_id()
          |> WeChat.Storage.Cache.get_cache(:access_token)
        end

        defdelegate get(url), to: unquote(requester)
        defdelegate get(url, opts), to: unquote(requester)
        defdelegate get(client, url, opts), to: unquote(requester)
        defdelegate post(url, body), to: unquote(requester)
        defdelegate post(url, body, opts), to: unquote(requester)
        defdelegate post(client, url, body, opts), to: unquote(requester)
      end

    {agent2cache_id_funs, agent_secret_funs} =
      agents
      |> Code.eval_quoted()
      |> elem(0)
      |> Enum.map(fn agent ->
        name = agent.name
        id = agent.id

        agent2cache_id =
          if name == id or name == nil do
            quote location: :keep do
              def agent2cache_id(unquote(id)), do: unquote("#{corp_id}_#{id}")
            end
          else
            quote location: :keep do
              def agent2cache_id(unquote(name)), do: unquote("#{corp_id}_#{id}")
              def agent2cache_id(unquote(id)), do: unquote("#{corp_id}_#{id}")
            end
          end

        secret = agent.secret

        agent_secret =
          if secret do
            if name == id or name == nil do
              quote location: :keep do
                def agent_secret(unquote(id)), do: unquote(secret)
              end
            else
              quote location: :keep do
                def agent_secret(unquote(name)), do: unquote(secret)
                def agent_secret(unquote(id)), do: unquote(secret)
              end
            end
          end

        {agent2cache_id, agent_secret}
      end)
      |> Enum.unzip()

    [base | agent2cache_id_funs] ++ agent_secret_funs
  end
end
