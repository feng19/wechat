defmodule WeChat.Storage.Cache do
  @moduledoc "缓存存储器"

  @type cache_id :: WeChat.appid()
  @type cache_sub_key :: atom
  @type cache_key :: {cache_id, cache_sub_key}
  @type cache_value :: String.t() | integer
  @typep app :: String.t()
  @typep url :: String.t()

  @compile {:inline, put_cache: 2, get_cache: 1, del_cache: 1}

  def init_table() do
    :ets.new(:wechat, [:named_table, :set, :public, read_concurrency: true])
  end

  @spec set_client(WeChat.client()) :: true
  def set_client(client) do
    put_cache(client.appid(), :client, client)
    put_cache(client.code_name(), :client, client)
  end

  @spec search_client(WeChat.appid()) :: nil | WeChat.client()
  def search_client(appid), do: get_cache(appid, :client)

  @spec search_client_by_name(WeChat.code_name()) :: nil | WeChat.client()
  def search_client_by_name(code_name) when is_binary(code_name),
    do: code_name |> String.downcase() |> get_cache(:client)

  @spec set_hub_oauth2_url(WeChat.client(), url) :: true
  def set_hub_oauth2_url(client, url) when is_binary(url) do
    put_cache(client.appid(), :hub_oauth2_url, url)
  end

  @spec get_hub_oauth2_url(WeChat.client()) :: nil | url
  def get_hub_oauth2_url(client) do
    get_cache(client.appid(), :hub_oauth2_url)
  end

  @spec set_oauth2_app_url(WeChat.client(), app, url) :: true
  def set_oauth2_app_url(client, app, url) when is_binary(app) and is_binary(url) do
    put_cache(client.appid(), {:oauth2_app, app}, url)
  end

  @spec get_oauth2_app_url(WeChat.client(), app) :: nil | url
  def get_oauth2_app_url(client, app) do
    get_cache(client.appid(), {:oauth2_app, app})
  end

  @spec put_cache(cache_id(), cache_sub_key(), cache_value()) :: true
  def put_cache(id, sub_key, value) do
    put_cache({id, sub_key}, value)
  end

  @spec put_cache(cache_key(), cache_value()) :: true
  def put_cache(key, value) do
    :ets.insert(:wechat, {key, value})
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
