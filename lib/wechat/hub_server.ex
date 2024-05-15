defmodule WeChat.HubServer do
  @moduledoc "Helper for hub server"
  alias WeChat.{Work, Storage.Cache}
  alias Work.Agent, as: WorkAgent

  @type env :: String.t()
  @type url :: String.t()
  @type oauth2_callbacks :: %{env => url}

  @spec list_oauth2_callbacks(WeChat.client()) :: oauth2_callbacks
  def list_oauth2_callbacks(client) do
    if match?(:work, client.app_type()) do
      Enum.map(
        client.agents(),
        &{
          &1.id,
          Cache.match({_key = {&1.cache_id, {:oauth2_env_url, :_}}, :"$1"})
          |> Enum.map(fn [v] -> v end)
        }
      )
    else
      Cache.match({_key = {client.appid(), {:oauth2_env_url, :_}}, :"$1"})
      |> Enum.map(fn [v] -> v end)
    end
  end

  @spec clean_oauth2_callbacks(WeChat.client()) :: :ok
  def clean_oauth2_callbacks(client) do
    if match?(:work, client.app_type()) do
      Enum.each(
        client.agents(),
        &Cache.match_delete({_key = {&1.cache_id, {:oauth2_env_url, :_}}, :_})
      )
    else
      Cache.match_delete({_key = {client.appid(), {:oauth2_env_url, :_}}, :_})
      :ok
    end
  end

  @spec set_oauth2_callbacks(WeChat.client(), oauth2_callbacks) :: [true]
  def set_oauth2_callbacks(client, oauth2_callbacks) do
    for {env, url} <- oauth2_callbacks, is_binary(env) and is_binary(url) do
      set_oauth2_env_url(client, env, url)
    end
  end

  @spec set_oauth2_callbacks(WeChat.client(), Work.agent(), oauth2_callbacks) :: [true]
  def set_oauth2_callbacks(client, agent, oauth2_callbacks) do
    for {env, url} <- oauth2_callbacks, is_binary(env) and is_binary(url) do
      set_oauth2_env_url(client, agent, env, url)
    end
  end

  @spec set_oauth2_env_url(WeChat.client(), env, url) :: true
  def set_oauth2_env_url(client, env, url) when is_binary(env) and is_binary(url) do
    Cache.put_cache(client.appid(), {:oauth2_env_url, env}, url)
  end

  @spec set_oauth2_env_url(WeChat.client(), Work.agent(), env, url) :: true
  def set_oauth2_env_url(client, agent, env, url) when is_binary(env) and is_binary(url) do
    WorkAgent.fetch_agent_cache_id!(client, agent)
    |> Cache.put_cache({:oauth2_env_url, env}, url)
  end

  @spec get_oauth2_env_url(WeChat.client(), env) :: nil | url
  def get_oauth2_env_url(client, env) do
    Cache.get_cache(client.appid(), {:oauth2_env_url, env})
  end

  @spec get_oauth2_env_url(WeChat.client(), Work.agent(), env) :: nil | url
  def get_oauth2_env_url(client, agent, env) do
    WorkAgent.fetch_agent_cache_id!(client, agent)
    |> Cache.get_cache({:oauth2_env_url, env})
  end

  @spec del_oauth2_env_url(WeChat.client(), env) :: true
  def del_oauth2_env_url(client, env) do
    Cache.del_cache(client.appid(), {:oauth2_env_url, env})
  end

  @spec del_oauth2_env_url(WeChat.client(), Work.agent(), env) :: true
  def del_oauth2_env_url(client, agent, env) do
    WorkAgent.fetch_agent_cache_id!(client, agent)
    |> Cache.del_cache({:oauth2_env_url, env})
  end
end
