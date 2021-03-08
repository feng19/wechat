defmodule WeChat.ServerMessage.Encryptor do
  @moduledoc """
  消息加解密

  [官方文档](https://developers.weixin.qq.com/doc/oplatform/Third-party_Platforms/Message_Encryption/Technical_Plan.html)
  """

  @typedoc """
  服务器配置里的 `EncodingAESKey` 值，在接收消息时用于解密消息
  """
  @type encoding_aes_key :: String.t()
  @typedoc """
  对 `encoding_aes_key <> "="` 进行 `Base.decode64!`之后的值
  """
  @type aes_key :: String.t()
  @type message :: String.t()
  @type encrypted_message :: String.t()

  @aes_block_size 16
  @pad_block_size 32

  @spec encrypt(message, WeChat.appid(), aes_key) :: encrypted_message
  def encrypt(message, appid, aes_key) do
    message
    |> pack_appid(appid)
    |> encode_padding_with_pkcs7()
    |> encrypt_with_aes_cbc(aes_key)
    |> Base.encode64()
  end

  @spec decrypt(encrypted_message, aes_key) :: {WeChat.appid(), message}
  def decrypt(encrypted_message, aes_key) do
    encrypted_message
    |> Base.decode64!()
    |> decrypt_with_aes_cbc(aes_key)
    |> decode_padding_with_pkcs7()
    |> unpack_appid()
  end

  # random(16B) + msg_size(4B) + msg + appid
  defp pack_appid(msg, appid) do
    random = :crypto.strong_rand_bytes(16)
    msg_size = byte_size(msg)
    random <> <<msg_size::32>> <> msg <> appid
  end

  # random(16B) + msg_size(4B) + msg + appid
  defp unpack_appid(
         <<_random::binary-16, msg_size::32, msg::binary-size(msg_size), appid::binary>>
       ) do
    {appid, msg}
  end

  def encode_padding_with_pkcs7(data) do
    pad =
      data
      |> byte_size()
      |> rem(@pad_block_size)
      |> case do
        0 -> @pad_block_size
        rem -> @pad_block_size - rem
      end

    data <> String.duplicate(<<pad::8>>, pad)
  end

  def decode_padding_with_pkcs7(data) do
    data_size = byte_size(data)
    <<pad::8>> = binary_part(data, data_size, -1)
    binary_part(data, 0, data_size - pad)
  end

  defp encrypt_with_aes_cbc(plain_text, aes_key) do
    iv = binary_part(aes_key, 0, @aes_block_size)
    :crypto.crypto_one_time(:aes_256_cbc, aes_key, iv, plain_text, true)
  end

  defp decrypt_with_aes_cbc(cipher_text, aes_key) do
    iv = binary_part(aes_key, 0, @aes_block_size)
    :crypto.crypto_one_time(:aes_256_cbc, aes_key, iv, cipher_text, false)
  end

  # get AES key from encoding_aes_key.
  @doc false
  def aes_key(encoding_aes_key) do
    Base.decode64!(encoding_aes_key <> "=")
  end
end
