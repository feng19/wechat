defmodule WeChat.ServerMessage.EventHandler do
  @moduledoc """
  微信推送消息处理

  ## API Docs
    * [接入概述](https://developers.weixin.qq.com/doc/offiaccount/Basic_Information/Access_Overview.html){:target="_blank"}
    * [接入指引](https://developers.weixin.qq.com/doc/oplatform/Third-party_Platforms/Message_Encryption/Message_encryption_and_decryption.html){:target="_blank"}
    * [接入技术方案](https://developers.weixin.qq.com/doc/oplatform/Third-party_Platforms/Message_Encryption/Technical_Plan.html){:target="_blank"}
  """
  require Logger
  import WeChat.Utils, only: [doc_link_prefix: 0]
  alias WeChat.{Utils, Component, RefreshTimer, Storage.Cache}
  alias WeChat.ServerMessage.{Encryptor, XmlParser, XmlMessage}

  @type data_type :: :plaqin_text | :encrypted_xml | :encrypted_json
  @type xml :: map()
  @type xml_string :: String.t()
  @type json :: map()
  @type json_string :: String.t()
  @typep timestamp :: non_neg_integer

  @doc """
  验证消息的确来自微信服务器
  """
  @spec handle_get(params :: map()) :: String.t()
  def handle_get(params) do
    with appid <- params["appid"],
         client when client != nil <- WeChat.get_client_by_appid(appid),
         true <- check_signature?(params, client) do
      params["echostr"]
    else
      _ -> "invalid request"
    end
  end

  @doc """
  接受事件推送
  """
  @spec handle_post(
          Plug.Conn.t(),
          params :: map(),
          (WeChat.client(), message :: map() -> {:reply, reply_msg :: String.t(), timestamp})
        ) :: String.t()
  def handle_post(conn = %{body_params: body_params}, params, callback)
      when is_struct(body_params) do
    # xml data for official_account
    with appid <- params["appid"],
         client when client != nil <- WeChat.get_client_by_appid(appid),
         true <- check_signature?(params, client),
         {:ok, body, _conn} <- Plug.Conn.read_body(conn),
         {:ok, reply_type, message} <- handle_event_xml(params, body, client) do
      case callback.(client, message) do
        {:reply, reply_msg, timestamp} -> reply_msg(reply_type, reply_msg, timestamp, client)
        :retry -> "please retry"
        :error -> "please retry"
        {:error, _} -> "please retry"
        _ -> "success"
      end
    else
      _ -> "invalid request"
    end
  end

  def handle_post(%{body_params: body_params, query_params: query_params}, params, callback) do
    # json data for mini_program
    with appid <- params["appid"],
         client when client != nil <- WeChat.get_client_by_appid(appid),
         true <- check_signature?(query_params, client),
         {:ok, _reply_type, message} <- handle_event_json(query_params, body_params, client) do
      case callback.(client, message) do
        reply_msg when is_binary(reply_msg) -> reply_msg
        :retry -> "please retry"
        :error -> "please retry"
        {:error, _} -> "please retry"
        _ -> "success"
      end
    else
      _ -> "invalid request"
    end
  end

  @doc "验证消息的确来自微信服务器"
  @spec check_signature?(params :: map(), WeChat.client()) :: boolean()
  def check_signature?(params, client) do
    with signature when signature != nil <- params["signature"],
         nonce when nonce != nil <- params["nonce"],
         timestamp when timestamp != nil <- params["timestamp"] do
      signature == Utils.sha1([client.token(), nonce, to_string(timestamp)])
    else
      _ -> false
    end
  end

  @spec handle_event_xml(params :: map(), body :: String.t(), WeChat.client()) ::
          {:ok, data_type(), xml()} | {:error, String.t()}
  def handle_event_xml(params, body, client) do
    case XmlParser.parse(body) do
      {:ok, %{"Encrypt" => encrypt_content}} ->
        decode_xml_msg(
          encrypt_content,
          params["msg_signature"],
          params["nonce"],
          params["timestamp"],
          client
        )

      {:ok, xml} when is_map(xml) ->
        # 明文模式
        {:ok, :plaqin_text, xml}

      _error ->
        {:error, "invalid"}
    end
  end

  @spec handle_event_json(params :: map(), body :: String.t(), WeChat.client()) ::
          {:ok, data_type(), json()} | {:error, String.t()}
  def handle_event_json(params, body, client) when is_map(body) do
    case body do
      %{"Encrypt" => encrypt_content} ->
        decode_json_msg(
          encrypt_content,
          params["msg_signature"],
          params["nonce"],
          params["timestamp"],
          client
        )

      {:ok, json} when is_map(json) ->
        # 明文模式
        {:ok, :plaqin_text, json}

      _error ->
        {:error, "invalid"}
    end
  end

  def handle_event_json(params, body, client) do
    case Jason.decode(body) do
      {:ok, %{"Encrypt" => encrypt_content}} ->
        decode_xml_msg(
          encrypt_content,
          params["msg_signature"],
          params["nonce"],
          params["timestamp"],
          client
        )

      {:ok, json} when is_map(json) ->
        # 明文模式
        {:ok, :plaqin_text, json}

      _error ->
        {:error, "invalid"}
    end
  end

  @doc """
  处理第三方平台推送通知

  * [验证票据](#{doc_link_prefix()}/doc/oplatform/Third-party_Platforms/api/component_verify_ticket.html)
  * [授权相关推送通知](#{doc_link_prefix()}/doc/oplatform/Third-party_Platforms/api/authorize_event.html)
  """
  def handle_component_message(%{"InfoType" => info_type, "AppId" => component_appid} = message) do
    case info_type do
      "component_verify_ticket" ->
        # 验证票据
        component_verify_ticket = message["ComponentVerifyTicket"]
        Cache.put_cache(component_appid, :component_verify_ticket, component_verify_ticket)
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

        Logger.info(
          "#{component_appid} Received AuthorizerAppid: #{authorizer_appid}, [unauthorized] info."
        )

        Cache.del_cache(authorizer_appid, :authorization_code)
        Cache.del_cache(authorizer_appid, :authorization_code_expired_time)
        :handled

      _ ->
        :ignore
    end
  end

  def handle_component_message(_message), do: :ignore

  defp authorized_message(component_appid, info_type, message) do
    authorizer_appid = message["AuthorizerAppid"]

    Logger.info(
      "#{component_appid} Received AuthorizerAppid: #{authorizer_appid}, [#{info_type}] info."
    )

    authorization_code = message["AuthorizationCode"]
    Cache.put_cache(authorizer_appid, :authorization_code, authorization_code)

    Cache.put_cache(
      authorizer_appid,
      :authorization_code_expired_time,
      message["AuthorizationCodeExpiredTime"]
    )

    with client when client != nil <- Cache.search_client(authorizer_appid),
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

  @spec reply_msg(data_type(), xml_string(), timestamp, WeChat.client()) :: String.t()
  def reply_msg(:plaqin_text, reply_msg, _timestamp, _client), do: reply_msg

  def reply_msg(:encrypted_xml, reply_msg, timestamp, client) do
    encode_xml_msg(reply_msg, timestamp, client)
  end

  def reply_msg(_, _reply_msg, _timestamp, _client) do
    "success"
  end

  @compile {:inline, decode_xml_msg: 5, decode_json_msg: 5, encode_xml_msg: 3}

  @spec decode_xml_msg(
          encrypt_content :: String.t(),
          signature :: String.t(),
          nonce :: String.t(),
          timestamp,
          WeChat.client()
        ) :: {:ok, :encrypted, xml_string()} | {:error, String.t()}
  def decode_xml_msg(encrypt_content, signature, nonce, timestamp, client) do
    with ^signature <-
           Utils.sha1([client.token(), encrypt_content, nonce, to_string(timestamp)]),
         appid <- client.appid(),
         {^appid, xml_string} <- Encryptor.decrypt(encrypt_content, client.aes_key()),
         {:ok, xml} <- XmlParser.parse(xml_string) do
      {:ok, :encrypted_xml, xml}
    else
      _error ->
        {:error, "invalid"}
    end
  end

  @spec decode_json_msg(
          encrypt_content :: String.t(),
          signature :: String.t(),
          nonce :: String.t(),
          timestamp,
          WeChat.client()
        ) :: {:ok, :encrypted, json_string()} | {:error, String.t()}
  def decode_json_msg(encrypt_content, signature, nonce, timestamp, client) do
    with ^signature <-
           Utils.sha1([client.token(), encrypt_content, nonce, to_string(timestamp)]),
         appid <- client.appid(),
         {^appid, json_string} <- Encryptor.decrypt(encrypt_content, client.aes_key()),
         {:ok, json} <- Jason.decode(json_string) do
      {:ok, :encrypted_json, json}
    else
      _error ->
        {:error, "invalid"}
    end
  end

  @spec encode_xml_msg(reply_msg :: xml_string(), timestamp, WeChat.client()) :: String.t()
  def encode_xml_msg(reply_msg, timestamp, client) do
    encrypt_content = Encryptor.encrypt(reply_msg, client.appid(), client.aes_key())
    nonce = Utils.random_string(10)

    Utils.sha1([client.token(), to_string(timestamp), nonce, encrypt_content])
    |> XmlMessage.reply_msg(nonce, timestamp, encrypt_content)
  end
end
