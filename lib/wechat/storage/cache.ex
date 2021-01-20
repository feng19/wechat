defmodule WeChat.Storage.Cache do
  @moduledoc "缓存存储器"

  @type cache_id :: WeChat.appid()
  @type cache_sub_key :: atom
  @type cache_key :: {cache_id, cache_sub_key}
  @type cache_value :: String.t() | integer

  @compile {:inline, put_cache: 2, get_cache: 1, del_cache: 1}

  def init_table() do
    :ets.new(:wechat, [:named_table, :set, :public, read_concurrency: true])
  end

  @spec set_client(WeChat.client()) :: true
  def set_client(client), do: put_cache(client.appid(), :client, client)

  @spec search_client(WeChat.appid()) :: nil | WeChat.client()
  def search_client(appid), do: get_cache(appid, :client)

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
