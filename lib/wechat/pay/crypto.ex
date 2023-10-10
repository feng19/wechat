defmodule WeChat.Pay.Crypto do
  @moduledoc "用于支付加密相关"
  import WeChat.Utils, only: [pay_doc_link_prefix: 0]

  @doc """
  证书和回调报文解密 - 
  [官方文档](#{pay_doc_link_prefix()}/merchant/development/interface-rules/certificate-callback-decryption.html){:target="_blank"}
  """
  def decrypt_certificate(
        %{
          "serial_no" => serial_no,
          "effective_time" => effective_time,
          "expire_time" => expire_time,
          "nonce" => iv,
          "ciphertext" => ciphertext,
          "associated_data" => associated_data
        },
        api_secret_key
      ) do
    data = Base.decode64!(ciphertext)
    len = byte_size(data) - 16
    <<data::binary-size(len), tag::binary-size(16)>> = data

    certificate =
      :crypto.crypto_one_time_aead(
        :aes_256_gcm,
        api_secret_key,
        iv,
        data,
        associated_data,
        tag,
        false
      )

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
  def load_pem!(path) do
    path |> File.read!() |> decode_key()
  end

  @doc false
  def decode_key(binary) do
    binary |> :public_key.pem_decode() |> hd() |> :public_key.pem_entry_decode()
  end

  @doc """
  加密敏感信息 -
  [官方文档](#{pay_doc_link_prefix()}/merchant/development/interface-rules/sensitive-data-encryption.html){:target="_blank"}
  """
  def encrypt_secret_data(data, public_key) do
    :public_key.encrypt_public(data, public_key, rsa_pad: :rsa_pkcs1_oaep_padding)
  end

  @doc """
  解密敏感信息 -
  [官方文档](#{pay_doc_link_prefix()}/merchant/development/interface-rules/sensitive-data-encryption.html){:target="_blank"}
  """
  def decrypt_secret_data(cipher_text, private_key) do
    :public_key.decrypt_private(cipher_text, private_key, rsa_pad: :rsa_pkcs1_oaep_padding)
  end

  @doc """
  验签 -
  [官方文档](#{pay_doc_link_prefix()}/merchant/development/interface-rules/signature-verification.html){:target="_blank"}
  """
  def verify(signature, timestamp, nonce, body, public_key) do
    signature = Base.decode64!(signature)
    :public_key.verify("#{timestamp}\n#{nonce}\n#{body}\n", :sha256, signature, public_key)
  end

  @doc """
  签名 -
  [官方文档](#{pay_doc_link_prefix()}/merchant/development/interface-rules/signature-generation.html){:target="_blank"}
  """
  def sign(env, timestamp, nonce_str, private_key) do
    method = to_string(env.method) |> String.upcase()

    path =
      case env.query do
        [] -> env.url
        query -> env.url <> "?" <> URI.encode_query(query)
      end

    "#{method}\n#{path}\n#{timestamp}\n#{nonce_str}\n#{env.body}\n"
    |> :public_key.sign(:sha256, private_key)
    |> Base.encode64()
  end
end
