defmodule WeChat.MiniProgram.Auth do
  @moduledoc """
  小程序 - 权限接口
  """
  alias WeChat.Storage.Cache
  alias WeChat.MiniProgram.UserInfo

  @typedoc "会话密钥"
  @type session_key :: String.t()

  @doc """
  服务端获取开放数据 -
  [官方文档](https://developers.weixin.qq.com/miniprogram/dev/framework/open-ability/signature.html){:target="_blank"}

  [登录流程](https://developers.weixin.qq.com/miniprogram/dev/framework/open-ability/login.html)
  """
  @deprecated "Use WeChat.MiniProgram.UserInfo.decode_user_info/3 instead"
  defdelegate decode_user_info(session_key, raw_data, signature), to: UserInfo

  @doc """
  服务端获取开放数据 - 包含敏感数据 -
  [官方文档](https://developers.weixin.qq.com/miniprogram/dev/framework/open-ability/signature.html){:target="_blank"}

  * [小程序登录](https://developers.weixin.qq.com/miniprogram/dev/framework/open-ability/login.html)
  * [加密数据解密算法](https://developers.weixin.qq.com/miniprogram/dev/framework/open-ability/signature.html#加密数据解密算法)
  """
  @deprecated "Use WeChat.MiniProgram.UserInfo.decode_get_user_sensitive_info/3 instead"
  defdelegate decode_get_user_sensitive_info(session_key, encrypted_data, iv), to: UserInfo

  @doc """
  小程序登录

  [登录流程](https://developers.weixin.qq.com/miniprogram/dev/framework/open-ability/login.html)

  官方文档:
    * [小程序](https://developers.weixin.qq.com/miniprogram/dev/OpenApiDoc/user-login/code2Session.html){:target="_blank"}
    * [第三方平台](https://developers.weixin.qq.com/doc/oplatform/openApi/OpenApiDoc/miniprogram-management/login/thirdpartyCode2Session.html){:target="_blank"}
  """
  @spec code2session(WeChat.client(), code :: String.t()) :: WeChat.response()
  def code2session(client, code) do
    if client.by_component?() do
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
    else
      client.get("/sns/jscode2session",
        query: [
          appid: client.appid(),
          secret: client.appsecret(),
          js_code: code,
          grant_type: "authorization_code"
        ]
      )
    end
  end

  @doc """
  检验登录态 -
  [官方文档](https://developers.weixin.qq.com/miniprogram/dev/OpenApiDoc/user-login/checkSessionKey.html){:target="_blank"}

  校验服务器所保存的登录态 session_key 是否合法。为了保持 session_key 私密性，接口不明文传输 session_key，而是通过校验登录态签名完成。
  """
  @spec check_session(WeChat.client(), WeChat.openid(), session_key) :: WeChat.response()
  def check_session(client, openid, session_key) do
    signature = :crypto.mac(:hmac, :sha256, session_key, "") |> Base.encode16()

    client.get("/wxa/checksession",
      query: [
        openid: openid,
        signature: signature,
        sig_method: "hmac_sha256",
        access_token: client.get_access_token()
      ]
    )
  end

  @doc """
  重置登录态 -
  [官方文档](https://developers.weixin.qq.com/miniprogram/dev/OpenApiDoc/user-login/ResetUserSessionKey.html){:target="_blank"}

  重置指定的登录态 session_key。为了保持 session_key 私密性，接口不明文传入 session_key，而是通过校验登录态签名完成。
  """
  @spec reset_session(WeChat.client(), WeChat.openid(), session_key) :: WeChat.response()
  def reset_session(client, openid, session_key) do
    signature = :crypto.mac(:hmac, :sha256, session_key, "") |> Base.encode16()

    client.get("/wxa/resetusersessionkey",
      query: [
        openid: openid,
        signature: signature,
        sig_method: "hmac_sha256",
        access_token: client.get_access_token()
      ]
    )
  end

  @deprecated "Use WeChat.MiniProgram.UserInfo.get_paid_unionid/2 instead"
  defdelegate get_paid_unionid(client, openid), to: UserInfo

  @deprecated "Use WeChat.MiniProgram.UserInfo.get_paid_unionid/3 instead"
  defdelegate get_paid_unionid(client, openid, transaction_id), to: UserInfo

  @deprecated "Use WeChat.MiniProgram.UserInfo.get_paid_unionid/4 instead"
  defdelegate get_paid_unionid(client, openid, mch_id, out_trade_no), to: UserInfo

  @doc """
  获取AccessToken -
  [官方文档](https://developers.weixin.qq.com/miniprogram/dev/OpenApiDoc/mp-access-token/getAccessToken.html){:target="_blank"}
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
