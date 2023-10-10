defmodule WeChat.Refresher.Pay do
  @moduledoc """
  微信支付 - 刷新器

  每天检查更新证书
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
    settings = Map.merge(%{update_interval: 86_400, retry_interval: 60}, settings)

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

  # [%{
  #   "serial_no" => serial_no,
  #   "effective_timestamp" => effective_time,
  #   "expire_timestamp" => expire_time,
  #   "certificate" => certificate
  # }]
  defp merge_cacerts(new_certs, old_certs, client) do
    now = WeChat.Utils.now_unix()
    old_certs = remove_expired_cert(old_certs, client, now)
    old_serial_no_list = Enum.map(old_certs, & &1["serial_no"])

    new_certs
    |> Enum.filter(&(&1["serial_no"] not in old_serial_no_list))
    |> case do
      [] ->
        false

      new_certs ->
        for cert <- new_certs do
          Certificates.put_cert(client, cert["serial_no"], cert["certificate"])
        end

        serial_no = get_latest_effective_serial_no(new_certs, now)
        {serial_no, new_certs ++ old_certs}
    end
  end

  defp get_latest_effective_serial_no(certs, now) do
    Enum.sort_by(certs, fn cert ->
      if cert["effective_timestamp"] < now and now < cert["expire_timestamp"] do
        -cert["expire_timestamp"]
      else
        0
      end
    end)
  end

  defp remove_expired_cert(certs, client, now) do
    Enum.reject(certs, fn cert ->
      if now >= cert["expire_timestamp"] do
        Certificates.remove_cert(client, cert["serial_no"])
        true
      else
        false
      end
    end)
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
        with {serial_no, cacerts} <- merge_cacerts(new_certs, old_certs, client) do
          result = storage.store(mch_id, :cacerts, cacerts)

          Logger.info(
            "Call #{inspect(storage)}.store(#{mch_id}, :cacerts, #{inspect(cacerts)}) => #{inspect(result)}."
          )

          cacerts = Enum.map(cacerts, & &1["certificate"])
          WeChat.Pay.start_next_requester(client, serial_no: serial_no, cacerts: cacerts)
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
