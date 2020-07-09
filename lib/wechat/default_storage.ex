defmodule WeChat.DefaultStorage do
  @moduledoc """
  默认存储器

  将数据存储在 `wechat/priv/wechat_app_tokens.json` 文件下
  """
  @behaviour WeChat.StorageAdapter
  @app :wechat
  @store_file "wechat_app_tokens.json"
  alias WeChat.StorageAdapter

  @impl true
  @spec store(StorageAdapter.store_id(), StorageAdapter.store_key(), StorageAdapter.value()) :: :ok | any()
  def store(store_id, store_key, value) do
    file = Path.join([:code.priv_dir(@app), @store_file])

    with store_key <- to_string(store_key),
         {:ok, string} <- File.read(file) do
      content =
        string
        |> Jason.decode!()
        |> Map.update(store_id, %{store_key => value}, &Map.put(&1, store_key, value))
        |> Jason.encode!()

      File.write(file, content)
    else
      {:error, :enoent} ->
        with :ok <-
               Path.dirname(file)
               |> File.mkdir_p() do
          content = Jason.encode!(%{store_id => %{store_key => value}})
          File.write(file, content)
        end
    end
  end

  @impl true
  @spec restore(StorageAdapter.store_id(), StorageAdapter.store_key()) :: {:ok, StorageAdapter.value()}
  def restore(store_id, store_key) do
    file = Path.join([:code.priv_dir(@app), @store_file])

    with store_key <- to_string(store_key),
         {:ok, string} <- File.read(file) do
      value =
        string
        |> Jason.decode!()
        |> get_in([store_id, store_key])

      {:ok, value}
    end
  end
end
