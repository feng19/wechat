defmodule WeChat.RefreshTimer do
  @moduledoc false
  use GenServer
  require Logger
  alias WeChat.Utils

  @default_opts %{role: :common, store_adapter: WeChat.StoreAdapter.Default}

  @spec add(client :: WeChat.client(), opts :: map()) :: :ok
  def add(client, opts) do
    GenServer.call(__MODULE__, {:add, client, opts})
  end

  @spec refresh(client :: WeChat.client()) :: :ok | :nofound
  def refresh(client) do
    GenServer.call(__MODULE__, {:refresh, client})
  end

  def start_link(state \\ %{}) do
    GenServer.start_link(__MODULE__, state, name: __MODULE__)
  end

  @impl true
  def init(state) do
    state =
      Map.new(state, fn {client, opts} ->
        opts = Map.merge(@default_opts, opts)
        do_add(client, opts)
        {client, opts}
      end)

    {:ok, state}
  end

  @impl true
  def handle_call({:add, client, opts}, _from, state) do
    opts = Map.merge(@default_opts, opts)
    do_add(client, opts)
    state = Map.put(state, client, opts)
    {:reply, :ok, state}
  end

  def handle_call({:refresh, client}, _from, state) do
    with opts when is_map(opts) <- Map.get(state, client) do
      do_refresh(client, opts)
      {:reply, :ok, state}
    else
      _ ->
        {:reply, :nofound, state}
    end
  end

  @impl true
  def handle_cast(_msg, state) do
    {:noreply, state}
  end

  @impl true
  def handle_info({:timeout, _timer, {:access_token, client}}, state) do
    opts = Map.get(state, client)
    refresh_access_token(:access_token, client, opts.store_adapter)
    {:noreply, state}
  end

  def handle_info({:timeout, _timer, {:js_api_ticket, client}}, state) do
    opts = Map.get(state, client)
    refresh_ticket("jsapi", :js_api_ticket, client, opts.store_adapter)
    {:noreply, state}
  end

  def handle_info({:timeout, _timer, {:wx_card_ticket, client}}, state) do
    opts = Map.get(state, client)
    refresh_ticket("wx_card", :wx_card_ticket, client, opts.store_adapter)
    {:noreply, state}
  end

  defp do_add(client, %{role: :common, store_adapter: store_adapter}) do
    Logger.info("Initialize WeChat App: #{client} by Role: common.")

    [
      access_token: &refresh_access_token/3,
      js_api_ticket: &refresh_ticket("jsapi", &1, &2, &3),
      wx_card_ticket: &refresh_ticket("wx_card", &1, &2, &3)
    ]
    |> Enum.map(fn {store_key, fun} ->
      case get_from_store(store_key, client, store_adapter) do
        false ->
          fun.(store_key, client, store_adapter)

        {true, expires_in} ->
          # 过期前10分钟刷新
          (max(expires_in, expires_in - 10 * 60) * 1000)
          |> :erlang.start_timer(self(), {store_key, client})
      end
    end)
  end

  defp do_refresh(client, %{role: :common, store_adapter: store_adapter}) do
    Logger.info("Refreshing WeChat App: #{client} by Role: common.")
    refresh_access_token(:access_token, client, store_adapter)
    refresh_ticket("jsapi", :js_api_ticket, client, store_adapter)
    refresh_ticket("wx_card", :wx_card_ticket, client, store_adapter)
  end

  defp refresh_access_token(store_key, client, store_adapter) do
    with {:ok, %{status: 200, body: data}} <- WeChat.Account.get_access_token(client),
         %{"access_token" => access_token, "expires_in" => expires_in} <- data do
      expired_time = Utils.now_unix() + expires_in
      store(store_key, access_token, expired_time, client, store_adapter)
      Logger.info("#{__MODULE__} Get #{client}-#{store_key} succeed.")

      :erlang.start_timer((expires_in - 10 * 60) * 1000, self(), {store_key, client})
    else
      error ->
        Logger.warn(
          "#{__MODULE__} Get #{client}-#{store_key} error:" <>
            inspect(error) <> ", try again one minute later."
        )

        :erlang.start_timer(60_000, self(), {store_key, client})
    end
  end

  defp refresh_ticket(ticket_type, store_key, client, store_adapter) do
    with {:ok, %{status: 200, body: data}} <- WeChat.JS.get_ticket(client, ticket_type),
         %{"ticket" => ticket, "expires_in" => expires_in} <- data do
      expired_time = Utils.now_unix() + expires_in
      store(store_key, ticket, expired_time, client, store_adapter)
      Logger.info("#{__MODULE__} Get #{client}-#{store_key} succeed.")

      :erlang.start_timer((expires_in - 10 * 60) * 1000, self(), {store_key, client})
    else
      error ->
        Logger.warn(
          "#{__MODULE__} Get #{client}-#{store_key} error:" <>
            inspect(error) <> ", try again one minute later."
        )

        :erlang.start_timer(60_000, self(), {store_key, client})
    end
  end

  def store(store_key, value, expired_time, client, store_adapter) do
    appid = client.appid()
    WeChat.put_cache(appid, store_key, value)

    if store_adapter != nil do
      result =
        store_adapter.store(appid, store_key, %{"value" => value, "expired_time" => expired_time})

      Logger.info("#{__MODULE__} Store #{client}-#{store_key} result: #{result}.")
    end
  end

  def get_from_store(store_key, client, store_adapter) do
    with true <- store_adapter != nil,
         appid <- client.appid(),
         {:ok, %{"value" => value, "expired_time" => expired_time}} <-
           store_adapter.get(appid, store_key) do
      diff = expired_time - Utils.now_unix()

      if diff > 0 do
        WeChat.put_cache(appid, store_key, value)
        Logger.info("#{__MODULE__} Get #{client}-#{store_key}-#{diff} from store succeed.")
        {true, diff}
      else
        Logger.info("#{__MODULE__} Get #{client}-#{store_key} token expired.")
        false
      end
    else
      error ->
        Logger.warn("#{__MODULE__} Get #{client}-#{store_key} error: #{inspect(error)}.")
        false
    end
  end
end
