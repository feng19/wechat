defmodule WeChat.Storage.PayFile do
  @moduledoc false
  alias WeChat.Storage.Adapter
  @behaviour WeChat.Storage.Adapter

  @app :wechat
  @store_file "wechat_pay_cacerts"

  @impl true
  @spec store(Adapter.store_id(), Adapter.store_key(), Adapter.value()) :: :ok | any()
  def store(store_id, store_key, value) do
    file = get_file_name(store_id)
    store_key = to_string(store_key)

    case File.read(file) do
      {:ok, string} ->
        content =
          string
          |> Jason.decode!()
          |> Map.update(store_id, %{store_key => value}, &Map.put(&1, store_key, value))
          |> Jason.encode!()

        File.write(file, content)

      {:error, :enoent} ->
        with :ok <- Path.dirname(file) |> File.mkdir_p() do
          content = Jason.encode!(%{store_id => %{store_key => value}})
          File.write(file, content)
        end

      error ->
        error
    end
  end

  @impl true
  @spec restore(Adapter.store_id(), Adapter.store_key()) :: {:ok, Adapter.value()}
  def restore(store_id, store_key) do
    file = get_file_name(store_id)
    store_key = to_string(store_key)

    with {:ok, string} <- File.read(file) do
      value =
        string
        |> Jason.decode!()
        |> get_in([store_id, store_key])

      {:ok, value}
    end
  end

  defp get_file_name(store_id) do
    Path.join([:code.priv_dir(@app), @store_file <> "_#{store_id}"]) <> ".json"
  end
end
