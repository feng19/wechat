if Code.ensure_loaded?(Plug) do
  defmodule WeChat.ServerMessage.EventHelper do
    @moduledoc """
    微信推送消息处理

    ## API Docs
      * [接入概述](https://developers.weixin.qq.com/doc/offiaccount/Basic_Information/Access_Overview.html){:target="_blank"}
      * [接入指引](https://developers.weixin.qq.com/doc/oplatform/Third-party_Platforms/Message_Encryption/Message_encryption_and_decryption.html){:target="_blank"}
      * [接入技术方案](https://developers.weixin.qq.com/doc/oplatform/Third-party_Platforms/Message_Encryption/Technical_Plan.html){:target="_blank"}
    """
    import WeChat.Utils, only: [doc_link_prefix: 0]
    require Logger
    alias WeChat.{Work, Utils, Component, Storage.Cache}
    alias WeChat.ServerMessage.{Encryptor, XmlParser, ReplyMessage}

    @type data_type :: :plaqin_text | :encrypted_xml | :encrypted_json
    @type encrypt_content :: String.t()
    @type xml :: map
    @type xml_string :: String.t()
    @type json :: map
    @type json_string :: String.t()
    @type nonce :: String.t()
    @type signature :: String.t()
    @type status :: Plug.Conn.status()
    @typep timestamp :: non_neg_integer
    @typep params :: map

    @doc "验证消息的确来自微信服务器"
    @spec check_signature?(params, WeChat.token()) :: boolean()
    def check_signature?(params, token) do
      with signature when signature != nil <- params["signature"],
           nonce when nonce != nil <- params["nonce"],
           timestamp when timestamp != nil <- params["timestamp"],
           {timestamp, ""} <- Integer.parse(timestamp),
           now_timestamp <- Utils.now_unix(),
           true <- now_timestamp >= timestamp and now_timestamp - timestamp <= 5 do
        challenge = Utils.sha1([token, nonce, to_string(timestamp)])
        Plug.Crypto.secure_compare(challenge, signature)
      else
        _ -> false
      end
    end

    @spec check_msg_signature?(encrypt_content, params, WeChat.token()) :: boolean()
    def check_msg_signature?(encrypt_content, params, token) do
      with signature when signature != nil <- params["msg_signature"],
           nonce when nonce != nil <- params["nonce"],
           timestamp when timestamp != nil <- params["timestamp"] do
        challenge = Utils.sha1([token, encrypt_content, nonce, to_string(timestamp)])
        Plug.Crypto.secure_compare(challenge, signature)
      else
        _ -> false
      end
    end

    @doc "parse xml format event message for official_account"
    @spec parse_xml_event(params, body :: String.t() | map, WeChat.client()) ::
            {:ok, data_type, xml} | {:error, String.t()}
    def parse_xml_event(params, body, client) do
      case XmlParser.parse(body) do
        # 安全模式
        {:ok, %{"Encrypt" => encrypt_content}} ->
          decrypt_xml_msg(encrypt_content, params, client)

        # 明文模式
        {:ok, xml} when is_map(xml) ->
          {:ok, :plaqin_text, xml}

        _error ->
          {:error, "invalid"}
      end
    end

    @doc "parse xml format event message for work"
    @spec parse_work_xml_event(params, body :: String.t() | map, WeChat.client(), Work.Agent.t()) ::
            {:ok, data_type, xml} | {:error, String.t()}
    def parse_work_xml_event(params, body, client, agent) do
      with {:ok, %{"Encrypt" => encrypt_content}} <- XmlParser.parse(body),
           token when token != nil <- agent.token,
           true <- check_msg_signature?(encrypt_content, params, token) do
        decrypt_xml_msg(encrypt_content, params, client.appid(), token, agent.aes_key)
      else
        _error -> {:error, "invalid"}
      end
    end

    # json format event message for mini_program
    @spec parse_json_event(params, body :: String.t(), WeChat.client()) ::
            {:ok, data_type, json} | {:error, String.t()}
    def parse_json_event(params, body, client) when is_map(body) do
      case body do
        # 安全模式
        %{"Encrypt" => encrypt_content} -> decrypt_json_msg(encrypt_content, params, client)
        # 明文模式
        json when is_map(json) -> {:ok, :plaqin_text, json}
        _error -> {:error, "invalid"}
      end
    end

    def parse_json_event(params, body, client) when is_binary(body) do
      case Jason.decode(body) do
        {:ok, body} -> parse_json_event(params, body, client)
        _ -> {:error, "invalid"}
      end
    end

    @doc """
    处理第三方平台推送通知

    * [验证票据](#{doc_link_prefix()}/doc/oplatform/Third-party_Platforms/api/component_verify_ticket.html)
    * [授权相关推送通知](#{doc_link_prefix()}/doc/oplatform/Third-party_Platforms/api/authorize_event.html)
    """
    def handle_component_event(_conn, client, %{"AppId" => component_appid} = message) do
      case info_type = message["InfoType"] do
        # 验证票据
        "component_verify_ticket" ->
          component_verify_ticket_message(component_appid, client, message)

        # 授权成功通知
        "authorized" ->
          authorized_message(component_appid, info_type, message)

        # 授权更新通知
        "updateauthorized" ->
          authorized_message(component_appid, info_type, message)

        # 取消授权通知
        "unauthorized" ->
          authorizer_appid = message["AuthorizerAppid"]

          Logger.info(
            "#{component_appid} Received AuthorizerAppid: #{authorizer_appid}, [unauthorized] info."
          )

          Cache.del_cache(authorizer_appid, :authorization_code)
          Cache.del_cache(authorizer_appid, :authorization_code_expired_time)
          :ok

        _ ->
          :ignore
      end
    end

    defp component_verify_ticket_message(component_appid, client, message) do
      ticket = message["ComponentVerifyTicket"]
      store_id = component_appid
      store_key = :component_verify_ticket
      store_map = %{"value" => ticket, "expired_time" => Utils.now_unix() + 600}
      Cache.put_cache(store_id, store_key, ticket)
      Cache.put_cache({:store_map, store_id}, store_key, store_map)

      if storage = client.storage() do
        result = storage.store(store_id, store_key, store_map)

        Logger.info(
          "Call #{inspect(storage)}.store(#{store_id}, #{store_key}, #{inspect(store_map)}) => #{inspect(result)}."
        )
      end

      Logger.info("#{component_appid} Received [component_verify_ticket] info.")
      :ok
    end

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

        refresher = WeChat.refresher()

        refresher.refresh_key(
          client,
          authorizer_appid,
          :access_token,
          authorizer_access_token,
          now + expires_in
        )

        # 官网并未说明有效期是多少，暂时指定一年有效期
        refresher.refresh_key(
          client,
          authorizer_appid,
          :authorizer_refresh_token,
          authorizer_refresh_token,
          now + 356 * 24 * 60 * 60
        )
      end

      :ok
    end

    @doc false
    @spec reply_msg(data_type, xml_string, timestamp, WeChat.client()) :: String.t()
    def reply_msg(:plaqin_text, xml_string, _timestamp, _client), do: xml_string

    def reply_msg(:encrypted_xml, xml_string, timestamp, client),
      do: encrypt_xml_msg(xml_string, timestamp, client)

    def reply_msg(_, _reply_msg, _timestamp, _client), do: "success"

    @spec reply_msg(data_type, xml_string, timestamp, WeChat.client(), Work.Agent.t()) ::
            String.t()
    def reply_msg(:plaqin_text, xml_string, _timestamp, _client, _agent), do: xml_string

    def reply_msg(:encrypted_xml, xml_string, timestamp, client, agent),
      do: encrypt_xml_msg(xml_string, timestamp, client, agent)

    def reply_msg(_, _reply_msg, _timestamp, _client, _agent), do: "success"

    @spec decrypt_xml_msg(encrypt_content, params, WeChat.client()) ::
            {:ok, :encrypted, xml_string} | {:error, String.t()}
    def decrypt_xml_msg(encrypt_content, params, client) do
      decrypt_xml_msg(encrypt_content, params, client.appid(), client.token(), client.aes_key())
    end

    @spec decrypt_xml_msg(
            encrypt_content,
            params,
            WeChat.appid(),
            WeChat.token(),
            Encryptor.aes_key()
          ) :: {:ok, :encrypted, xml_string} | {:error, String.t()}
    def decrypt_xml_msg(encrypt_content, params, appid, token, aes_key) do
      with true <- check_msg_signature?(encrypt_content, params, token),
           {^appid, xml_string} <- Encryptor.decrypt(encrypt_content, aes_key),
           {:ok, xml} <- XmlParser.parse(xml_string) do
        {:ok, :encrypted_xml, xml}
      else
        _error -> {:error, "invalid"}
      end
    end

    @spec decrypt_json_msg(encrypt_content, params, WeChat.client()) ::
            {:ok, :encrypted, json_string} | {:error, String.t()}
    def decrypt_json_msg(encrypt_content, params, client) do
      decrypt_json_msg(encrypt_content, params, client.appid(), client.token(), client.aes_key())
    end

    @spec decrypt_json_msg(
            encrypt_content,
            params,
            WeChat.appid(),
            WeChat.token(),
            Encryptor.aes_key()
          ) :: {:ok, :encrypted, json_string} | {:error, String.t()}
    def decrypt_json_msg(encrypt_content, params, appid, token, aes_key) do
      with true <- check_msg_signature?(encrypt_content, params, token),
           {^appid, json_string} <- Encryptor.decrypt(encrypt_content, aes_key),
           {:ok, json} <- Jason.decode(json_string) do
        {:ok, :encrypted_json, json}
      else
        _error -> {:error, "invalid"}
      end
    end

    @spec encrypt_xml_msg(xml_string, timestamp, WeChat.client()) :: String.t()
    def encrypt_xml_msg(xml_string, timestamp, client) do
      encrypt_xml_msg(xml_string, timestamp, client.appid(), client.token(), client.aes_key())
    end

    @spec encrypt_xml_msg(xml_string, timestamp, WeChat.client(), Work.Agent.t()) :: String.t()
    def encrypt_xml_msg(xml_string, timestamp, client, agent) do
      encrypt_xml_msg(xml_string, timestamp, client.appid(), agent.token, agent.aes_key)
    end

    @spec encrypt_xml_msg(
            xml_string,
            timestamp,
            WeChat.appid(),
            WeChat.token(),
            Encryptor.aes_key()
          ) :: String.t()
    def encrypt_xml_msg(xml_string, timestamp, appid, token, aes_key) do
      encrypt_content = Encryptor.encrypt(xml_string, appid, aes_key)
      nonce = Utils.random_string(10)

      Utils.sha1([token, to_string(timestamp), nonce, encrypt_content])
      |> ReplyMessage.reply_msg(nonce, timestamp, encrypt_content)
    end
  end
end
