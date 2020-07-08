defmodule WeChat.ServerMessage.EventHandler do
  @moduledoc """
  微信推送消息处理

  ## API Docs
    * [接入概述](https://developers.weixin.qq.com/doc/offiaccount/Basic_Information/Access_Overview.html){:target="_blank"}
    * [接入指引](https://developers.weixin.qq.com/doc/oplatform/Third-party_Platforms/Message_Encryption/Message_encryption_and_decryption.html){:target="_blank"}
    * [接入技术方案](https://developers.weixin.qq.com/doc/oplatform/Third-party_Platforms/Message_Encryption/Technical_Plan.html){:target="_blank"}
  """
  alias WeChat.Utils
  alias WeChat.ServerMessage.{Encryptor, XmlParser, XmlMessage}

  @spec handle_event(params :: map(), body :: String.t(), WeChat.client()) ::
          {:ok, :plaqin_text | :encrypted, xml :: String.t()} | {:error, String.t()}
  def handle_event(params, body, client) do
    with {:ok, %{"Encrypt" => encrypt_content}} <- XmlParser.parse(body) do
      decode_msg(
        encrypt_content,
        params["msg_signature"],
        params["nonce"],
        params["timestamp"],
        client
      )
    else
      {:ok, xml} when is_map(xml) ->
        # 明文模式
        {:ok, :plaqin_text, xml}

      _error ->
        {:error, "invalid"}
    end
  end

  @spec decode_msg(
          encrypt_content :: String.t(),
          signature :: String.t(),
          nonce :: String.t(),
          timestamp :: integer,
          WeChat.client()
        ) ::
          {:ok, :encrypted, xml :: String.t()} | {:error, String.t()}
  def decode_msg(encrypt_content, signature, nonce, timestamp, client) do
    with ^signature <-
           Encryptor.get_sha1([client.token(), encrypt_content, nonce, to_string(timestamp)]),
         appid <- client.appid(),
         {^appid, xml} <- Encryptor.decrypt(encrypt_content, client.encoding_aes_key()),
         {:ok, xml} <- XmlParser.parse(xml) do
      {:ok, :encrypted, xml}
    else
      _error ->
        {:error, "invalid"}
    end
  end

  @spec encode_msg(reply_msg :: String.t(), timestamp :: integer(), WeChat.client()) ::
          xml :: String.t()
  def encode_msg(reply_msg, timestamp, client) do
    encrypt_content = Encryptor.encrypt(reply_msg, client.appid(), client.encoding_aes_key())
    nonce = Utils.random_string(10)

    Encryptor.get_sha1([client.token(), to_string(timestamp), nonce, encrypt_content])
    |> XmlMessage.reply_msg(nonce, timestamp, encrypt_content)
  end
end
