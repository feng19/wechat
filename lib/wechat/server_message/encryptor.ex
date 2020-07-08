defmodule WeChat.ServerMessage.Encryptor do
  @moduledoc """
  消息加解密

  [API Docs Link](https://developers.weixin.qq.com/doc/oplatform/Third-party_Platforms/Message_Encryption/Technical_Plan.html)
  """
  @type encoding_aes_key :: String.t()

  @aes_block_size 16
  @pad_block_size 32

  @spec get_sha1([String.t()]) :: signature :: String.t()
  def get_sha1(list) do
    str_to_sign =
      list
      |> Enum.sort()
      |> Enum.join()

    :crypto.hash(:sha, str_to_sign) |> Base.encode16(case: :lower)
  end

  @spec encrypt(msg :: String.t(), WeChat.appid(), encoding_aes_key()) ::
          msg_encrypted :: String.t()
  def encrypt(msg, appid, encoding_aes_key) do
    aes_key = aes_key(encoding_aes_key)

    msg
    |> pack_appid(appid)
    |> encode_padding_with_pkcs7()
    |> encrypt_with_aes_cbc(aes_key)
    |> Base.encode64()
  end

  @spec decrypt(msg_encrypted :: String.t(), encoding_aes_key()) ::
          {WeChat.appid(), xml :: String.t()}
  def decrypt(msg_encrypted, encoding_aes_key) do
    aes_key = aes_key(encoding_aes_key)

    msg_encrypted
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

  defp encode_padding_with_pkcs7(data) do
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

  defp decode_padding_with_pkcs7(data) do
    data_size = byte_size(data)
    <<pad::8>> = binary_part(data, data_size, -1)
    binary_part(data, 0, data_size - pad)
  end

  defp encrypt_with_aes_cbc(plain_text, aes_key) do
    iv = binary_part(aes_key, 0, @aes_block_size)
    :crypto.block_encrypt(:aes_cbc, aes_key, iv, plain_text)
  end

  defp decrypt_with_aes_cbc(cipher_text, aes_key) do
    iv = binary_part(aes_key, 0, @aes_block_size)
    :crypto.block_decrypt(:aes_cbc, aes_key, iv, cipher_text)
  end

  # get AES key from encoding_aes_key.
  defp aes_key(encoding_aes_key) do
    Base.decode64!(encoding_aes_key <> "=")
  end
end
