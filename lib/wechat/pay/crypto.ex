defmodule WeChat.Pay.Crypto do
  @moduledoc "用于支付加密相关"
  import WeChat.Utils, only: [pay_doc_link_prefix: 0]

  def decrypt_aes_256_gcm(client, ciphertext, associated_data, iv) do
    data = Base.decode64!(ciphertext)
    len = byte_size(data) - 16
    <<data::binary-size(len), tag::binary-size(16)>> = data

    :crypto.crypto_one_time_aead(
      :aes_256_gcm,
      client.api_secret_key(),
      iv,
      data,
      associated_data,
      tag,
      false
    )
  end

  @doc false
  def load_pem!({:app_dir, app, path}), do: load_pem!({:file, Application.app_dir(app, path)})
  def load_pem!({:file, path}), do: path |> File.read!() |> decode_key()

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
    %{path: path} = URI.parse(env.url)

    path =
      case env.query do
        [] -> path
        query -> path <> "?" <> URI.encode_query(query)
      end

    "#{method}\n#{path}\n#{timestamp}\n#{nonce_str}\n#{env.body}\n"
    |> :public_key.sign(:sha256, private_key)
    |> Base.encode64()
  end
end
