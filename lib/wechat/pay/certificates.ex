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
  @spec certificates(Pay.client(), first? :: boolean) :: {:ok, list(map)} | any
  def certificates(client, first? \\ false)

  def certificates(client, false) do
    with {:ok, %{body: %{"data" => certificates}}} when is_list(certificates) <-
           client.get("/v3/certificates") do
      {:ok, Enum.map(certificates, &decrypt_certificate(&1, client))}
    end
  end

  def certificates(client, true) do
    with {:ok, %{body: %{"data" => certificates}}} when is_list(certificates) <-
           WeChat.Requester.Pay.first_time_download_certificates_client(client)
           |> Tesla.get("/v3/certificates", []) do
      {:ok, Enum.map(certificates, &decrypt_certificate(&1, client))}
    end
  end

  @doc """
  证书和回调报文解密 - 
  [官方文档](#{pay_doc_link_prefix()}/merchant/development/interface-rules/certificate-callback-decryption.html){:target="_blank"}
  """
  @spec decrypt_certificate(data :: map, Pay.client()) :: map
  def decrypt_certificate(
        %{
          "serial_no" => serial_no,
          "effective_time" => effective_time,
          "expire_time" => expire_time,
          "encrypt_certificate" => %{
            "algorithm" => "AEAD_AES_256_GCM",
            "nonce" => iv,
            "ciphertext" => ciphertext,
            "associated_data" => associated_data
          }
        },
        client
      ) do
    certificate = Crypto.decrypt_aes_256_gcm(client, ciphertext, associated_data, iv)
    {:ok, effective_datetime, _utc_offset} = DateTime.from_iso8601(effective_time)
    {:ok, expire_datetime, _utc_offset} = DateTime.from_iso8601(expire_time)

    %{
      "serial_no" => serial_no,
      "effective_time" => effective_time,
      "effective_timestamp" => DateTime.to_unix(effective_datetime),
      "expire_time" => expire_time,
      "expire_timestamp" => DateTime.to_unix(expire_datetime),
      "certificate" => certificate
    }
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
