defmodule WeChat.ServerMessage.EventHandler do
  @moduledoc """
  微信推送消息处理

  ## API Docs
    * [接入概述](https://developers.weixin.qq.com/doc/offiaccount/Basic_Information/Access_Overview.html){:target="_blank"}
    * [接入指引](https://developers.weixin.qq.com/doc/oplatform/Third-party_Platforms/Message_Encryption/Message_encryption_and_decryption.html){:target="_blank"}
    * [接入技术方案](https://developers.weixin.qq.com/doc/oplatform/Third-party_Platforms/Message_Encryption/Technical_Plan.html){:target="_blank"}
  """
  require Logger
  alias WeChat.{Utils, Component, RefreshTimer}
  alias WeChat.ServerMessage.{Encryptor, XmlParser, XmlMessage}

  @type reply_type :: :plaqin_text | :encrypted
  @type xml :: map()
  @type xml_string :: String.t()

  @spec handle_event(params :: map(), body :: String.t(), WeChat.client()) ::
          {:ok, reply_type(), xml()} | {:error, String.t()}
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

  @doc """
  处理第三方平台推送通知

  * [验证票据](#{WeChat.doc_link_prefix()}/oplatform/Third-party_Platforms/api/component_verify_ticket.html)
  * [授权相关推送通知](#{WeChat.doc_link_prefix()}/oplatform/Third-party_Platforms/api/authorize_event.html)
  """
  def handle_component_message(message) do
    with %{"InfoType" => info_type} <- message do
      component_appid = message["AppId"]

      case info_type do
        "component_verify_ticket" ->
          # 验证票据
          component_verify_ticket = message["ComponentVerifyTicket"]
          WeChat.put_cache(component_appid, :component_verify_ticket, component_verify_ticket)
          Logger.info("#{component_appid} Received [component_verify_ticket] info.")
          :handled

        "authorized" ->
          # 授权成功通知
          authorized_message(component_appid, info_type, message)

        "updateauthorized" ->
          # 授权更新通知
          authorized_message(component_appid, info_type, message)

        "unauthorized" ->
          # 取消授权通知
          authorizer_appid = message["AuthorizerAppid"]
          Logger.info("#{component_appid} Received AuthorizerAppid: #{authorizer_appid}, [unauthorized] info.")
          WeChat.del_cache(authorizer_appid, :authorization_code)
          WeChat.del_cache(authorizer_appid, :authorization_code_expired_time)
          :handled

        _ ->
          :ignore
      end
    else
      _ ->
        :ignore
    end
  end

  defp authorized_message(component_appid, info_type, message) do
    authorizer_appid = message["AuthorizerAppid"]
    Logger.info("#{component_appid} Received AuthorizerAppid: #{authorizer_appid}, [#{info_type}] info.")
    authorization_code = message["AuthorizationCode"]
    WeChat.put_cache(authorizer_appid, :authorization_code, authorization_code)

    WeChat.put_cache(
      authorizer_appid,
      :authorization_code_expired_time,
      message["AuthorizationCodeExpiredTime"]
    )

    with client when client != nil <- WeChat.search_client(authorizer_appid),
         {:ok, %{status: 200, body: body}} <- Component.query_auth(client, authorization_code),
         %{"authorization_info" => authorization_info} <- body,
         %{
           "authorizer_access_token" => authorizer_access_token,
           "authorizer_refresh_token" => authorizer_refresh_token,
           "expires_in" => expires_in
         } <- authorization_info do
      now = Utils.now_unix()

      RefreshTimer.refresh_key(
        authorizer_appid,
        :access_token,
        authorizer_access_token,
        now + expires_in,
        client
      )

      # 官网并未说明有效期是多少，暂时指定一年有效期
      RefreshTimer.refresh_key(
        authorizer_appid,
        :authorizer_refresh_token,
        authorizer_refresh_token,
        now + 356 * 24 * 60 * 60,
        client
      )
    end

    :handled
  end

  @spec reply_msg(reply_type(), xml_string(), timestamp :: integer(), WeChat.client()) ::
          xml_string()
  def reply_msg(:plaqin_text, reply_msg, _timestamp, _client), do: reply_msg

  def reply_msg(:encrypted, reply_msg, timestamp, client) do
    encode_msg(reply_msg, timestamp, client)
  end

  @compile {:inline, decode_msg: 5, encode_msg: 3}

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
         {^appid, xml_string} <- Encryptor.decrypt(encrypt_content, client.encoding_aes_key()),
         {:ok, xml} <- XmlParser.parse(xml_string) do
      {:ok, :encrypted, xml}
    else
      _error ->
        {:error, "invalid"}
    end
  end

  @spec encode_msg(reply_msg :: xml(), timestamp :: integer(), WeChat.client()) :: xml_string()
  def encode_msg(reply_msg, timestamp, client) do
    encrypt_content = Encryptor.encrypt(reply_msg, client.appid(), client.encoding_aes_key())
    nonce = Utils.random_string(10)

    Encryptor.get_sha1([client.token(), to_string(timestamp), nonce, encrypt_content])
    |> XmlMessage.reply_msg(nonce, timestamp, encrypt_content)
  end
end
