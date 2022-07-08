defmodule WeChat.WebPage do
  @moduledoc """
  网页开发

  ## API Docs
    * [网页授权](https://developers.weixin.qq.com/doc/offiaccount/OA_Web_Apps/Wechat_webpage_authorization.html){:target="_blank"}
    * [JS-SDK](https://developers.weixin.qq.com/doc/offiaccount/OA_Web_Apps/JS-SDK.html){:target="_blank"}
  """
  import WeChat.Utils, only: [doc_link_prefix: 0]
  alias WeChat.{Requester, Utils, Card, User, Storage.Cache}

  @typedoc """
  授权范围
    * `"snsapi_base"` - 静默授权
    * `"snsapi_userinfo"` - 用户的基本信息(无须关注)
  """
  @type scope :: String.t()
  @typedoc "重定向后会带上state参数，开发者可以填写a-zA-Z0-9的参数值，最多128字节"
  @type state :: String.t()
  @typedoc "授权后重定向的回调链接地址， 请使用 urlEncode 对链接进行处理"
  @type redirect_uri :: String.t()
  @type code :: String.t()
  @type access_token :: String.t()
  @type refresh_token :: String.t()
  @type ticket :: String.t()
  @type wx_card_ticket :: ticket
  @type js_api_ticket :: ticket
  @type url :: String.t()
  @type signature :: String.t()
  @type timestamp :: non_neg_integer
  @type nonce_str :: String.t()
  @type js_sdk_config :: %{
          appId: WeChat.appid(),
          signature: signature,
          timestamp: timestamp,
          nonceStr: nonce_str
        }
  @type card_ext :: String.t()
  @type card_config :: %{cardId: Card.card_id(), cardExt: card_ext}

  @typedoc """
  JS API的临时票据类型
    * `"jsapi"` - JS-SDK Config
    * `"wx_card"` - 微信卡券
  """
  @type js_api_ticket_type :: String.t()

  @doc_link "#{doc_link_prefix()}/doc/offiaccount/OA_Web_Apps"
  @component_doc_link "#{doc_link_prefix()}/doc/oplatform/Third-party_Platforms/Official_Accounts/official_account_website_authorization.html"

  @doc """
  网页授权 - 请求`code`

  官方文档:
  * [Official Account](#{@doc_link}/Wechat_webpage_authorization.html#0){:target="_blank"}
  * [Component](#{@component_doc_link}){:target="_blank"}

  关于网页授权回调域名的说明

  - 在微信公众号请求用户网页授权之前，开发者需要先到公众平台官网中的 “`开发` - `接口权限` - `网页服务` - `网页帐号` - `网页授权获取用户基本信息`” 的配置选项中，
  修改授权回调域名。请注意，这里填写的是域名（是一个字符串），而不是URL，因此请勿加 `http://` 等协议头；
  - 授权回调域名配置规范为全域名，比如需要网页授权的域名为：`www.qq.com`，配置以后此域名下面的页面 `http://www.qq.com/music.html`、
  `http://www.qq.com/login.html` 都可以进行 `OAuth2.0` 鉴权。但 `http://pay.qq.com`、`http://music.qq.com` 、 `http://qq.com`
  无法进行 `OAuth2.0` 鉴权
  - 如果公众号登录授权给了第三方开发者来进行管理，则不必做任何设置，由第三方代替公众号实现网页授权即可
  """
  @spec oauth2_authorize_url(WeChat.client(), redirect_uri, scope, state) :: url
  def oauth2_authorize_url(client, redirect_uri, scope \\ "snsapi_base", state \\ "") do
    [
      "https://open.weixin.qq.com/connect/oauth2/authorize?",
      ["appid=", client.appid()],
      ["&redirect_uri=", URI.encode_www_form(redirect_uri)],
      "&response_type=code",
      ["&scope=", scope],
      if match?("", state) do
        []
      else
        ["&state=", state]
      end,
      if client.by_component?() do
        ["&component_appid=", client.component_appid(), "#wechat_redirect"]
      else
        "#wechat_redirect"
      end
    ]
    |> IO.iodata_to_binary()
  end

  @doc """
  网页授权 - 通过`code`换取`access_token`

  官方文档:
    * [Official Account](#{@doc_link}/Wechat_webpage_authorization.html#1){:target="_blank"}
    * [Component](#{@component_doc_link}){:target="_blank"}
  """
  @spec code2access_token(WeChat.client(), code) :: WeChat.response()
  def code2access_token(client, code) do
    if client.by_component?() do
      component_appid = client.component_appid()

      client.get(
        "/sns/oauth2/component/access_token",
        query: [
          appid: client.appid(),
          code: code,
          grant_type: "authorization_code",
          component_appid: component_appid,
          component_access_token: Cache.get_cache(component_appid, :component_access_token)
        ]
      )
    else
      client.get("/sns/oauth2/access_token",
        query: [
          appid: client.appid(),
          secret: client.appsecret(),
          code: code,
          grant_type: "authorization_code"
        ]
      )
    end
  end

  @doc """
  网页授权 - 刷新`access_token`

  由于`access_token`拥有较短的有效期，当`access_token`超时后，可以使用`refresh_token`进行刷新，

  `refresh_token`有效期为30天，当`refresh_token`失效之后，需要用户重新授权。

  官方文档:
    * [Official Account](#{@doc_link}/Wechat_webpage_authorization.html#2){:target="_blank"}
    * [Component](#{@component_doc_link}){:target="_blank"}
  """
  @spec refresh_token(WeChat.client(), refresh_token) :: WeChat.response()
  def refresh_token(client, refresh_token) do
    if client.by_component?() do
      component_appid = client.component_appid()

      client.get("/sns/oauth2/component/refresh_token",
        query: [
          appid: client.appid(),
          grant_type: "refresh_token",
          refresh_token: refresh_token,
          component_appid: component_appid,
          component_access_token: Cache.get_cache(component_appid, :component_access_token)
        ]
      )
    else
      client.get("/sns/oauth2/refresh_token",
        query: [
          appid: client.appid(),
          grant_type: "refresh_token",
          refresh_token: refresh_token
        ]
      )
    end
  end

  @doc """
  网页授权 - 拉取用户信息(需`scope`为`snsapi_userinfo`) -
  [官方文档](#{@doc_link}/Wechat_webpage_authorization.html#3){:target="_blank"}

  如果网页授权作用域为`snsapi_userinfo`,则此时开发者可以通过access_token和openid拉取用户信息了.
  """
  @spec user_info(WeChat.openid(), access_token) :: WeChat.response()
  def user_info(openid, access_token) do
    Requester.OfficialAccount.get("/sns/userinfo",
      query: [access_token: access_token, openid: openid]
    )
  end

  @doc "See `user_info/2`"
  @spec user_info(WeChat.requester(), WeChat.openid(), access_token) :: WeChat.response()
  def user_info(requester, openid, access_token) when is_atom(requester) do
    requester.get("/sns/userinfo",
      query: [access_token: access_token, openid: openid]
    )
  end

  @spec user_info(WeChat.openid(), access_token, User.lang()) :: WeChat.response()
  def user_info(openid, access_token, lang) do
    Requester.OfficialAccount.get("/sns/userinfo",
      query: [
        access_token: access_token,
        openid: openid,
        lang: lang
      ]
    )
  end

  @doc "See `user_info/2`"
  @spec user_info(WeChat.requester(), WeChat.openid(), access_token, User.lang()) ::
          WeChat.response()
  def user_info(requester, openid, access_token, lang) do
    requester.get("/sns/userinfo",
      query: [
        access_token: access_token,
        openid: openid,
        lang: lang
      ]
    )
  end

  @doc """
  网页授权 - 检验授权凭证(`access_token`)是否有效 -
  [官方文档](#{@doc_link}/Wechat_webpage_authorization.html#4){:target="_blank"}
  """
  @spec auth(WeChat.openid(), access_token) :: WeChat.response()
  def auth(requester \\ Requester.OfficialAccount, openid, access_token) do
    requester.get("/sns/auth",
      query: [access_token: access_token, openid: openid]
    )
  end

  @doc """
  生成 JS-SDK 配置 -
  [官方文档](#{@doc_link}/JS-SDK.html#4){:target="_blank"}

  返回 `maps` 包含: `appId/signature/timestamp/nonceStr`
  """
  @spec js_sdk_config(WeChat.client(), url) :: js_sdk_config
  def js_sdk_config(client, url) do
    appid = client.appid()

    appid
    |> Cache.get_cache(:js_api_ticket)
    |> sign_js_sdk(url, appid)
  end

  @doc """
  生成 JS-SDK 配置(by ticket) -
  [官方文档](#{@doc_link}/JS-SDK.html#4){:target="_blank"}

  返回 `maps` 包含: `appId/signature/timestamp/nonceStr`
  """
  @spec sign_js_sdk(js_api_ticket, url, WeChat.appid()) :: js_sdk_config
  def sign_js_sdk(jsapi_ticket, url, appid) do
    url = String.replace(url, ~r/\#.*/, "")
    nonce_str = Utils.random_string(16)
    timestamp = Utils.now_unix()

    signature =
      Utils.sha1(
        "jsapi_ticket=#{jsapi_ticket}&noncestr=#{nonce_str}&timestamp=#{timestamp}&url=#{url}"
      )

    %{appId: appid, signature: signature, timestamp: timestamp, nonceStr: nonce_str}
  end

  @doc """
  生成微信卡券配置 - 添加卡券

  ## API Docs
    * [微信卡券](#{@doc_link}/JS-SDK.html#53){:target="_blank"}
    * [卡券扩展字段及签名生成算法](#{@doc_link}/JS-SDK.html#65){:target="_blank"}
  """
  @spec add_card_config(WeChat.client(), Card.card_id(), outer_str :: String.t()) :: card_config
  def add_card_config(client, card_id, outer_str) do
    appid = client.appid()

    card_ext =
      appid
      |> Cache.get_cache(:wx_card_ticket)
      |> sign_card(card_id)
      |> Map.merge(%{appid: client.appid(), outer_str: outer_str})
      |> Jason.encode!()

    %{cardId: card_id, cardExt: card_ext}
  end

  @doc """
  生成微信卡券配置 - 添加卡券(绑定`openid`)

  ## API Docs
    * [微信卡券](#{@doc_link}/JS-SDK.html#53){:target="_blank"}
    * [卡券扩展字段及签名生成算法](#{@doc_link}/JS-SDK.html#65){:target="_blank"}
  """
  @spec add_card_config(WeChat.client(), Card.card_id(), outer_str :: String.t(), WeChat.openid()) ::
          map
  def add_card_config(client, card_id, outer_str, openid) do
    appid = client.appid()

    card_ext =
      appid
      |> Cache.get_cache(:wx_card_ticket)
      |> sign_card(card_id, openid)
      |> Map.merge(%{appid: client.appid(), outer_str: outer_str, openid: openid})
      |> Jason.encode!()

    %{cardId: card_id, cardExt: card_ext}
  end

  @doc "See `sign_card/1`"
  @spec sign_card(wx_card_ticket, Card.card_id()) :: map
  def sign_card(wx_card_ticket, card_id), do: sign_card([wx_card_ticket, card_id])

  @doc "See `sign_card/1`"
  @spec sign_card(wx_card_ticket, Card.card_id(), WeChat.openid()) :: map
  def sign_card(wx_card_ticket, card_id, openid), do: sign_card([wx_card_ticket, card_id, openid])

  @doc """
  卡券签名 -
  [官方文档](#{@doc_link}/JS-SDK.html#65){:target="_blank"}
  """
  @compile {:inline, sign_card: 1}
  @spec sign_card(list :: [String.t()]) :: map
  def sign_card(list) do
    nonce_str = Utils.random_string(16)
    timestamp = Utils.now_unix()
    timestamp_str = Integer.to_string(timestamp)
    signature = Utils.sha1([timestamp_str, nonce_str | list])

    %{signature: signature, timestamp: timestamp, nonce_str: nonce_str}
  end

  @doc """
  获取`api_ticket` -
  [官方文档](#{@doc_link}/JS-SDK.html#62){:target="_blank"}
  """
  @spec get_ticket(WeChat.client(), js_api_ticket_type) :: WeChat.response()
  def get_ticket(client, type) do
    client.get("/cgi-bin/ticket/getticket",
      query: [type: type, access_token: client.get_access_token()]
    )
  end
end
