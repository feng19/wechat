defmodule WeChat.RefreshTimer do
  @moduledoc """
  token 刷新器

  这个是默认的刷新器，当然也支持自定义的刷新器，可以这样配置：
  ```elixir

  config :wechat, :refresh_timer, YourRefreshTimer

  # or with state

  config :wechat, :refresh_timer, {YourRefreshTimer, state}
  ```

  默认的刷新器支持多种配置：
  ### 配置1

  ```elixir
  config :wechat, :refresh_settings, [ClientA, ClientB, ClientC]
  ```

  以上配置会自动为三个 `Client` 定时刷新 `token` ，默认会在 `token` 过期前 `30` 分钟刷新，`token` 刷新失败的重试间隔为 `1` 分钟，
  默认的 `token` 刷新列表为：`WeChat.RefreshHelper.get_refresh_options_by_client/1` 输出的结果

  ### 配置2

  ```elixir
  config :wechat, :refresh_settings, [{ClientA, options}, ClientB, ClientC]

  # or

  config :wechat, :refresh_settings, %{ClientA => options, ClientB => options, ClientC => options}
  ```

  `options` 配置说明见：`t:options/0`
  """
  use GenServer
  require Logger
  alias WeChat.Storage.Adapter, as: StorageAdapter
  alias WeChat.{Utils, Storage.Cache}

  # 过期前 30 分钟刷新
  @refresh_before_expired 30 * 60
  # 刷新失败重试时间间隔 1 分钟
  @refresh_retry_interval 60

  @typedoc "在 `token` 过去前多少秒刷新，单位：秒"
  @type refresh_before_expired :: non_neg_integer
  @typedoc "刷新 `token` 失败的重试间隔，单位：秒"
  @type refresh_retry_interval :: non_neg_integer
  @typedoc """

  option
  - `:refresh_before_expired`: 在 `token` 过去前多少秒刷新，单位：秒，可选，默认值：`#{@refresh_before_expired}` 秒
  - `:refresh_retry_interval`: 刷新 `token` 失败的重试间隔，单位：秒，可选，默认值：`#{@refresh_retry_interval * 1000}` 秒
  - `:refresh_options`: 刷新 `token` 配置，可选，默认值：`WeChat.RefreshHelper.get_refresh_options_by_client/1` 的输出结果
  """
  @type options ::
          %{
            optional(:refresh_before_expired) => refresh_before_expired,
            optional(:refresh_retry_interval) => refresh_retry_interval,
            optional(:refresh_options) => WeChat.RefreshHelper.refresh_options()
          }

  @spec add(WeChat.client(), options) :: :ok
  def add(client, opts) do
    GenServer.call(__MODULE__, {:add, client, opts})
  end

  @spec remove(WeChat.client()) :: :ok
  def remove(client) do
    GenServer.call(__MODULE__, {:remove, client})
  end

  @spec refresh(WeChat.client()) :: :ok | :nofound
  def refresh(client) do
    GenServer.call(__MODULE__, {:refresh, client})
  end

  @spec refresh_key(
          StorageAdapter.store_id(),
          StorageAdapter.store_key(),
          StorageAdapter.value(),
          expired_time :: integer(),
          WeChat.client()
        ) :: :ok
  def refresh_key(store_id, store_key, value, expired_time, client) do
    GenServer.cast(__MODULE__, {:refresh_key, store_id, store_key, value, expired_time, client})
  end

  @spec start_link(state :: %{WeChat.client() => options}) :: GenServer.on_start()
  def start_link(state \\ %{}) do
    GenServer.start_link(__MODULE__, state, name: __MODULE__)
  end

  @impl true
  def init(state) do
    state =
      Map.new(state, fn
        client when is_atom(client) ->
          {client, do_add(client, %{})}

        {client, opts} ->
          {client, do_add(client, opts)}
      end)

    {:ok, state}
  end

  @impl true
  def handle_call({:add, client, opts}, _from, state) do
    opts = do_add(client, opts)
    state = Map.put(state, client, opts)
    {:reply, :ok, state}
  end

  def handle_call({:remove, client}, _from, state) do
    {get, state} = Map.pop(state, client)

    with {_client, opts} <- get do
      Enum.each(opts.refresh_options, fn {_key, _fun, timer} ->
        :erlang.cancel_timer(timer)
      end)
    end

    {:reply, :ok, state}
  end

  def handle_call({:refresh, client}, _from, state) do
    with opts when is_map(opts) <- Map.get(state, client) do
      opts = do_refresh(client, opts)
      state = Map.put(state, client, opts)
      {:reply, :ok, state}
    else
      _ ->
        {:reply, :nofound, state}
    end
  end

  @impl true
  def handle_cast({:refresh_key, store_id, store_key, value, expired_time, client}, state) do
    cache_and_store(store_id, store_key, value, expired_time, client)
    {:ok, state}
  end

  @impl true
  def handle_info(
        {:timeout, _timer,
         {:refresh_token, %{store_id: store_id, store_key: store_key, client: client}}},
        state
      ) do
    case Map.get(state, client) do
      opts when opts != nil ->
        key = {store_id, store_key}
        {{_key, fun, _timer}, refresh_options} = List.keytake(opts.refresh_options, key, 0)
        timer = refresh_token(store_id, store_key, fun, client, opts)

        state =
          Map.put(state, client, %{opts | refresh_options: [{key, fun, timer} | refresh_options]})

        {:noreply, state}

      _ ->
        {:noreply, state}
    end
  end

  defp cache_and_store(store_id, store_key, value, expired_time, client) do
    Cache.put_cache(store_id, store_key, value)

    if storage = client.storage() do
      result =
        storage.store(store_id, store_key, %{"value" => value, "expired_time" => expired_time})

      Logger.info(
        "Store appid: #{store_id}, key: #{store_key} by #{inspect(storage)} => #{inspect(result)}."
      )
    end
  end

  defp restore_and_cache(store_id, store_key, client) do
    with storage when storage != nil <- client.storage(),
         {:ok, %{"value" => value, "expired_time" => expired_time}} <-
           storage.restore(store_id, store_key) do
      diff = expired_time - Utils.now_unix()

      if diff > 0 do
        Cache.put_cache(store_id, store_key, value)

        Logger.info(
          "Get appid: #{store_id}, key: #{store_key}, expires_in: #{diff} from storage: #{
            inspect(storage)
          } succeed."
        )

        {true, diff}
      else
        Logger.info(
          "Get appid: #{store_id}, key: #{store_key}] from storage: #{inspect(storage)} token expired."
        )

        false
      end
    else
      nil ->
        false

      error ->
        Logger.warn(
          "Get appid: #{store_id}, key: #{store_key} from storage: #{inspect(client.storage())} error: #{
            inspect(error)
          }."
        )

        false
    end
  end

  defp do_add(client, opts) do
    opts =
      Map.merge(opts, %{
        refresh_before_expired: Map.get(opts, :refresh_before_expired, @refresh_before_expired),
        refresh_retry_interval:
          Map.get(opts, :refresh_retry_interval, @refresh_retry_interval) * 1000
      })

    Cache.set_client(client)

    refresh_options = init_refresh_options(client, opts)

    Logger.info(
      "Initialize WeChat Client: #{inspect(client)} by Role: #{client.role()}, Storage: #{
        inspect(client.storage())
      }."
    )

    refresh_options =
      for {id_type, store_key, fun} <- refresh_options do
        store_id = get_store_id_by_id_type(id_type, client)

        timer =
          case restore_and_cache(store_id, store_key, client) do
            false ->
              refresh_token(store_id, store_key, fun, client, opts)

            {true, expires_in} ->
              ((expires_in - opts.refresh_before_expired) * 1000)
              |> max(0)
              |> start_refresh_token_timer(store_id, store_key, client)
          end

        {{store_id, store_key}, fun, timer}
      end

    Map.put(opts, :refresh_options, refresh_options)
  end

  defp do_refresh(client, %{refresh_options: refresh_options} = opts) do
    Logger.info(
      "Refreshing WeChat Client: #{inspect(client)} with list: #{inspect(refresh_options)}."
    )

    refresh_options =
      for {{store_id, store_key}, fun, timer} <- refresh_options do
        :erlang.cancel_timer(timer)
        timer = refresh_token(store_id, store_key, fun, client, opts)
        {{store_id, store_key}, fun, timer}
      end

    %{opts | refresh_options: refresh_options}
  end

  @compile {:inline, get_store_id_by_id_type: 2}
  defp get_store_id_by_id_type(:appid, client), do: client.appid()
  defp get_store_id_by_id_type(:component_appid, client), do: client.component_appid()

  defp refresh_token(store_id, store_key, fun, client, opts) do
    case fun.(client) do
      {:ok, list, expires_in} when is_list(list) ->
        now = Utils.now_unix()

        Enum.each(list, fn {key, token, expires_in} ->
          expired_time = now + expires_in
          cache_and_store(store_id, key, token, expired_time, client)
        end)

        Logger.info(
          "Refresh appid: #{store_id}, key: #{store_key}, expires_in: #{expires_in} succeed."
        )

        ((expires_in - opts.refresh_before_expired) * 1000)
        |> max(0)
        |> start_refresh_token_timer(store_id, store_key, client)

      {:ok, token, expires_in} ->
        expired_time = Utils.now_unix() + expires_in
        cache_and_store(store_id, store_key, token, expired_time, client)

        Logger.info(
          "Refresh appid: #{store_id}, key: #{store_key}, expires_in: #{expires_in} succeed."
        )

        ((expires_in - opts.refresh_before_expired) * 1000)
        |> max(0)
        |> start_refresh_token_timer(store_id, store_key, client)

      error ->
        Logger.warn(
          "Refresh appid: #{store_id}, key: #{store_key} error: #{inspect(error)}, Will be retry again one minute later."
        )

        start_refresh_token_timer(opts.refresh_retry_interval, store_id, store_key, client)
    end
  end

  defp start_refresh_token_timer(time, store_id, store_key, client) do
    info = %{store_id: store_id, store_key: store_key, client: client}
    :erlang.start_timer(time, self(), {:refresh_token, info})
  end

  defp init_refresh_options(client, opts) do
    case Map.get(opts, :refresh_options) do
      fun when is_function(fun, 0) ->
        fun.()

      fun when is_function(fun, 1) ->
        fun.(client)

      refresh_options when is_list(refresh_options) ->
        refresh_options

      nil ->
        WeChat.RefreshHelper.get_refresh_options_by_client(client)
    end
  end
end
