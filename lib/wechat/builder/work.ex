defmodule WeChat.Builder.Work do
  @moduledoc false

  @default_opts [
    server_role: :client,
    by_component?: false,
    storage: WeChat.Storage.File,
    requester: WeChat.Requester.Work
  ]

  defmacro __using__(options \\ []) do
    client = __CALLER__.module
    opts = Macro.prewalk(options, &Macro.expand(&1, __CALLER__))
    default_opts = Keyword.merge(@default_opts, opts)

    unless Keyword.get(default_opts, :corp_id) |> is_binary() do
      raise ArgumentError, "please set corp_id option for #{inspect(client)}"
    end

    {agents, default_opts} =
      case Keyword.pop(default_opts, :agents, :fetch_env) do
        {[], _} ->
          raise ArgumentError, "please set at least one WeChat.Work.Agent for :agents option"

        {agents, default_opts} when is_list(agents) ->
          agents = Code.eval_quoted(agents, [], __CALLER__) |> elem(0)

          agents
          |> Enum.all?(&is_struct(&1, WeChat.Work.Agent))
          |> unless do
            raise ArgumentError, "please set WeChat.Work.Agent struct for :agents option"
          end

          {agents, default_opts}

        {:fetch_env, default_opts} ->
          {:fetch_env, default_opts}

        nil ->
          raise ArgumentError, "please set :agents option"
      end

    gen_get_functions(client, default_opts, agents)
  end

  defp gen_get_functions(client, default_opts, agents) do
    {corp_id, default_opts} = Keyword.pop!(default_opts, :corp_id)
    {requester, default_opts} = Keyword.pop!(default_opts, :requester)

    {code_name, default_opts} =
      Keyword.pop_lazy(default_opts, :code_name, fn ->
        client |> to_string() |> String.split(".") |> List.last() |> String.downcase()
      end)

    base_funs =
      quote location: :keep do
        def appid, do: unquote(corp_id)
        def code_name, do: unquote(code_name)
        def app_type, do: :work

        def get_access_token(agent) do
          WeChat.Work.Agent.fetch_agent_cache_id!(__MODULE__, agent)
          |> WeChat.Storage.Cache.get_cache(:access_token)
        end

        defdelegate get(url), to: unquote(requester)
        defdelegate get(url, opts), to: unquote(requester)
        defdelegate get(client, url, opts), to: unquote(requester)
        defdelegate post(url, body), to: unquote(requester)
        defdelegate post(url, body, opts), to: unquote(requester)
        defdelegate post(client, url, body, opts), to: unquote(requester)
      end

    get_funs =
      Enum.map(default_opts, fn {key, value} ->
        with :not_handle <- WeChat.Builder.Utils.handle_env_option(client, key, value) do
          quote do
            def unquote(key)(), do: unquote(value)
          end
        end
      end)

    agent_funs = gen_agent_funs(corp_id, agents)
    List.flatten([base_funs, get_funs, agent_funs])
  end

  defp gen_agent_funs(_corp_id, :fetch_env) do
    quote do
      def agents, do: Application.fetch_env!(:wechat, __MODULE__) |> Keyword.fetch!(:agents)
    end
  end

  defp gen_agent_funs(corp_id, agents) do
    agents =
      Enum.map(agents, fn agent ->
        Map.put(agent, :cache_id, "#{corp_id}_#{agent.id}")
      end)

    quote do
      def agents, do: unquote(Macro.escape(agents))
    end
  end
end
