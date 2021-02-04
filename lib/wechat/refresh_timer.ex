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

  为了适应 `Storage` 在 `RefreshTimer` 启动之后才启动，可以开启延时启动刷新:

  ```elixir
  config :wechat, WeChat.RefreshTimer, wait_for_signal: true
  ```

  当所有的 `Storage` 都已经完成，可以即可通过 `WeChat.RefreshTimer.start_monitor/0` 方法刷新 `token`

  不配置默认为立即启动刷新
  """
  use GenServer
  require Logger
  alias WeChat.Storage.Adapter, as: StorageAdapter
  alias WeChat.{Utils, Storage.Cache}

  # 过期前 30 分钟刷新
  @refresh_before_expired 30 * 60
  # 刷新失败重试时间间隔 1 分钟
  @refresh_retry_interval 60

  @typedoc """
  在 `token` 过去前多少秒刷新，单位：秒

  如果`server_role` = `hub`, `hub server` 的值请大于 `hub client`
  """
  @type refresh_before_expired :: non_neg_integer
  @typedoc "刷新 `token` 失败的重试间隔，单位：秒"
  @type refresh_retry_interval :: non_neg_integer
  @typedoc """

  option
  - `:refresh_before_expired`: 在 `token` 过去前多少秒刷新，单位：秒，可选，
  为保证 `hub` & `hub_client` 刷新正常，请保持两者的时间一致；
  `server_role=hub_client` 时, 默认值：`#{@refresh_before_expired} + 30` 秒；
  其余角色默认值：`#{@refresh_before_expired}` 秒
  - `:refresh_retry_interval`: 刷新 `token` 失败的重试间隔，单位：秒，可选，默认值：`#{@refresh_retry_interval * 1000}` 秒
  - `:refresh_options`: 刷新 `token` 配置，可选，默认值：`WeChat.RefreshHelper.get_refresh_options_by_client/1` 的输出结果
  """
  @type options ::
          %{
            optional(:refresh_before_expired) => refresh_before_expired,
            optional(:refresh_retry_interval) => refresh_retry_interval,
            optional(:refresh_options) => WeChat.RefreshHelper.refresh_options()
          }

  @spec start_monitor() :: :ok
  def start_monitor do
    GenServer.call(__MODULE__, :start_monitor)
  end

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
          {client, init_client_options(client, %{})}

        {client, opts} ->
          {client, init_client_options(client, opts)}
      end)

    clients = Map.keys(state)

    options =
      :wechat
      |> Application.get_env(__MODULE__, %{})
      |> Map.new()

    state =
      %{wait_for_signal: false}
      |> Map.merge(options)
      |> Map.merge(state)
      |> Map.put(:clients, clients)

    continue =
      if state.wait_for_signal do
        :wait_for_signal
      else
        :start_monitor
      end

    {:ok, state, {:continue, continue}}
  end

  @impl true
  def handle_continue(:wait_for_signal, state) do
    {:noreply, state}
  end

  def handle_continue(:start_monitor, state) do
    state =
      Enum.reduce(state.clients, state, fn client, acc ->
        options = start_monitor_client(client, Map.get(acc, client))
        Map.put(acc, client, options)
      end)

    {:noreply, %{state | wait_for_signal: false}}
  end

  @impl true
  def handle_call(:start_monitor, _from, state) do
    {:reply, :ok, state, {:continue, :start_monitor}}
  end

  def handle_call({:add, client, options}, _from, state) do
    options =
      if state.wait_for_signal do
        init_client_options(client, options)
      else
        options = init_client_options(client, options)
        start_monitor_client(client, options)
      end

    state =
      state
      |> Map.put(client, options)
      |> Map.put(:clients, [client | state.clients])

    {:reply, :ok, state}
  end

  def handle_call({:remove, client}, _from, state) do
    {get, state} = Map.pop(state, client)
    clients = List.delete(state.clients, client)

    with {_client, opts} <- get do
      Enum.each(opts.refresh_options, fn {_key, _fun, timer} ->
        cancel_timer(timer)
      end)
    end

    {:reply, :ok, %{state | clients: clients}}
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

    with storage when storage != nil <- client.storage(),
         # 因为 hub_client 是从 storage 中读取 token 的，因此不需要再做写入操作
         true <- client.server_role() != :hub_client do
      result =
        storage.store(store_id, store_key, %{"value" => value, "expired_time" => expired_time})

      Logger.info(
        "Call #{inspect(storage)}.restore(#{store_id}, #{store_key}) => #{inspect(result)}."
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
          "Call #{inspect(storage)}.restore(#{store_id}, #{store_key}) succeed, the expires_in is: #{
            diff
          }s."
        )

        {true, diff}
      else
        Logger.info(
          "Call #{inspect(storage)}.restore(#{store_id}, #{store_key}) succeed, but the token expired."
        )

        false
      end
    else
      nil ->
        false

      error ->
        Logger.warn(
          "Call #{inspect(client.storage())}.restore(#{store_id}, #{store_key}) failed, return error: #{
            inspect(error)
          }."
        )

        false
    end
  end

  defp init_client_options(client, options) do
    Logger.info(
      "Initialize WeChat Client: #{inspect(client)} by AppType: #{client.app_type()}, Storage: #{
        inspect(client.storage())
      }."
    )

    default_refresh_before_expired =
      if match?(:hub_client, client.server_role()) do
        @refresh_before_expired + 30
      else
        @refresh_before_expired
      end

    options =
      Map.merge(options, %{
        refresh_before_expired:
          Map.get(options, :refresh_before_expired, default_refresh_before_expired),
        refresh_retry_interval:
          Map.get(options, :refresh_retry_interval, @refresh_retry_interval) * 1000
      })

    Cache.set_client(client)

    refresh_options = init_refresh_options(client, options)
    Map.put(options, :refresh_options, refresh_options)
  end

  defp start_monitor_client(client, options) do
    Logger.info("Monitoring WeChat Client: #{inspect(client)}.")

    refresh_options =
      for {{store_id, store_key}, fun, _timer} <- options.refresh_options do
        timer =
          case restore_and_cache(store_id, store_key, client) do
            false ->
              refresh_token(store_id, store_key, fun, client, options)

            {true, expires_in} ->
              ((expires_in - options.refresh_before_expired) * 1000)
              |> max(0)
              |> start_refresh_token_timer(store_id, store_key, client)
          end

        {{store_id, store_key}, fun, timer}
      end

    %{options | refresh_options: refresh_options}
  end

  defp do_refresh(client, %{refresh_options: refresh_options} = opts) do
    Logger.info(
      "Refreshing WeChat Client: #{inspect(client)} with list: #{inspect(refresh_options)}."
    )

    refresh_options =
      for {{store_id, store_key}, fun, timer} <- refresh_options do
        cancel_timer(timer)
        timer = refresh_token(store_id, store_key, fun, client, opts)
        {{store_id, store_key}, fun, timer}
      end

    %{opts | refresh_options: refresh_options}
  end

  defp cancel_timer(nil), do: :ignore
  defp cancel_timer(timer), do: :erlang.cancel_timer(timer)

  @compile {:inline, get_store_id_by_id_type: 2}
  defp get_store_id_by_id_type(:appid, client), do: client.appid()
  defp get_store_id_by_id_type(:component_appid, client), do: client.component_appid()
  defp get_store_id_by_id_type(store_id, _client) when is_binary(store_id), do: store_id

  defp refresh_token(store_id, store_key, fun, client, options) do
    case fun.(client) do
      {:ok, list, expires_in} when is_list(list) ->
        now = Utils.now_unix()

        Enum.each(list, fn {key, token, expires_in} ->
          expired_time = now + expires_in
          cache_and_store(store_id, key, token, expired_time, client)
        end)

        Logger.info(
          "Refresh appid: #{store_id}, key: #{store_key} succeed, get expires_in: #{expires_in}s."
        )

        ((expires_in - options.refresh_before_expired) * 1000)
        |> max(options.refresh_retry_interval)
        |> start_refresh_token_timer(store_id, store_key, client)

      {:ok, token, expires_in} ->
        expired_time = Utils.now_unix() + expires_in
        cache_and_store(store_id, store_key, token, expired_time, client)

        Logger.info(
          "Refresh appid: #{store_id}, key: #{store_key} succeed, get expires_in: #{expires_in}s."
        )

        ((expires_in - options.refresh_before_expired) * 1000)
        |> max(options.refresh_retry_interval)
        |> start_refresh_token_timer(store_id, store_key, client)

      error ->
        refresh_retry_interval = options.refresh_retry_interval

        Logger.warn(
          "Refresh appid: #{store_id}, key: #{store_key} failed, return error: #{inspect(error)}, Will be retry again #{
            refresh_retry_interval
          }s later."
        )

        start_refresh_token_timer(refresh_retry_interval, store_id, store_key, client)
    end
  end

  defp start_refresh_token_timer(time, store_id, store_key, client) do
    Logger.info("Start Refresh Timer for appid: #{store_id}, key: #{store_key}, time: #{time}s.")
    info = %{store_id: store_id, store_key: store_key, client: client}
    :erlang.start_timer(time, self(), {:refresh_token, info})
  end

  defp init_refresh_options(client, opts) do
    refresh_options =
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

    for {id_type, store_key, fun} <- refresh_options do
      store_id = get_store_id_by_id_type(id_type, client)
      {{store_id, store_key}, fun, nil}
    end
  end
end
