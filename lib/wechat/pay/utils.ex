defmodule WeChat.Pay.Utils do
  @moduledoc false

  # [证书和回调报文解密](https://pay.weixin.qq.com/docs/merchant/development/interface-rules/certificate-callback-decryption.html)
  # {
  #     "serial_no": "5157F09EFDC096DE15EBE81A47057A7232F1B8E1",
  #     "effective_time ": "2018-06-08T10:34:56+08:00",
  #     "expire_time ": "2018-12-08T10:34:56+08:00",
  #     "encrypt_certificate": {
  #         "algorithm": "AEAD_AES_256_GCM",
  #         "nonce": "61f9c719728a",
  #         "associated_data": "certificate",
  #         "ciphertext": "sRvt… "
  #     }
  # }
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

  def load_pem!(path) do
    path |> File.read!() |> decode_key()
  end

  def decode_key(binary) do
    binary |> :public_key.pem_decode() |> hd() |> :public_key.pem_entry_decode()
  end

  # 使用[平台证书中的公钥]进行加密
  def encrypt_secret_data(data, public_key) do
    :public_key.encrypt_public(data, public_key, rsa_pad: :rsa_pkcs1_oaep_padding)
  end

  # 使用[商户API私钥]进行解密
  def decrypt_secret_data(cipher_text, private_key) do
    :public_key.decrypt_private(cipher_text, private_key, rsa_pad: :rsa_pkcs1_oaep_padding)
  end

  # 使用[平台证书中的公钥]进行验签
  def verify(signature, timestamp, nonce, body, public_key) do
    # signature = Base.decode64!(signature)
    :public_key.verify("#{timestamp}\n#{nonce}\n#{body}\n", :sha256, signature, public_key)
  end

  # 使用[商户API私钥]进行签名
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

  def get_token(mch_id, serial_no, private_key, env) do
    timestamp = WeChat.Utils.now_unix()
    nonce_str = :crypto.strong_rand_bytes(32) |> Base.url_encode64()
    signature = sign(env, timestamp, nonce_str, private_key)

    ~s(mchid="#{mch_id}",nonce_str="#{nonce_str}",timestamp="#{timestamp}",serial_no="#{serial_no}",signature="#{signature}")
  end
end
