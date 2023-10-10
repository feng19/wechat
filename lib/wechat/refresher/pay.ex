defmodule WeChat.Refresher.Pay do
  @moduledoc """
  微信支付 - 刷新器

  每 12 小时检查 更新证书

  [下载平台证书](https://pay.weixin.qq.com/docs/merchant/apis/platform-certificate/api-v3-get-certificates/get.html)
  """
  use GenServer
  require Logger
  alias WeChat.Pay.Certificates

  def start_link(client, settings \\ %{}) do
    GenServer.start_link(__MODULE__, {client, settings}, name: name(client))
  end

  defp name(client), do: :"#{client}.Refresher"

  @impl true
  def init({client, settings}) do
    settings = Map.new(settings)
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
      case storage.restore(mch_id, :cacerts) do
        {:ok, old_certs} ->
          download_certificates(old_certs, state)

        # 无记录
        {:error, :enoent} ->
          download_certificates([], state)

        error ->
          Logger.warning(
            "Update certs failed! Call #{inspect(storage)}.restore(#{mch_id}, :cacerts) error: #{inspect(error)}, will be retry again #{state.retry_interval}ms later."
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
    storage = client.storage()
    mch_id = client.mch_id()

    case Certificates.certificates(client) do
      {:ok, new_certs} when is_list(new_certs) ->
        with {:ok, cacerts} <- Certificates.merge_cacerts(new_certs, old_certs, client) do
          result = storage.store(mch_id, :cacerts, cacerts)

          Logger.info(
            "Call #{inspect(storage)}.store(#{mch_id}, :cacerts, #{inspect(cacerts)}) => #{inspect(result)}."
          )

          WeChat.Pay.start_next_requester(client, cacerts: cacerts)
        end

        update_interval

      error ->
        Logger.warning(
          "Refresh certificates error: #{inspect(error)}, will be retry again #{retry_interval}ms later."
        )

        retry_interval
    end
  end
end
