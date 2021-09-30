defmodule WeChat.Builder.Work do
  @moduledoc false
  alias WeChat.{Work, Builder.Utils}
  alias Work.{Contacts, Customer, KF, OA, WeDrive}

  @default_opts [
    server_role: :client,
    by_component?: false,
    storage: WeChat.Storage.File,
    requester: WeChat.Requester.Work
  ]

  @sub_modules [
    Work.App,
    Work.App.Chat,
    Work.App.Menu,
    Work.App.Workbench,
    Work.Living,
    Work.Material,
    Work.Meeting,
    Work.Message,
    Work.MiniProgram,
    Customer,
    Customer.ContactWay,
    Customer.GroupChat,
    Customer.GroupMsg,
    Customer.Moment,
    Customer.Strategy,
    Customer.Tag,
    Customer.Transfer,
    Customer.Welcome,
    OA.Approval,
    OA.Calendar,
    OA.Checkin,
    OA.Journal,
    OA.MeetingRoom,
    OA.Pstncc,
    OA.Schedule,
    OA.Vacation,
    {:we_drive,
     [WeDrive.FileACL, WeDrive.FileManagement, WeDrive.SpaceACL, WeDrive.SpaceManagement]},
    {:contacts, [Contacts.Tag, Contacts.User, Contacts.Department]},
    {:kf, [KF.Account, KF.Customer, KF.Message]}
  ]

  defmacro __using__(options \\ []) do
    opts = Macro.prewalk(options, &Macro.expand(&1, __CALLER__))
    default_opts = Keyword.merge(@default_opts, opts)

    unless Keyword.get(default_opts, :corp_id) |> is_binary() do
      raise ArgumentError, "please set corp_id option"
    end

    agents =
      case Keyword.get(default_opts, :agents) do
        [] ->
          raise ArgumentError, "please set at least one Work.Agent for :agents option"

        agents when is_list(agents) ->
          agents = Code.eval_quoted(agents, [], __CALLER__) |> elem(0)

          agents
          |> Enum.all?(&is_struct(&1, WeChat.Work.Agent))
          |> unless do
            raise ArgumentError, "please set Work.Agent struct for :agents option"
          end

          agents

        nil ->
          raise ArgumentError, "please set :agents option"
      end

    client = __CALLER__.module

    sub_modules =
      if Keyword.get(default_opts, :gen_sub_module?, true) do
        default_opts
        |> Keyword.get(:sub_modules, @sub_modules)
        |> Enum.reduce([], fn
          {agent, modules}, acc ->
            # 没有定义该 应用(agent) 则不会生成对应的子模块
            case Enum.find(agents, &match?(^agent, &1.id)) do
              nil -> acc
              _ -> modules ++ acc
            end

          module, acc ->
            [module | acc]
        end)
        |> Utils.gen_sub_modules(client, 2)
      else
        []
      end

    gen_get_functions(client, default_opts, agents) ++ sub_modules
  end

  defp gen_get_functions(client, default_opts, agents) do
    corp_id = Keyword.get(default_opts, :corp_id)

    code_name =
      Keyword.get_lazy(default_opts, :code_name, fn ->
        client |> to_string() |> String.split(".") |> List.last() |> String.downcase()
      end)

    storage = Keyword.get(default_opts, :storage)
    requester = Keyword.get(default_opts, :requester)
    server_role = Keyword.get(default_opts, :server_role)
    by_component? = false

    base =
      quote location: :keep do
        def appid, do: unquote(corp_id)
        def code_name, do: unquote(code_name)
        def app_type, do: :work
        def storage, do: unquote(storage)
        def server_role, do: unquote(server_role)
        def by_component?, do: unquote(by_component?)
        def agents, do: unquote(Macro.escape(agents))

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
      |> Enum.reverse()
      |> Enum.reduce({[], []}, fn agent, {cache_id_funs, secret_funs} ->
        name = agent.name
        id = agent.id
        secret = agent.secret

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

        {
          [agent2cache_id | cache_id_funs],
          [agent_secret | secret_funs]
        }
      end)

    [
      base,
      agent2cache_id_funs,
      quote location: :keep do
        def agent2cache_id(agent) do
          raise "missing #{inspect(agent)}, maybe it's a wrong name or id, maybe it not set in agents."
        end
      end,
      agent_secret_funs,
      quote location: :keep do
        def agent_secret(agent) do
          raise "missing #{inspect(agent)}, maybe it's a wrong name or id, maybe it not set in agents."
        end
      end
    ]
    |> List.flatten()
  end
end
