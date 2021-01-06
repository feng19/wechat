defmodule WeChat.RefreshTimer do
  @moduledoc false
  use GenServer
  require Logger
  alias WeChat.Storage.Adapter, as: StorageAdapter
  alias WeChat.{Utils, Storage.Cache}

  @type opts :: map()
  # 过期前30分钟刷新
  @refresh_before_time 30 * 60
  # 刷新失败重试时间间隔 1分钟
  @refresh_retry_interval 60_000

  @spec add(WeChat.client(), opts()) :: :ok
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

  @spec start_link(state :: %{WeChat.client() => opts()}) :: GenServer.on_start()
  def start_link(state \\ %{}) do
    GenServer.start_link(__MODULE__, state, name: __MODULE__)
  end

  @impl true
  def init(state) do
    Cache.init_table()

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
      Enum.each(opts.refresh_list, fn {_key, _fun, timer} ->
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
  def handle_info({:timeout, _timer, {store_id, store_key, client}}, state) do
    case Map.get(state, client) do
      opts when opts != nil ->
        key = {store_id, store_key}
        {{_key, fun, _timer}, refresh_list} = List.keytake(opts.refresh_list, key, 0)
        timer = refresh_token(store_id, store_key, fun, client, opts)
        state = Map.put(state, client, %{opts | refresh_list: [{key, fun, timer} | refresh_list]})
        {:noreply, state}

      _ ->
        {:noreply, state}
    end
  end

  def cache_and_store(store_id, store_key, value, expired_time, client) do
    Cache.put_cache(store_id, store_key, value)

    storage = client.storage()

    if storage do
      result =
        storage.store(store_id, store_key, %{"value" => value, "expired_time" => expired_time})

      Logger.info("Store [#{store_id}] [#{store_key}] by #{storage} => #{result}.")
    end
  end

  def restore_and_cache(store_id, store_key, client) do
    storage = client.storage()

    with true <- storage != nil,
         {:ok, %{"value" => value, "expired_time" => expired_time}} <-
           storage.restore(store_id, store_key) do
      diff = expired_time - Utils.now_unix()

      if diff > 0 do
        Cache.put_cache(store_id, store_key, value)

        Logger.info(
          "Get [#{store_id}] [#{store_key}] [expires_in: #{diff}] from storage: #{storage} succeed."
        )

        {true, diff}
      else
        Logger.info("Get [#{store_id}] [#{store_key}] from storage: #{storage} token expired.")
        false
      end
    else
      false ->
        false

      error ->
        Logger.warn(
          "Get [#{store_id}] [#{store_key}] from storage: #{storage} error: #{inspect(error)}."
        )

        false
    end
  end

  defp do_add(client, opts) do
    opts =
      Map.merge(opts, %{
        refresh_before_time: Map.get(opts, :refresh_before_time, @refresh_before_time),
        refresh_retry_interval: Map.get(opts, :refresh_retry_interval, @refresh_retry_interval)
      })

    Cache.set_client(client)

    refresh_list = init_refresh_list(client, opts)

    Logger.info(
      "Initialize WeChat App: #{client} by Role: #{client.role()}, Storage: #{client.storage()}."
    )

    refresh_list =
      for {id_type, store_key, fun} <- refresh_list do
        store_id = get_store_id_by_id_type(id_type, client)

        timer =
          case restore_and_cache(store_id, store_key, client) do
            false ->
              refresh_token(store_id, store_key, fun, client, opts)

            {true, expires_in} ->
              (max(0, expires_in - opts.refresh_before_time) * 1000)
              |> :erlang.start_timer(self(), {store_id, store_key, client})
          end

        {{store_id, store_key}, fun, timer}
      end

    Map.put(opts, :refresh_list, refresh_list)
  end

  defp do_refresh(client, %{refresh_list: refresh_list} = opts) do
    Logger.info("Refreshing WeChat App: #{client}, list: #{inspect(refresh_list)}.")

    refresh_list =
      for {{store_id, store_key}, fun, timer} <- refresh_list do
        :erlang.cancel_timer(timer)
        timer = refresh_token(store_id, store_key, fun, client, opts)
        {{store_id, store_key}, fun, timer}
      end

    %{opts | refresh_list: refresh_list}
  end

  @compile {:inline, get_store_id_by_id_type: 2}
  def get_store_id_by_id_type(:appid, client), do: client.appid()
  def get_store_id_by_id_type(:component_appid, client), do: client.component_appid()

  defp refresh_token(store_id, store_key, fun, client, opts) do
    case fun.(client) do
      {:ok, list, expires_in} when is_list(list) ->
        now = Utils.now_unix()

        Enum.each(list, fn {key, token, expires_in} ->
          expired_time = now + expires_in
          cache_and_store(store_id, key, token, expired_time, client)
        end)

        Logger.info("Refresh [#{store_id}] [#{store_key}] [expires_in: #{expires_in}] succeed.")

        :erlang.start_timer(
          (expires_in - opts.refresh_before_time) * 1000,
          self(),
          {store_id, store_key, client}
        )

      {:ok, token, expires_in} ->
        expired_time = Utils.now_unix() + expires_in
        cache_and_store(store_id, store_key, token, expired_time, client)
        Logger.info("Refresh [#{store_id}] [#{store_key}] [expires_in: #{expires_in}] succeed.")

        :erlang.start_timer(
          (expires_in - opts.refresh_before_time) * 1000,
          self(),
          {store_id, store_key, client}
        )

      error ->
        Logger.warn(
          "Refresh [#{store_id}] [#{store_key}] error:" <>
            inspect(error) <> ", Will be retry again one minute later."
        )

        :erlang.start_timer(opts.refresh_retry_interval, self(), {store_id, store_key, client})
    end
  end

  defp init_refresh_list(client, opts) do
    case Map.get(opts, :refresh_list) do
      fun when is_function(fun, 0) ->
        fun.()

      fun when is_function(fun, 1) ->
        fun.(client)

      refresh_list when is_list(refresh_list) ->
        refresh_list

      nil ->
        WeChat.RefreshHelper.get_refresh_list_by_client(client)
    end
  end
end
