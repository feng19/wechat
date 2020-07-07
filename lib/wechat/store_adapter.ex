defmodule WeChat.StoreAdapter do
  @moduledoc false
  @callback store(appid :: String.t(), store_key :: atom(), map()) :: :ok
  @callback get(appid :: String.t(), store_key :: atom()) :: {:ok, map()}
end

defmodule WeChat.StoreAdapter.Default do
  @moduledoc false
  @behaviour WeChat.StoreAdapter
  @app :wechat
  @store_file "wechat_app_tokens.json"

  def store(appid, store_key, map) do
    file = Path.join([:code.priv_dir(@app), @store_file])

    with store_key <- to_string(store_key),
         {:ok, string} <- File.read(file) do
      content =
        string
        |> Jason.decode!()
        |> Map.update(appid, %{store_key => map}, &Map.put(&1, store_key, map))
        |> Jason.encode!()

      File.write(file, content)
    else
      {:error, :enoent} ->
        with :ok <-
               Path.dirname(file)
               |> File.mkdir_p() do
          content = Jason.encode!(%{appid => %{store_key => map}})
          File.write(file, content)
        end
    end
  end

  def get(appid, store_key) do
    file = Path.join([:code.priv_dir(@app), @store_file])

    with store_key <- to_string(store_key),
         {:ok, string} <- File.read(file) do
      map =
        string
        |> Jason.decode!()
        |> get_in([appid, store_key])

      {:ok, map}
    end
  end
end
