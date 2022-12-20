defmodule WeChat.TokenChecker do
  @moduledoc """
  Token 检查器

  定期（默认为每 5 分钟检查一次）检查 access_token，如果发现失效，则自动刷新

  按以下方式配置，将自动给对应的 client 增加检查

      config :wechat, :check_token_for_clients, [ClientA, ClientB, ClientC]

  """

  use GenServer
  require Logger

  @type check_fun :: (() -> WeChat.response())
  @type refresh_fun :: (() -> any)
  @typep id :: WeChat.Storage.Adapter.store_id()
  @typep refresh_options :: WeChat.Refresher.DefaultSettings.refresh_options()

  @default_settings %{
    # 5 minutes
    check_interval: 5 * 60,
    checks: %{}
  }

  @spec maybe_add_client(WeChat.client(), refresh_options) :: :ok
  def maybe_add_client(client, refresh_options) do
    if client in Application.get_env(:wechat, :check_token_for_clients, []) do
      add_client(client, refresh_options)
    end
  end

  @spec add_client(WeChat.client()) :: :ok | nil
  def add_client(client) do
    refresher = WeChat.refresher()

    with %{refresh_options: refresh_options} <- refresher.client_options(client) do
      add_client(client, refresh_options)
    end
  end

  @spec add_client(WeChat.client(), refresh_options) :: :ok
  def add_client(client, refresh_options) do
    refresher = WeChat.refresher()

    Enum.each(refresh_options, fn {{id, key}, _fun, _ref} ->
      case key do
        :access_token ->
          check_fun = fn ->
            WeChat.Account.get_quota(client, "/cgi-bin/openapi/quota/get")
          end

          refresh_fun = fn -> refresher.refresh(client, id, key) end
          add(id, check_fun, refresh_fun)

        :component_access_token ->
          check_fun = fn ->
            WeChat.Component.get_quota(client, "/cgi-bin/openapi/quota/get")
          end

          refresh_fun = fn -> refresher.refresh_component(id, key) end
          add(id, check_fun, refresh_fun)

        _ ->
          :ignore
      end
    end)
  end

  @spec add(id, check_fun, refresh_fun) :: :ok
  def add(id, check_fun, refresh_fun) do
    GenServer.call(__MODULE__, {:add, id, check_fun, refresh_fun})
  end

  @spec remove(id) :: :ok
  def remove(id) do
    GenServer.call(__MODULE__, {:remove, id})
  end

  @spec ids() :: [id]
  def ids do
    GenServer.call(__MODULE__, :ids)
  end

  @spec start_link(settings :: map) :: GenServer.on_start()
  def start_link(settings \\ %{}) do
    GenServer.start_link(__MODULE__, settings, name: __MODULE__)
  end

  @impl true
  def init(settings) do
    state = Map.merge(@default_settings, settings || %{})
    :timer.send_interval(state.check_interval * 1000, :check)
    {:ok, state}
  end

  @impl true
  def handle_info(:check, state) do
    for {id, opts} <- state.checks do
      check_token(id, opts)
    end

    {:noreply, state}
  end

  @impl true
  def handle_call({:add, id, check_fun, refresh_fun}, _from, state) do
    checks = Map.put(state.checks, id, %{check_fun: check_fun, refresh_fun: refresh_fun})
    {:reply, :ok, %{state | checks: checks}}
  end

  def handle_call({:remove, id}, _from, state) do
    checks = Map.delete(state.checks, id)
    {:reply, :ok, %{state | checks: checks}}
  end

  def handle_call(:ids, _from, state) do
    {:reply, Map.keys(state.checks), state}
  end

  defp check_token(id, %{check_fun: check_fun, refresh_fun: refresh_fun}) do
    with {:ok, %{status: 200, body: %{"errcode" => code}}} <- check_fun.(),
         true <- code in [40001, 42001] do
      Logger.info("TokenChecker found the token of #{inspect(id)} already expired, go refresh.")
      refresh_fun.()
    end
  rescue
    reason ->
      error_msg = Exception.format(:error, reason, __STACKTRACE__)
      Logger.error(error_msg)
      {:error, error_msg}
  catch
    error, reason ->
      error_msg = Exception.format(error, reason, __STACKTRACE__)
      Logger.error(error_msg)
      {:error, error_msg}
  end
end
