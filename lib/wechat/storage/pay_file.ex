defmodule WeChat.Storage.PayFile do
  @moduledoc """
  微信支付 - 文件存储器(default)

  数据存储在 `wechat/priv/wechat_pay_cacerts_xxx.json` 文件下
  """
  import WeChat.Storage.File, only: [store_to_file: 4, restore_from_file: 3]
  alias WeChat.Storage.Adapter
  @behaviour WeChat.Storage.Adapter

  @app :wechat
  @store_file "wechat_pay_cacerts"

  @impl true
  @spec store(Adapter.store_id(), Adapter.store_key(), Adapter.value()) :: :ok | any
  def store(store_id, store_key, value) do
    get_file_name(store_id) |> store_to_file(store_id, store_key, value)
  end

  @impl true
  @spec restore(Adapter.store_id(), Adapter.store_key()) :: {:ok, Adapter.value()} | any
  def restore(store_id, store_key) do
    get_file_name(store_id) |> restore_from_file(store_id, store_key)
  end

  defp get_file_name(store_id) do
    Path.join([:code.priv_dir(@app), @store_file <> "_#{store_id}"]) <> ".json"
  end
end
