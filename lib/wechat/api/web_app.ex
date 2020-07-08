defmodule WeChat.WebApp do
  @moduledoc """
  网页开发

  ## API Docs
    * [网页授权](https://developers.weixin.qq.com/doc/offiaccount/OA_Web_Apps/Wechat_webpage_authorization.html){:target="_blank"}
    * [JS-SDK](https://developers.weixin.qq.com/doc/offiaccount/OA_Web_Apps/JS-SDK.html){:target="_blank"}
  """
  alias WeChat.{Requester, Utils}

  @typedoc """
  授权范围
    * `"snsapi_base"` - 静默授权
    * `"snsapi_userinfo"` - 用户的基本信息(无须关注)
  """
  @type scope :: String.t()
  @type redirect_uri :: String.t()
  @type code :: String.t()
  @type access_token :: String.t()
  @type refresh_token :: String.t()

  @typedoc """
  JS API的临时票据类型
    * `"jsapi"` - JS-SDK Config
    * `"wx_card"` - 微信卡券
  """
  @type js_api_ticket_type :: String.t()

  @doc_link "#{WeChat.doc_link_prefix()}/offiaccount/OA_Web_Apps"

  @doc """
  请求 CODE

  ## API Docs
    [link](#{@doc_link}/Wechat_webpage_authorization.html#0){:target="_blank"}
  """
  @spec oauth2_authorize_url(WeChat.client(), redirect_uri(), state :: String.t(), scope()) ::
          url :: String.t()
  def oauth2_authorize_url(client, redirect_uri, scope \\ "snsapi_base", state \\ "") do
    "https://open.weixin.qq.com/connect/oauth2/authorize?" <>
      URI.encode_query(
        appid: client.appid(),
        redirect_uri: redirect_uri,
        response_type: "code",
        scope: scope,
        state: state
      ) <> "#wechat_redirect"
  end

  @doc """
  通过code换取网页授权access_token

  ## API Docs
    [link](#{@doc_link}/Wechat_webpage_authorization.html#1){:target="_blank"}
  """
  @spec code2access_token(WeChat.client(), code()) :: WeChat.response()
  def code2access_token(client, code) do
    Requester.get("sns/oauth2/access_token",
      query: [
        appid: client.appid(),
        secret: client.appsecret(),
        code: code,
        grant_type: "authorization_code"
      ]
    )
  end

  @doc """
  刷新access_token

  由于access_token拥有较短的有效期，当access_token超时后，可以使用refresh_token进行刷新，refresh_token有效期为30天，当refresh_token失效之后，需要用户重新授权。

  ## API Docs
    [link](#{@doc_link}/Wechat_webpage_authorization.html#2){:target="_blank"}
  """
  @spec refresh_token(WeChat.client(), refresh_token()) :: WeChat.response()
  def refresh_token(client, refresh_token) do
    Requester.get("sns/oauth2/refresh_token",
      query: [
        appid: client.appid(),
        grant_type: "refresh_token",
        refresh_token: refresh_token
      ]
    )
  end

  @doc """
  拉取用户信息(需scope为 snsapi_userinfo)

  如果网页授权作用域为snsapi_userinfo,则此时开发者可以通过access_token和openid拉取用户信息了.

  ## API Docs
    [link](#{@doc_link}/Wechat_webpage_authorization.html#3){:target="_blank"}
  """
  @spec sns_user_info(WeChat.openid(), access_token()) ::
          WeChat.response()
  def sns_user_info(openid, access_token) do
    Requester.get("/sns/userinfo",
      query: [
        access_token: access_token,
        openid: openid
      ]
    )
  end

  @spec sns_user_info(WeChat.openid(), access_token(), WeChat.lang()) :: WeChat.response()
  def sns_user_info(openid, access_token, lang) do
    Requester.get("/sns/userinfo",
      query: [
        access_token: access_token,
        openid: openid,
        lang: lang
      ]
    )
  end

  @doc """
  检验授权凭证（access_token）是否有效

  ## API Docs
    [link](#{@doc_link}/Wechat_webpage_authorization.html#4){:target="_blank"}
  """
  @spec auth(WeChat.openid(), access_token()) :: WeChat.response()
  def auth(openid, access_token) do
    Requester.get("/sns/auth",
      query: [
        access_token: access_token,
        openid: openid
      ]
    )
  end

  @doc """
  JS-SDK配置

  ## API Docs
    [link](#{@doc_link}/JS-SDK.html#4){:target="_blank"}
  """
  @spec js_sdk_config(WeChat.client(), url :: String.t()) :: WeChat.response()
  def js_sdk_config(client, url) do
    appid = client.appid()

    appid
    |> WeChat.get_cache(:js_api_ticket)
    |> sign_jssdk(url)
    |> Map.put(:appId, appid)
  end

  @spec sign_jssdk(jsapi_ticket :: String.t(), url :: String.t()) :: JSSDKSignature.t()
  def sign_jssdk(jsapi_ticket, url) do
    url = String.replace(url, ~r/\#.*/, "")
    nonce_str = Utils.random_string(16)
    timestamp = Utils.now_unix()

    str_to_sign =
      "jsapi_ticket=#{jsapi_ticket}&noncestr=#{nonce_str}&timestamp=#{timestamp}&url=#{url}"

    signature =
      :crypto.hash(:sha, str_to_sign)
      |> Base.encode16(case: :lower)

    %{signature: signature, timestamp: timestamp, nonceStr: nonce_str}
  end

  @doc """
  微信卡券配置 - 添加卡券

  ## API Docs
    [link](#{@doc_link}/JS-SDK.html#53){:target="_blank"}
  """
  def add_card_config(client, card_id, outer_str) do
    appid = client.appid()

    card_ext =
      appid
      |> WeChat.get_cache(:wx_card_ticket)
      |> sign_card(card_id)
      |> Map.merge(%{appid: client.appid(), outer_str: outer_str})
      |> Jason.encode!()

    %{
      cardId: card_id,
      cardExt: card_ext
    }
  end

  @doc """
  微信卡券配置 - 添加卡券(绑定openid)

  ## API Docs

  * [微信卡券](#{@doc_link}/JS-SDK.html#53){:target="_blank"}
  * [卡券扩展字段及签名生成算法](#{@doc_link}/JS-SDK.html#65){:target="_blank"}
  """
  def add_card_config(client, card_id, outer_str, openid) do
    appid = client.appid()

    card_ext =
      appid
      |> WeChat.get_cache(:wx_card_ticket)
      |> sign_card(card_id, openid)
      |> Map.merge(%{appid: client.appid(), outer_str: outer_str, openid: openid})
      |> Jason.encode!()

    %{
      cardId: card_id,
      cardExt: card_ext
    }
  end

  @doc """
  To initialize WeChat Card functions via JSSDK, use `wxcard_ticket`, `card_id` to generate an signature for this scenario.

  ## API Docs
    [link](#{@doc_link}/JS-SDK.html#65){:target="_blank"}
  """
  @spec sign_card(list :: [String.t()]) :: CardSignature.t()
  @spec sign_card(wxcard_ticket :: String.t(), card_id :: String.t()) :: CardSignature.t()
  @spec sign_card(wxcard_ticket :: String.t(), card_id :: String.t(), openid :: String.t()) ::
          CardSignature.t()
  def sign_card(wxcard_ticket, card_id), do: sign_card([wxcard_ticket, card_id])
  def sign_card(wxcard_ticket, card_id, openid), do: sign_card([wxcard_ticket, card_id, openid])

  def sign_card(list) do
    nonce_str = Utils.random_string(16)
    timestamp = Utils.now_unix()
    timestamp_str = Integer.to_string(timestamp)

    str_to_sign =
      Enum.sort([timestamp_str, nonce_str | list])
      |> Enum.join()

    signature =
      :crypto.hash(:sha, str_to_sign)
      |> Base.encode16(case: :lower)

    %{signature: signature, timestamp: timestamp, nonce_str: nonce_str}
  end

  @doc """
  获取api_ticket

  ## API Docs
    [link](#{@doc_link}/JS-SDK.html#62){:target="_blank"}
  """
  @spec get_ticket(WeChat.client(), js_api_ticket_type) :: WeChat.response()
  def get_ticket(client, type) do
    Requester.get("/cgi-bin/ticket/getticket",
      query: [type: type, access_token: WeChat.get_cache(client.appid(), :access_token)]
    )
  end
end
