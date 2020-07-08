defmodule WeChat.StoreAdapter do
  @moduledoc false
  @type appid :: String.t()
  @type store_key :: atom()
  @type value :: map()

  @callback store(appid :: String.t(), store_key :: atom(), value :: map()) :: :ok
  @callback get(appid :: String.t(), store_key :: atom()) :: {:ok, value :: map()}
end

defmodule WeChat.StoreAdapter.Default do
  @moduledoc false
  @behaviour WeChat.StoreAdapter
  @app :wechat
  @store_file "wechat_app_tokens.json"
  alias WeChat.StoreAdapter

  @impl true
  @spec store(StoreAdapter.appid(), StoreAdapter.store_key(), StoreAdapter.value()) :: :ok | any()
  def store(appid, store_key, value) do
    file = Path.join([:code.priv_dir(@app), @store_file])

    with store_key <- to_string(store_key),
         {:ok, string} <- File.read(file) do
      content =
        string
        |> Jason.decode!()
        |> Map.update(appid, %{store_key => value}, &Map.put(&1, store_key, value))
        |> Jason.encode!()

      File.write(file, content)
    else
      {:error, :enoent} ->
        with :ok <-
               Path.dirname(file)
               |> File.mkdir_p() do
          content = Jason.encode!(%{appid => %{store_key => value}})
          File.write(file, content)
        end
    end
  end

  @impl true
  @spec get(StoreAdapter.appid(), StoreAdapter.store_key()) :: {:ok, StoreAdapter.value()}
  def get(appid, store_key) do
    file = Path.join([:code.priv_dir(@app), @store_file])

    with store_key <- to_string(store_key),
         {:ok, string} <- File.read(file) do
      value =
        string
        |> Jason.decode!()
        |> get_in([appid, store_key])

      {:ok, value}
    end
  end
end
