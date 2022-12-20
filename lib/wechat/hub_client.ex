defmodule WeChat.HubClient do
  @moduledoc "Helper for hub client"
  alias WeChat.{Work, Storage.Cache}
  alias Work.Agent, as: WorkAgent

  @type hub_springboard_url :: String.t()

  @spec set_hub_springboard_url(WeChat.client(), hub_springboard_url) :: true
  def set_hub_springboard_url(client, url) when is_binary(url) do
    Cache.put_cache(client.appid(), :hub_springboard_url, url)
  end

  @spec set_hub_springboard_url(WeChat.client(), Work.agent(), hub_springboard_url) :: true
  def set_hub_springboard_url(client, agent, url) when is_binary(url) do
    WorkAgent.fetch_agent_cache_id!(client, agent)
    |> Cache.put_cache(:hub_springboard_url, url)
  end

  @spec get_hub_springboard_url(WeChat.client()) :: nil | hub_springboard_url
  def get_hub_springboard_url(client) do
    Cache.get_cache(client.appid(), :hub_springboard_url)
  end

  @spec get_hub_springboard_url(WeChat.client(), Work.agent()) :: nil | hub_springboard_url
  def get_hub_springboard_url(client, agent) do
    WorkAgent.fetch_agent_cache_id!(client, agent)
    |> Cache.get_cache(:hub_springboard_url)
  end
end
