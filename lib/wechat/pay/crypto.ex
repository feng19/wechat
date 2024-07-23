defmodule WeChat.Pay.Crypto do
  @moduledoc "用于支付加密相关"
  @compile {:no_warn_undefined, Plug.Crypto}

  def decrypt_aes_256_gcm(api_secret_key, ciphertext, associated_data, iv) do
    data = Base.decode64!(ciphertext, padding: false)
    len = byte_size(data) - 16
    <<data::binary-size(len), tag::binary-size(16)>> = data

    :crypto.crypto_one_time_aead(
      :aes_256_gcm,
      api_secret_key,
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
  def load_pem!({:binary, binary}), do: decode_key(binary)

  @doc false
  def decode_key(binary) do
    binary |> :public_key.pem_decode() |> hd() |> :public_key.pem_entry_decode()
  end

  @doc """
  加密敏感信息 -
  [官方文档](https://pay.weixin.qq.com/docs/merchant/development/interface-rules/sensitive-data-encryption.html){:target="_blank"}
  """
  def encrypt_secret_data(data, public_key) do
    :public_key.encrypt_public(data, public_key, rsa_pad: :rsa_pkcs1_oaep_padding)
  end

  @doc """
  解密敏感信息 -
  [官方文档](https://pay.weixin.qq.com/docs/merchant/development/interface-rules/sensitive-data-encryption.html){:target="_blank"}
  """
  def decrypt_secret_data(cipher_text, private_key) do
    :public_key.decrypt_private(cipher_text, private_key, rsa_pad: :rsa_pkcs1_oaep_padding)
  end

  @doc """
  验签 -
  [官方文档](https://pay.weixin.qq.com/docs/merchant/development/interface-rules/signature-verification.html){:target="_blank"}
  """
  def verify(signature, timestamp, nonce, body, public_key) do
    case Base.decode64(signature, padding: false) do
      {:ok, signature} ->
        :public_key.verify("#{timestamp}\n#{nonce}\n#{body}\n", :sha256, signature, public_key)

      _ ->
        false
    end
  end

  @doc """
  签名 -
  [官方文档](https://pay.weixin.qq.com/docs/merchant/development/interface-rules/signature-generation.html){:target="_blank"}
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

  @doc """
  签名(v2) -
  [官方文档](https://pay.weixin.qq.com/wiki/doc/api/micropay.php?chapter=4_3){:target="_blank"}
  """
  @spec v2_sign(data :: map, key :: binary) :: signature :: binary
  def v2_sign(params, key) when is_map(params) do
    method = Map.get(params, "sign_type", "MD5")
    v2_sign(params, method, key)
  end

  @spec v2_sign(data :: binary | map, method :: binary, key :: binary) :: signature :: binary
  def v2_sign(plain_text, method, key)

  def v2_sign(plain_text, "HMAC-SHA256", key) when is_binary(plain_text) do
    :crypto.mac(:hmac, :sha256, key, plain_text <> "&key=#{key}") |> Base.encode16()
  end

  def v2_sign(plain_text, "MD5", key) when is_binary(plain_text) do
    (plain_text <> "&key=#{key}") |> :erlang.md5() |> Base.encode16()
  end

  def v2_sign(params, method, key) do
    params
    |> Enum.sort_by(&elem(&1, 0))
    |> Enum.filter(fn
      {_k, ""} -> false
      {k, v} when is_binary(k) and is_binary(v) -> true
      {k, v} when is_binary(k) and is_list(v) -> true
      {k, v} when is_binary(k) and is_integer(v) -> true
      {k, v} when is_binary(k) and is_map(v) -> true
      _ -> false
    end)
    |> Enum.map(fn
      {k, v} when is_list(v) -> "#{k}=#{Jason.encode!(v)}"
      {k, v} when is_map(v) -> "#{k}=#{Jason.encode!(v)}"
      {k, v} -> "#{k}=#{v}"
    end)
    |> Enum.join("&")
    |> v2_sign(method, key)
  end

  def v2_verify(params, method, key) do
    {signature, params} = Map.pop!(params, "sign")

    v2_sign(params, method, key)
    |> Plug.Crypto.secure_compare(signature)
  end
end
