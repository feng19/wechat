defmodule WeChat.MiniProgram.Auth do
  @moduledoc """
  权限接口
  """
  import WeChat.Utils, only: [doc_link_prefix: 0]
  alias WeChat.{Utils, ServerMessage.Encryptor, Storage.Cache}

  @doc_link "#{doc_link_prefix()}/miniprogram/dev/api-backend/open-api"
  @open_ability_doc_link "#{doc_link_prefix()}/miniprogram/dev/framework/open-ability"

  @doc """
  服务端获取开放数据 - [Official API Docs Link](#{@open_ability_doc_link}/signature.html)

  [小程序登录](#{@open_ability_doc_link}/login.html)
  """
  @spec decode_user_info(
          session_key :: String.t(),
          raw_data :: String.t(),
          signature :: String.t()
        ) :: {:ok, map()} | {:error, String.t()}
  def decode_user_info(session_key, raw_data, signature) do
    case Utils.sha1(raw_data <> session_key) do
      ^signature ->
        Jason.decode(raw_data)

      _ ->
        {:error, "invalid"}
    end
  end

  @doc """
  服务端获取开放数据 - 包含敏感数据 - [Official API Docs Link](#{@open_ability_doc_link}/signature.html)

  * [小程序登录](#{@open_ability_doc_link}/login.html)
  * [加密数据解密算法](#{@open_ability_doc_link}/signature.html#加密数据解密算法)
  """
  @spec decode_get_user_sensitive_info(
          session_key :: String.t(),
          encrypted_data :: String.t(),
          iv :: String.t()
        ) :: {:ok, map()} | :error | {:error, any()}
  def decode_get_user_sensitive_info(session_key, encrypted_data, iv) do
    with {:ok, session_key} <- Base.decode64(session_key),
         {:ok, iv} <- Base.decode64(iv),
         {:ok, encrypted_data} <- Base.decode64(encrypted_data) do
      :crypto.block_decrypt(:aes_cbc, session_key, iv, encrypted_data)
      |> Encryptor.decode_padding_with_pkcs7()
      |> Jason.decode()
    end
  end

  @doc """
  小程序登录

  Official API Docs Link:
    * [Mini Program](#{@doc_link}/login/auth.code2Session.html){:target="_blank"}
    * [Component](#{doc_link_prefix()}/doc/oplatform/Third-party_Platforms/Mini_Programs/WeChat_login.html){:target="_blank"}
  """
  @spec code2session(WeChat.client(), code :: String.t()) :: WeChat.response()
  def code2session(client, code) do
    case client.role() do
      :mini_program ->
        client.get("/sns/jscode2session",
          query: [
            appid: client.appid(),
            secret: client.appsecret(),
            js_code: code,
            grant_type: "authorization_code"
          ]
        )

      :component ->
        component_appid = client.component_appid()

        client.get("/sns/component/jscode2session",
          query: [
            appid: client.appid(),
            js_code: code,
            grant_type: "authorization_code",
            component_appid: component_appid,
            component_access_token: Cache.get_cache(component_appid, :component_access_token)
          ]
        )
    end
  end

  @doc """
  支付后获取用户的`UnionId` - [Official API Docs Link](#{@doc_link}/user-info/auth.getPaidUnionId.html){:target="_blank"}

  用户支付完成后，获取该用户的`UnionId`，无需用户授权.

  本接口支持第三方平台代理查询.

  **注意：调用前需要用户完成支付，且在支付后的五分钟内有效**
  """
  @spec get_paid_unionid(WeChat.client(), WeChat.openid()) :: WeChat.response()
  def get_paid_unionid(client, openid) do
    client.get("/wxa/getpaidunionid",
      query: [
        openid: openid,
        access_token: client.get_access_token()
      ]
    )
  end

  @doc """
  支付后获取用户的`UnionId` - 微信支付订单号(`transaction_id`) - [Official API Docs Link](#{@doc_link}/user-info/auth.getPaidUnionId.html){:target="_blank"}

  用户支付完成后，获取该用户的`UnionId`，无需用户授权.

  本接口支持第三方平台代理查询.

  **注意：调用前需要用户完成支付，且在支付后的五分钟内有效**
  """
  @spec get_paid_unionid(WeChat.client(), WeChat.openid(), transaction_id :: String.t()) ::
          WeChat.response()
  def get_paid_unionid(client, openid, transaction_id) do
    client.get("/wxa/getpaidunionid",
      query: [
        openid: openid,
        transaction_id: transaction_id,
        access_token: client.get_access_token()
      ]
    )
  end

  @doc """
  支付后获取用户的`UnionId` - 微信支付商户订单号和微信支付商户号(`out_trade_no`及`mch_id`) - [Official API Docs Link](#{
    @doc_link
  }/user-info/auth.getPaidUnionId.html){:target="_blank"}

  用户支付完成后，获取该用户的`UnionId`，无需用户授权.

  本接口支持第三方平台代理查询.

  **注意：调用前需要用户完成支付，且在支付后的五分钟内有效**
  """
  @spec get_paid_unionid(
          WeChat.client(),
          WeChat.openid(),
          mch_id :: String.t(),
          out_trade_no :: String.t()
        ) :: WeChat.response()
  def get_paid_unionid(client, openid, mch_id, out_trade_no) do
    client.get("/wxa/getpaidunionid",
      query: [
        openid: openid,
        mch_id: mch_id,
        out_trade_no: out_trade_no,
        access_token: client.get_access_token()
      ]
    )
  end

  @doc """
  获取AccessToken - [Official API Docs Link](#{@doc_link}/access-token/auth.getAccessToken.html){:target="_blank"}
  """
  @spec get_access_token(WeChat.client()) :: WeChat.response()
  def get_access_token(client) do
    client.get("/cgi-bin/token",
      query: [
        grant_type: "client_credential",
        appid: client.appid(),
        secret: client.appsecret()
      ]
    )
  end
end
