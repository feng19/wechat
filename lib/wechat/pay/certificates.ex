defmodule WeChat.Pay.Certificates do
  import WeChat.Utils, only: [pay_doc_link_prefix: 0]

  @moduledoc """
  微信支付 - 平台证书

  - [平台证书简介](#{pay_doc_link_prefix()}/merchant/development/interface-rules/wechatpay-certificates.html){:target="_blank"}
  - [平台证书更新指引](#{pay_doc_link_prefix()}/merchant/development/interface-rules/wechatpay-certificates-rotation.html){:target="_blank"}
  - [证书相关问题](#{pay_doc_link_prefix()}/merchant/development/interface-rules/certificate-faqs.html){:target="_blank"}
  """
  alias WeChat.Pay
  alias WeChat.Pay.Crypto

  @doc """
  下载平台证书 -
  [官方文档](#{pay_doc_link_prefix()}/merchant/apis/platform-certificate/api-v3-get-certificates/get.html){:target="_blank"}
  """
  def certificates(client, first? \\ false)

  def certificates(client, false) do
    with {:ok, %{body: %{"data" => certificates}}} when is_list(certificates) <-
           client.get("/v3/certificates") do
      api_secret_key = client.api_secret_key()
      {:ok, Enum.map(certificates, &Crypto.decrypt_certificate(&1, api_secret_key))}
    end
  end

  def certificates(client, true) do
    with {:ok, %{body: %{"data" => certificates}}} when is_list(certificates) <-
           WeChat.Requester.Pay.first_time_download_certificates_client(client)
           |> Tesla.get("/v3/certificates", []) do
      api_secret_key = client.api_secret_key()
      {:ok, Enum.map(certificates, &Crypto.decrypt_certificate(&1, api_secret_key))}
    end
  end

  @doc false
  def put_certs(certs, client) do
    for cert <- certs do
      put_cert(client, cert["serial_no"], cert["certificate"])
    end
  end

  @doc "保存平台证书 serial_no => cert 的对应关系"
  @spec put_cert(Pay.client(), Pay.platform_serial_no(), cert :: binary()) :: :ok
  def put_cert(client, serial_no, cert) do
    public_key = cert |> X509.Certificate.from_pem!() |> X509.Certificate.public_key()
    :persistent_term.put({:wechat, {client, serial_no}}, public_key)
  end

  @doc "获取 serial_no 对应的 平台证书"
  @spec get_cert(Pay.client(), Pay.platform_serial_no()) :: X509.PublicKey.t()
  def get_cert(client, serial_no) do
    :persistent_term.get({:wechat, {client, serial_no}}, nil)
  end

  @doc "移除 serial_no 对应的 平台证书"
  @spec remove_cert(Pay.client(), Pay.platform_serial_no()) :: boolean
  def remove_cert(client, serial_no) do
    :persistent_term.erase({:wechat, {client, serial_no}})
  end

  # [%{
  #   "serial_no" => serial_no,
  #   "effective_timestamp" => effective_time,
  #   "expire_timestamp" => expire_time,
  #   "certificate" => certificate
  # }]
  @doc false
  def merge_cacerts(new_certs, [], client) do
    put_certs(new_certs, client)
    {:ok, new_certs}
  end

  def merge_cacerts(new_certs, old_certs, client) do
    now = WeChat.Utils.now_unix()
    old_certs = remove_expired_cert(old_certs, client, now)
    old_serial_no_list = Enum.map(old_certs, & &1["serial_no"])

    new_certs
    |> Enum.filter(&(&1["serial_no"] not in old_serial_no_list))
    |> case do
      [] ->
        false

      new_certs ->
        put_certs(new_certs, client)
        {:ok, new_certs ++ old_certs}
    end
  end

  defp remove_expired_cert(certs, client, now) do
    Enum.reject(certs, fn cert ->
      if now >= cert["expire_timestamp"] do
        remove_cert(client, cert["serial_no"])
        true
      else
        false
      end
    end)
  end
end
