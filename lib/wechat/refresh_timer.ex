defmodule WeChat.RefreshTimer do
  @moduledoc false
  use GenServer
  require Logger

  def add(role, client) do
    GenServer.call(__MODULE__, {:add, role, client})
  end

  def start_link(state \\ %{}) do
    GenServer.start_link(__MODULE__, state, name: __MODULE__)
  end

  @impl true
  def init(state) do
    {:ok, state}
  end

  @impl true
  def handle_call({:add, :common, client}, _from, state) do
    refresh_access_token(client)
    refresh_js_api_ticket(client)
    refresh_wx_card_ticket(client)
    {:reply, :ok, state}
  end

  @impl true
  def handle_cast(_msg, state) do
    {:noreply, state}
  end

  @impl true
  def handle_info({:timeout, _timer, {:access_token, client}}, state) do
    refresh_access_token(client)
    {:noreply, state}
  end

  def handle_info({:timeout, _timer, {:js_api_ticket, client}}, state) do
    refresh_js_api_ticket(client)
    {:noreply, state}
  end

  def handle_info({:timeout, _timer, {:wx_card_ticket, client}}, state) do
    refresh_wx_card_ticket(client)
    {:noreply, state}
  end

  defp refresh_access_token(client) do
    case WeChat.Account.get_access_token(client) do
      {:ok, %{status: 200, body: data}} ->
        access_token = data["access_token"]
        WeChat.put_cache(client.appid(), :access_token, access_token)
        Logger.info("#{__MODULE__} get_access_token succeed")

        ((data["expires_in"] - 10 * 60) * 1000)
        |> :erlang.start_timer(self(), {:access_token, client})

      error ->
        Logger.warn(
          "#{__MODULE__} get_access_token error:" <>
            inspect(error) <> ", try again one minute later"
        )

        :erlang.start_timer(60_000, self(), {:access_token, client})
    end
  end

  defp refresh_js_api_ticket(client) do
    case WeChat.JS.get_ticket(client, "jsapi") do
      {:ok, %{status: 200, body: data}} ->
        ticket = data["ticket"]
        WeChat.put_cache(client.appid(), :js_api_ticket, ticket)
        Logger.info("#{__MODULE__} get_js_api_ticket succeed")

        ((data["expires_in"] - 10 * 60) * 1000)
        |> :erlang.start_timer(self(), {:js_api_ticket, client})

      error ->
        Logger.warn(
          "#{__MODULE__} get_js_api_ticket error:" <>
            inspect(error) <> ", try again one minute later"
        )

        :erlang.start_timer(60_000, self(), {:js_api_ticket, client})
    end
  end

  defp refresh_wx_card_ticket(client) do
    case WeChat.JS.get_ticket(client, "wx_card") do
      {:ok, %{status: 200, body: data}} ->
        ticket = data["ticket"]
        WeChat.put_cache(client.appid(), :wx_card_ticket, ticket)

        Logger.info("#{__MODULE__} get_wx_card_ticket succeed")

        ((data["expires_in"] - 10 * 60) * 1000)
        |> :erlang.start_timer(self(), {:wx_card_ticket, client})

      error ->
        Logger.warn(
          "#{__MODULE__} get_wx_card_ticket error:" <>
            inspect(error) <> ", try again one minute later"
        )

        :erlang.start_timer(60_000, self(), {:wx_card_ticket, client})
    end
  end
end
