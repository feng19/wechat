defmodule WeChat.Storage.File do
  @moduledoc """
  文件存储器(default)

  将 `AccessToken` 数据存储在 `wechat/priv/wechat_app_tokens.json` 文件下
  """
  alias WeChat.Storage.Adapter
  @behaviour WeChat.Storage.Adapter

  @app :wechat
  @store_file "wechat_app_tokens.json"

  @impl true
  @spec store(Adapter.store_id(), Adapter.store_key(), Adapter.value()) :: :ok | any
  def store(store_id, store_key, value) do
    get_file_name() |> store_to_file(store_id, store_key, value)
  end

  @impl true
  @spec restore(Adapter.store_id(), Adapter.store_key()) :: {:ok, Adapter.value()} | any
  def restore(store_id, store_key) do
    get_file_name() |> restore_from_file(store_id, store_key)
  end

  defp get_file_name, do: Path.join([:code.priv_dir(@app), @store_file])

  @doc false
  def store_to_file(file, store_id, store_key, value) do
    store_key = to_string(store_key)

    case File.read(file) do
      {:ok, string} ->
        content =
          string
          |> Jason.decode!()
          |> Map.update(store_id, %{store_key => value}, &Map.put(&1, store_key, value))
          |> Jason.encode!(pretty: true)

        File.write(file, content)

      {:error, :enoent} ->
        with :ok <- Path.dirname(file) |> File.mkdir_p() do
          content = Jason.encode!(%{store_id => %{store_key => value}}, pretty: true)
          File.write(file, content)
        end

      error ->
        error
    end
  end

  def restore_from_file(file, store_id, store_key) do
    with {:ok, string} <- File.read(file) do
      store_key = to_string(store_key)

      value =
        string
        |> Jason.decode!()
        |> get_in([store_id, store_key])

      {:ok, value}
    end
  end
end
