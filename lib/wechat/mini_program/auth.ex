defmodule WeChat.MiniProgram.Auth do
  @moduledoc """
  权限接口
  """
  alias WeChat.Requester

  @doc_link "https://developers.weixin.qq.com/miniprogram/dev/api-backend/open-api"

  @doc """
  登录 - [Official API Docs Link](#{@doc_link}/login/auth.code2Session.html){:target="_blank"}
  """
  @spec code2session(WeChat.client(), code :: String.t()) :: WeChat.response()
  def code2session(client, code) do
    Requester.get("/sns/jscode2session",
      query: [
        appid: client.appid(),
        secret: client.appsecret(),
        js_code: code,
        grant_type: "authorization_code"
      ]
    )
  end

  @doc """
  支付后获取用户的`UnionId` - [Official API Docs Link](#{@doc_link}/user-info/auth.getPaidUnionId.html){:target="_blank"}

  用户支付完成后，获取该用户的`UnionId`，无需用户授权.

  本接口支持第三方平台代理查询.

  **注意：调用前需要用户完成支付，且在支付后的五分钟内有效**
  """
  @spec get_paid_unionid(WeChat.client(), WeChat.openid()) :: WeChat.response()
  def get_paid_unionid(client, openid) do
    Requester.get("/wxa/getpaidunionid",
      query: [
        openid: openid,
        access_token: WeChat.get_cache(client.appid(), :access_token)
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
    Requester.get("/wxa/getpaidunionid",
      query: [
        openid: openid,
        transaction_id: transaction_id,
        access_token: WeChat.get_cache(client.appid(), :access_token)
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
        ) ::
          WeChat.response()
  def get_paid_unionid(client, openid, mch_id, out_trade_no) do
    Requester.get("/wxa/getpaidunionid",
      query: [
        openid: openid,
        mch_id: mch_id,
        out_trade_no: out_trade_no,
        access_token: WeChat.get_cache(client.appid(), :access_token)
      ]
    )
  end

  @doc """
  获取AccessToken - [Official API Docs Link](#{@doc_link}/access-token/auth.getAccessToken.html){:target="_blank"}
  """
  def get_access_token(client) do
    Requester.get("/cgi-bin/token",
      query: [
        grant_type: "client_credential",
        appid: client.appid(),
        secret: client.appsecret()
      ]
    )
  end
end
