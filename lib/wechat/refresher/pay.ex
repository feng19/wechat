defmodule WeChat.Refresher.Pay do
  @moduledoc """
  微信支付 - 刷新器

  每 12 小时检查 更新证书

  [下载平台证书](https://pay.weixin.qq.com/docs/merchant/apis/platform-certificate/api-v3-get-certificates/get.html)
  """
  use GenServer
  require Logger
  alias WeChat.Pay.Certificates

  def start_link(settings = %{client: client}) when is_map(settings) do
    GenServer.start_link(__MODULE__, settings, name: name(client))
  end

  defp name(client), do: :"#{client}.Refresher"

  @impl true
  def init(settings = %{client: client}) do
    make_sure_certs(client)
    settings = Map.merge(%{update_interval: 43200, retry_interval: 60}, settings)

    time_settings =
      Map.take(settings, [:update_interval, :retry_interval])
      |> Map.new(fn {k, v} -> {k, v * 1000} end)

    timer = start_update_timer(time_settings.update_interval, client)
    state = Map.merge(%{client: client, settings: settings, timer: timer}, time_settings)
    {:ok, state}
  end

  @impl true
  def handle_info({:timeout, _timer, :update_certs}, %{client: client} = state) do
    storage = client.storage()
    mch_id = client.mch_id()

    timer =
      case storage.restore(mch_id, :certs) do
        {:ok, old_certs} ->
          download_certificates(old_certs, state)

        # 无记录
        {:error, :enoent} ->
          download_certificates([], state)

        error ->
          Logger.warning(
            "Update certs failed! Call #{inspect(storage)}.restore(#{mch_id}, :certs) error: #{inspect(error)}, will be retry again #{state.retry_interval}ms later."
          )

          state.retry_interval
      end
      |> start_update_timer(client)

    {:noreply, %{state | timer: timer}}
  end

  defp start_update_timer(time, client) do
    Logger.info("Start Update Certs Timer for #{inspect(client)}, time: #{time}s.")
    :erlang.start_timer(time, self(), :update_certs)
  end

  defp download_certificates(old_certs, %{
         client: client,
         update_interval: update_interval,
         retry_interval: retry_interval
       }) do
    case Certificates.certificates(client) do
      {:ok, new_certs} when is_list(new_certs) ->
        with {:ok, certs} <- Certificates.merge_certs(new_certs, old_certs, client) do
          storage = client.storage()
          mch_id = client.mch_id()
          result = storage.store(mch_id, :certs, certs)

          Logger.info(
            "Call #{inspect(storage)}.store(#{mch_id}, :certs, #{inspect(certs)}) => #{inspect(result)}."
          )
        end

        update_interval

      error ->
        Logger.warning(
          "Refresh certificates error: #{inspect(error)}, will be retry again #{retry_interval}ms later."
        )

        retry_interval
    end
  end

  defp make_sure_certs(client) do
    storage = client.storage()
    mch_id = client.mch_id()
    # Load certs From Storage
    case storage.restore(mch_id, :certs) do
      {:ok, certs} -> Certificates.put_certs(certs, client)
      _error -> WeChat.Pay.init_certs(client)
    end
  end
end
