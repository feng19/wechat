defmodule WeChat.Storage.Cache do
  @moduledoc "缓存存储器"

  @type cache_id :: WeChat.appid()
  @type cache_sub_key :: term
  @type cache_key :: {cache_id, cache_sub_key}
  @type cache_value :: term

  @compile {:inline, put_cache: 2, get_cache: 1, del_cache: 1}

  alias WeChat.Work

  @doc false
  def init_table do
    :ets.new(:wechat, [:named_table, :set, :public, read_concurrency: true])
  end

  @spec set_client(WeChat.client()) :: true
  def set_client(client) do
    appid = client.appid()
    code_name = client.code_name()
    app_list = Enum.uniq([appid, code_name])
    Enum.map(app_list, &{{&1, :client}, client}) |> put_caches()

    if match?(:work, client.app_type()) do
      Enum.flat_map(client.agents(), &agent_cache_list(app_list, client, &1))
      |> put_caches()
    end
  end

  @spec set_work_agent(WeChat.client(), Work.Agent.t()) :: true
  def set_work_agent(client, agent) do
    appid = client.appid()
    code_name = client.code_name()

    Enum.uniq([appid, code_name])
    |> agent_cache_list(client, agent)
    |> List.flatten()
    |> put_caches()
  end

  defp agent_cache_list(app_list, client, agent) do
    agent_id = agent.id
    name = agent.name
    agent_list = Enum.uniq([agent_id, to_string(agent_id), name, to_string(name)])
    value = {client, agent}

    for app_flag <- app_list, agent_flag <- agent_list do
      {{app_flag, agent_flag}, value}
    end
  end

  @spec search_client(WeChat.appid() | WeChat.code_name()) :: nil | WeChat.client()
  def search_client(app_flag), do: get_cache(app_flag, :client)

  @spec search_client_agent(WeChat.appid() | WeChat.code_name(), Work.agent() | String.t()) ::
          nil | {WeChat.client(), Work.Agent.t()}
  def search_client_agent(app_flag, agent_flag), do: get_cache(app_flag, agent_flag)

  @spec put_cache(cache_id(), cache_sub_key(), cache_value()) :: true
  def put_cache(id, sub_key, value) do
    put_cache({id, sub_key}, value)
  end

  @spec put_cache(cache_key(), cache_value()) :: true
  def put_cache(key, value) do
    :ets.insert(:wechat, {key, value})
  end

  @spec put_caches([{cache_key(), cache_value()}]) :: true
  def put_caches(list) when is_list(list) do
    :ets.insert(:wechat, list)
  end

  @spec get_cache(cache_id(), cache_sub_key()) :: nil | cache_value()
  def get_cache(id, sub_key) do
    get_cache({id, sub_key})
  end

  @spec get_cache(cache_key()) :: nil | cache_value()
  def get_cache(key) do
    case :ets.lookup(:wechat, key) do
      [{_, value}] -> value
      _ -> nil
    end
  end

  @spec del_cache(cache_id(), cache_sub_key()) :: true
  def del_cache(id, sub_key) do
    del_cache({id, sub_key})
  end

  @spec del_cache(cache_key()) :: true
  def del_cache(key) do
    :ets.delete(:wechat, key)
  end
end
