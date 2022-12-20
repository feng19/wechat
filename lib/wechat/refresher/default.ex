defmodule WeChat.Refresher.Default do
  @moduledoc """
  AccessToken 刷新器 - 用于定时刷新 AccessToken

  [官方说明](https://developers.weixin.qq.com/doc/offiaccount/Getting_Started/Getting_Started_Guide.html#_1-5-%E9%87%8D%E8%A6%81%E4%BA%8B%E6%83%85%E6%8F%90%E5%89%8D%E4%BA%A4%E4%BB%A3)

  本模块为默认的刷新器

  需要修改为自定义的刷新器，可以这样配置：

      config :wechat, :refresher, YourRefresher

  修改刷新器的配置，支持多种配置方式：

  ### 方式1

      config :wechat, :refresh_settings, [ClientA, ClientB, ClientC]

  以上配置会自动为三个 `Client` 定时刷新 `AccessToken` ，
  默认会在 `AccessToken` 过期前 `30` 分钟刷新，
  `AccessToken` 刷新失败的重试间隔为 `1` 分钟，
  可以通过接口 获取默认的 `AccessToken` 刷新列表：`WeChat.Refresher.DefaultSettings.get_refresh_options_by_client/1`

  ### 方式2

      config :wechat, :refresh_settings, [{ClientA, client_setting}, ClientB, ClientC]
      # or
      config :wechat, :refresh_settings, %{ClientA => client_setting, ClientB => client_setting, ClientC => client_setting}

  `client_setting` 配置说明见：`t:client_setting/0`

  为了适应 `Storage` 在 `Refresher` 启动之后才启动，可以开启延时启动刷新:

      config :wechat, #{inspect(__MODULE__)}, wait_for_signal: true

  当所有的 `Storage` 都已经完成，可以即可通过 `#{inspect(__MODULE__)}.start_monitor/0` 方法刷新 `AccessToken`

  不配置默认为立即启动刷新
  """
  use GenServer
  require Logger
  alias WeChat.Storage.Adapter, as: StorageAdapter
  alias WeChat.{Utils, TokenChecker, Storage.Cache, Refresher.DefaultSettings}

  # 过期前 30 分钟刷新
  @refresh_before_expired 30 * 60
  # 刷新失败重试时间间隔 1 分钟
  @refresh_retry_interval 60

  @default_state %{wait_for_signal: false, components: %{}}

  @typedoc """
  在 `AccessToken` 超时前多少秒刷新，单位：秒

  如果`server_role` = `hub`, `hub server` 的值请大于 `hub client`
  """
  @type refresh_before_expired :: non_neg_integer
  @typedoc "刷新 `AccessToken` 失败的重试间隔，单位：秒"
  @type refresh_retry_interval :: non_neg_integer
  @typedoc """

  option
  - `:refresh_before_expired`: 在 `AccessToken` 超时前多少秒刷新，单位：秒，可选，
  为保证 `hub` & `hub_client` 刷新正常，请保持两者的时间一致；
  `server_role=hub_client` 时, 默认值：`#{@refresh_before_expired} + 30` 秒；
  其余角色默认值：`#{@refresh_before_expired}` 秒
  - `:refresh_retry_interval`: 刷新 `AccessToken` 失败的重试间隔，单位：秒，可选，默认值：`#{@refresh_retry_interval * 1000}` 秒
  - `:refresh_options`: 刷新 `AccessToken` 配置，可选，默认值：`WeChat.Refresher.DefaultSettings.get_refresh_options_by_client/1` 的输出结果
  """
  @type client_setting ::
          %{
            optional(:refresh_before_expired) => refresh_before_expired,
            optional(:refresh_retry_interval) => refresh_retry_interval,
            optional(:refresh_options) => DefaultSettings.refresh_options()
          }
  @type client_settings :: [WeChat.client()] | %{WeChat.client() => client_setting}
  @type state :: %{
          :wait_for_signal => boolean,
          :clients => [WeChat.client()],
          WeChat.client() => client_setting
        }

  @spec start_monitor() :: :ok
  def start_monitor do
    GenServer.call(__MODULE__, :start_monitor)
  end

  @spec add(WeChat.client(), client_setting) :: :ok
  def add(client, opts \\ %{}) do
    GenServer.call(__MODULE__, {:add, client, Map.new(opts)})
  end

  @spec append_work_agent(WeChat.client(), WeChat.Work.Agent.t()) :: :ok | :client_not_in
  def append_work_agent(client, agent) do
    GenServer.call(__MODULE__, {:append_work_agent, client, agent})
  end

  @spec remove(WeChat.client()) :: :ok | :not_found
  def remove(client) do
    GenServer.call(__MODULE__, {:remove, client})
  end

  @spec refresh(WeChat.client()) :: :ok | :not_found
  def refresh(client) do
    GenServer.call(__MODULE__, {:refresh, client})
  end

  @spec refresh(WeChat.client(), StorageAdapter.store_id(), StorageAdapter.store_key()) ::
          :ok | :not_found
  def refresh(client, store_id, store_key) do
    GenServer.call(__MODULE__, {:refresh, client, store_id, store_key})
  end

  @spec refresh_component(WeChat.component_appid(), StorageAdapter.store_key()) ::
          :ok | :not_found
  def refresh_component(component_appid, store_key) do
    GenServer.call(__MODULE__, {:refresh_component, component_appid, store_key})
  end

  @spec refresh_key(
          WeChat.client(),
          StorageAdapter.store_id(),
          StorageAdapter.store_key(),
          StorageAdapter.value(),
          expires :: integer()
        ) :: :ok
  def refresh_key(client, store_id, store_key, value, expires) do
    GenServer.cast(__MODULE__, {:refresh_key, client, store_id, store_key, value, expires})
  end

  @spec client_options(WeChat.client()) :: client_setting | nil
  def client_options(client), do: GenServer.call(__MODULE__, {:client_options, client})

  @spec clients() :: [WeChat.client()]
  def clients, do: GenServer.call(__MODULE__, :clients)

  @spec components() :: %{
          WeChat.component_appid() => %{
            keys: [StorageAdapter.store_key()],
            clients: [WeChat.client()]
          }
        }
  def components, do: GenServer.call(__MODULE__, :components)

  @spec start_link(client_settings) :: GenServer.on_start()
  def start_link(client_settings \\ %{}) do
    GenServer.start_link(__MODULE__, client_settings, name: __MODULE__)
  end

  @impl true
  def init(client_settings) do
    state =
      Map.new(client_settings, fn
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
      @default_state
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
    state = Enum.reduce(state.clients, state, &start_monitor_client/2)
    {:noreply, %{state | wait_for_signal: false}}
  end

  @impl true
  def handle_call(:start_monitor, _from, state) do
    {:reply, :ok, state, {:continue, :start_monitor}}
  end

  def handle_call({:add, client, options}, _from, state) do
    state =
      if client in state.clients do
        remove_client(state, client)
      else
        state
      end
      |> add_client(client, options)

    {:reply, :ok, state}
  end

  def handle_call({:append_work_agent, client, agent}, _from, state) do
    if client in state.clients do
      state = append_client_agent(state, client, agent)
      {:reply, :ok, state}
    else
      {:reply, :client_not_in, state}
    end
  end

  def handle_call({:remove, client}, _from, state) do
    if client in state.clients do
      state = remove_client(state, client)
      {:reply, :ok, state}
    else
      {:reply, :not_found, state}
    end
  end

  def handle_call({:refresh, client}, _from, state) do
    with opts when is_map(opts) <- Map.get(state, client) do
      opts = do_refresh(client, opts)
      state = Map.put(state, client, opts)
      {:reply, :ok, state}
    else
      _ ->
        {:reply, :not_found, state}
    end
  end

  def handle_call({:refresh, client, store_id, store_key}, _from, state) do
    with opts when is_map(opts) <- Map.get(state, client) do
      opts = do_refresh(client, store_id, store_key, opts)
      state = Map.put(state, client, opts)
      {:reply, :ok, state}
    else
      _ ->
        {:reply, :not_found, state}
    end
  end

  def handle_call({:refresh_component, component_appid, store_key}, _from, state) do
    with component when is_map(component) <- Map.get(state.components, component_appid),
         true <- store_key in component.keys do
      client =
        Enum.find(component.clients, fn c ->
          Map.get(state, c)
          |> Map.get(:refresh_options)
          |> Enum.find(&match?({{^component_appid, ^store_key}, _, _}, &1))
        end)

      opts = do_refresh(client, component_appid, store_key, state[client])
      state = Map.put(state, client, opts)
      {:reply, :ok, state}
    else
      _ -> {:reply, :not_found, state}
    end
  end

  def handle_call({:client_options, client}, _from, state) do
    {:reply, Map.get(state, client), state}
  end

  def handle_call(:clients, _from, state) do
    {:reply, state.clients, state}
  end

  def handle_call(:components, _from, state) do
    {:reply, state.components, state}
  end

  @impl true
  def handle_cast({:refresh_key, client, store_id, store_key, value, expires}, state) do
    cache_and_store(store_id, store_key, value, expires, client)
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

  defp cache_and_store(store_id, store_key, value, expires, client) do
    store_map = %{"value" => value, "expired_time" => expires}
    Cache.put_cache(store_id, store_key, value)
    Cache.put_cache({:store_map, store_id}, store_key, store_map)

    with storage when storage != nil <- client.storage(),
         # 因为 hub_client 是从 storage 中读取 token 的，因此不需要再做写入操作
         true <- client.server_role() != :hub_client do
      result = storage.store(store_id, store_key, store_map)

      Logger.info(
        "Call #{inspect(storage)}.restore(#{store_id}, #{store_key}) => #{inspect(result)}."
      )
    end
  end

  defp restore_and_cache(store_id, store_key, client) do
    with storage when storage != nil <- client.storage(),
         {:ok, %{"value" => value, "expired_time" => expires} = store_map} <-
           storage.restore(store_id, store_key) do
      diff = expires - Utils.now_unix()

      if diff > 0 do
        Cache.put_cache(store_id, store_key, value)
        Cache.put_cache({:store_map, store_id}, store_key, store_map)

        Logger.info(
          "Call #{inspect(storage)}.restore(#{store_id}, #{store_key}) succeed, the expires_in is: #{diff}s."
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
          "Call #{inspect(client.storage())}.restore(#{store_id}, #{store_key}) failed, return error: #{inspect(error)}."
        )

        false
    end
  end

  defp init_client_options(client, options) do
    Logger.info(
      "Initialize WeChat Client: #{inspect(client)} by AppType: #{client.app_type()}, Storage: #{inspect(client.storage())}."
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

  defp start_monitor_client(client, state) do
    Logger.info("Monitoring WeChat Client: #{inspect(client)}.")
    options = Map.get(state, client)
    {refresh_options, state} = filter_duplicate_component(client, options.refresh_options, state)
    refresh_options = start_refresh_timers(client, options, refresh_options)
    options = %{options | refresh_options: refresh_options}
    TokenChecker.maybe_add_client(client, refresh_options)
    Map.put(state, client, options)
  end

  defp filter_duplicate_component(client, refresh_options, state) do
    if client.by_component?() do
      component_appid = client.component_appid()

      {refresh_options, components} =
        Enum.reduce(refresh_options, {[], state.components}, fn
          {{^component_appid, _store_key}, _fun, _timer} = option, {acc, components} ->
            update_component(option, client, acc, components)

          record, {acc, components} ->
            {[record | acc], components}
        end)

      {Enum.reverse(refresh_options), %{state | components: components}}
    else
      {refresh_options, state}
    end
  end

  defp update_component(
         option = {{component_appid, store_key}, _fun, _timer},
         client,
         refresh_options,
         components
       ) do
    {refresh_options, component} =
      if component = Map.get(components, component_appid) do
        if store_key in component.keys do
          Logger.info(
            "Ignore refresh_option: #{inspect(option)} for #{inspect(client)}, because duplicated."
          )

          {refresh_options,
           %{component | clients: Utils.uniq_and_sort([client | component.clients])}}
        else
          {[option | refresh_options],
           %{
             component
             | keys: Utils.uniq_and_sort([store_key | component.keys]),
               clients: Utils.uniq_and_sort([client | component.clients])
           }}
        end
      else
        {[option | refresh_options], %{keys: [store_key], clients: [client]}}
      end

    {refresh_options, Map.put(components, component_appid, component)}
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

  defp do_refresh(client, store_id, store_key, %{refresh_options: refresh_options} = opts) do
    Logger.info(
      "Refreshing WeChat Client: #{inspect(client)} with list: #{inspect(refresh_options)}."
    )

    refresh_options =
      for {{id, key}, fun, timer} = option <- refresh_options do
        case {id, key} do
          {^store_id, ^store_key} ->
            cancel_timer(timer)
            timer = refresh_token(store_id, store_key, fun, client, opts)
            {{store_id, store_key}, fun, timer}

          _ ->
            option
        end
      end

    %{opts | refresh_options: refresh_options}
  end

  defp cancel_timer(nil), do: :ignore
  defp cancel_timer(timer), do: :erlang.cancel_timer(timer)

  defp refresh_token(store_id, store_key, fun, client, options) do
    case fun.(client) do
      {:ok, list, expires_in} when is_list(list) ->
        now = Utils.now_unix()

        Enum.each(list, fn {key, token, expires_in} ->
          expires = now + expires_in
          cache_and_store(store_id, key, token, expires, client)
        end)

        Logger.info(
          "Refresh appid: #{store_id}, key: #{store_key} succeed, get expires_in: #{expires_in}s."
        )

        ((expires_in - options.refresh_before_expired) * 1000)
        |> max(options.refresh_retry_interval)

      {:ok, token, expires_in} ->
        expires = Utils.now_unix() + expires_in
        cache_and_store(store_id, store_key, token, expires, client)

        Logger.info(
          "Refresh appid: #{store_id}, key: #{store_key} succeed, get expires_in: #{expires_in}s."
        )

        ((expires_in - options.refresh_before_expired) * 1000)
        |> max(options.refresh_retry_interval)

      error ->
        refresh_retry_interval = options.refresh_retry_interval

        Logger.warn(
          "Refresh appid: #{store_id}, key: #{store_key} failed, return error: #{inspect(error)}, Will be retry again #{refresh_retry_interval}s later."
        )

        refresh_retry_interval
    end
    |> start_refresh_token_timer(store_id, store_key, client)
  end

  defp start_refresh_timers(client, options, refresh_options) do
    for {{store_id, store_key}, fun, _timer} <- refresh_options do
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
          DefaultSettings.get_refresh_options_by_client(client)
      end

    for {store_id, store_key, fun} <- refresh_options do
      {{store_id, store_key}, fun, nil}
    end
  end

  defp add_client(state, client, options) do
    options = init_client_options(client, options)

    state =
      state
      |> Map.put(client, options)
      |> Map.put(:clients, [client | state.clients])

    if state.wait_for_signal do
      state
    else
      start_monitor_client(client, state)
    end
  end

  defp remove_client(state, client) do
    Logger.info("Removing WeChat Client: #{inspect(client)}.")
    {get, state} = Map.pop(state, client)
    clients = List.delete(state.clients, client)

    with {_client, opts} <- get do
      Enum.each(opts.refresh_options, fn {_key, _fun, timer} ->
        cancel_timer(timer)
      end)
    end

    %{state | clients: clients}
  end

  defp append_client_agent(state, client, agent) do
    options = Map.fetch!(state, client)
    Cache.set_work_agent(client, agent)

    refresh_options =
      DefaultSettings.work_refresh_options(client, agent)
      |> Enum.map(fn {store_id, store_key, fun} ->
        {{store_id, store_key}, fun, nil}
      end)

    if state.wait_for_signal do
      Map.put(options, :refresh_options, options.refresh_options ++ refresh_options)
      |> then(&Map.put(state, client, &1))
    else
      Logger.info("Monitoring WeChat work agent: #{agent.name} for Client: #{inspect(client)}.")
      refresh_options = start_refresh_timers(client, options, refresh_options)
      TokenChecker.maybe_add_client(client, refresh_options)

      Map.put(options, :refresh_options, options.refresh_options ++ refresh_options)
      |> then(&Map.put(state, client, &1))
    end
  end
end
