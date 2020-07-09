defmodule WeChat.StorageAdapter do
  @moduledoc false
  @type store_id :: String.t()
  @type store_key :: atom() | String.t()
  @type value :: map()

  @callback store(store_id(), store_key(), value()) :: :ok
  @callback restore(store_id(), store_key()) :: {:ok, value()}
end
