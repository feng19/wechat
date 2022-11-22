defmodule WeChat.Component do
  @moduledoc """
  第三方平台

  [官方文档](https://developers.weixin.qq.com/doc/oplatform/Third-party_Platforms/Third_party_platform_appid.html){:target="_blank"}
  """
  import Jason.Helpers
  import WeChat.Utils, only: [doc_link_prefix: 0]
  alias WeChat.Storage.Cache

  @typedoc """
  要授权的帐号类型:

  1. 则商户点击链接后，手机端仅展示公众号;
  2. 表示仅展示小程序;
  3. 表示公众号和小程序都展示。如果为未指定，则默认小程序和公众号都展示.

  第三方平台开发者可以使用本字段来控制授权的帐号类型.
  """
  @type auth_type :: 1 | 2 | 3
  @type biz_appid :: WeChat.appid()

  @doc_link "#{doc_link_prefix()}/doc/oplatform/Third-party_Platforms/api"

  @typedoc """
  选项名称及可选值说明 -
  [官方文档](#{@doc_link}/api_get_authorizer_option.html#选项名称及可选值说明){:target="_blank"}

  |   option_name    |   选项名说明    | option_value | 选项值说明 |
  | ---------------- | ------------  | ------------ | -------- |
  | location_report  | 地理位置上报选项 |       0      | 无上报    |
  | location_report  | 地理位置上报选项 |       1      | 进入会话时上报 |
  | location_report  | 地理位置上报选项 |       2      | 每 5s 上报 |
  | voice_recognize  | 语音识别开关选项 |       0      | 关闭语音识别 |
  | voice_recognize  | 语音识别开关选项 |       1      | 开启语音识别 |
  | customer_service | 多客服开关选项   |       0      | 关闭多客服 |
  | customer_service | 多客服开关选项   |       1      | 开启多客服 |
  """
  @type option_name :: String.t()

  @doc """
  生成授权链接 -
  [官方文档](#{doc_link_prefix()}/doc/oplatform/Third-party_Platforms/Authorization_Process_Technical_Description.html){:target="_blank"}
  """
  @spec bind_component_url(WeChat.client(), redirect_uri :: String.t(), auth_type() | biz_appid()) ::
          url :: String.t() | WeChat.response()
  def bind_component_url(client, redirect_uri, auth_type_or_biz_appid) do
    with {:ok, %{status: 200, body: %{"pre_auth_code" => pre_auth_code}}} <-
           create_pre_auth_code(client) do
      item =
        case auth_type_or_biz_appid do
          auth_type when is_integer(auth_type) and auth_type in 1..3 ->
            {:auth_type, auth_type}

          biz_appid when is_binary(biz_appid) ->
            {:biz_appid, biz_appid}
        end

      query =
        URI.encode_query([
          item
          | [
              action: "bindcomponent",
              no_scan: 1,
              component_appid: client.component_appid(),
              pre_auth_code: pre_auth_code,
              redirect_uri: redirect_uri
            ]
        ])

      "https://mp.weixin.qq.com/safe/bindcomponent?" <> query <> "#wechat_redirect"
    end
  end

  @doc """
  查询接口调用次数 -
  [官方文档](#{doc_link_prefix()}/doc/oplatform/Third-party_Platforms/2.0/api/openApi/get_api_quota.html){:target="_blank"}

  [接口调用频次限制说明](#{doc_link_prefix()}/doc/offiaccount/Message_Management/API_Call_Limits.html){:target="_blank"}
  """
  @spec get_quota(WeChat.client, cgi_path :: String.t()) :: WeChat.response()
  def get_quota(client, cgi_path) do
    component_appid = client.component_appid()

    client.post("/cgi-bin/openapi/quota/get", json_map(cgi_path: cgi_path),
      query: [access_token: get_access_token(component_appid)]
    )
  end

  @doc """
  接口调用次数清零 -
  [官方文档](#{doc_link_prefix()}/doc/oplatform/Third-party_Platforms/2.0/api/openApi/clear_quota.html){:target="_blank"}

  [接口调用频次限制说明](#{doc_link_prefix()}/doc/offiaccount/Message_Management/API_Call_Limits.html){:target="_blank"}
  """
  @spec clear_quota(WeChat.client()) :: WeChat.response()
  def clear_quota(client) do
    component_appid = client.component_appid()

    client.post(
      "/cgi-bin/component/clear_quota",
      json_map(appid: component_appid),
      query: [access_token: get_access_token(component_appid)]
    )
  end

  @doc """
  获取令牌 -
  [官方文档](#{@doc_link}/component_access_token.html){:target="_blank"}
  """
  @spec get_component_token(WeChat.client()) :: WeChat.response()
  def get_component_token(client) do
    client.component_appid()
    |> Cache.get_cache(:component_verify_ticket)
    |> case do
      nil -> {:error, :missing_component_verify_ticket}
      ticket -> get_component_token(client, ticket)
    end
  end

  @doc """
  获取令牌 -
  [官方文档](#{@doc_link}/component_access_token.html){:target="_blank"}

  ## ticket 来源
    [验证票据](#{doc_link_prefix()}/doc/oplatform/Third-party_Platforms/api/component_verify_ticket.html)
  """
  @spec get_component_token(WeChat.client(), ticket :: String.t()) :: WeChat.response()
  def get_component_token(client, ticket) do
    client.post(
      "/cgi-bin/component/api_component_token",
      json_map(
        component_appid: client.component_appid(),
        component_appsecret: client.component_appsecret(),
        component_verify_ticket: ticket
      )
    )
  end

  @doc """
  获取预授权码 -
  [官方文档](#{@doc_link}/pre_auth_code.html){:target="_blank"}
  """
  @spec create_pre_auth_code(WeChat.client()) :: WeChat.response()
  def create_pre_auth_code(client) do
    component_appid = client.component_appid()

    client.post(
      "/cgi-bin/component/api_create_preauthcode",
      json_map(component_appid: component_appid),
      query: [component_access_token: get_access_token(component_appid)]
    )
  end

  @doc """
  使用授权码获取授权信息 -
  [官方文档](#{@doc_link}/authorization_info.html){:target="_blank"}
  """
  @spec query_auth(WeChat.client(), authorization_code :: String.t()) :: WeChat.response()
  def query_auth(client, authorization_code) do
    component_appid = client.component_appid()

    client.post(
      "/cgi-bin/component/api_query_auth",
      json_map(
        component_appid: component_appid,
        authorization_code: authorization_code
      ),
      query: [component_access_token: get_access_token(component_appid)]
    )
  end

  @doc """
  获取/刷新接口调用令牌 -
  [官方文档](#{@doc_link}/api_authorizer_token.html){:target="_blank"}
  """
  @spec authorizer_token(WeChat.client()) :: nil | WeChat.response()
  def authorizer_token(client) do
    appid = client.appid()

    with authorizer_refresh_token when authorizer_refresh_token != nil <-
           Cache.get_cache(appid, :authorizer_refresh_token) do
      component_appid = client.component_appid()

      client.post(
        "/cgi-bin/component/api_authorizer_token",
        json_map(
          component_appid: component_appid,
          authorizer_appid: appid,
          authorizer_refresh_token: authorizer_refresh_token
        ),
        query: [component_access_token: get_access_token(component_appid)]
      )
    end
  end

  @doc """
  获取授权方的帐号基本信息 -
  [官方文档](#{@doc_link}/api_get_authorizer_info.html){:target="_blank"}
  """
  @spec get_authorizer_info(WeChat.client()) :: WeChat.response()
  def get_authorizer_info(client) do
    component_appid = client.component_appid()

    client.post(
      "/cgi-bin/component/api_get_authorizer_info",
      json_map(component_appid: component_appid, authorizer_appid: client.appid()),
      query: [component_access_token: get_access_token(component_appid)]
    )
  end

  @doc """
  获取授权方选项信息 -
  [官方文档](#{@doc_link}/api_get_authorizer_option.html){:target="_blank"}
  """
  @spec get_authorizer_option(WeChat.client(), option_name) :: WeChat.response()
  def get_authorizer_option(client, option_name) do
    component_appid = client.component_appid()

    client.post(
      "/cgi-bin/component/api_get_authorizer_option",
      json_map(
        component_appid: component_appid,
        authorizer_appid: client.appid(),
        option_name: option_name
      ),
      query: [component_access_token: get_access_token(component_appid)]
    )
  end

  @doc """
  拉取所有已授权的帐号信息 -
  [官方文档](#{@doc_link}/api_get_authorizer_list.html){:target="_blank"}
  """
  @spec get_authorizer_list(WeChat.client(), offset :: integer, count :: integer) ::
          WeChat.response()
  def get_authorizer_list(client, offset, count) when count <= 500 do
    component_appid = client.component_appid()

    client.post(
      "/cgi-bin/component/api_get_authorizer_list",
      json_map(component_appid: component_appid, offset: offset, count: count),
      query: [component_access_token: get_access_token(component_appid)]
    )
  end

  @doc """
  创建开放平台帐号并绑定公众号/小程序 -
  [官方文档](#{@doc_link}/account/create.html){:target="_blank"}

  该 API 用于创建一个开放平台帐号，并将一个尚未绑定开放平台帐号的公众号/小程序绑定至该开放平台帐号上。

  新创建的开放平台帐号的主体信息将设置为与之绑定的公众号或小程序的主体。
  """
  @spec create(WeChat.client(), WeChat.appid()) :: WeChat.response()
  def create(client, appid) do
    client.post(
      "/cgi-bin/open/create",
      json_map(appid: appid),
      query: [access_token: client.get_access_token()]
    )
  end

  @doc """
  将公众号/小程序绑定到开放平台帐号下 -
  [官方文档](#{@doc_link}/account/bind.html){:target="_blank"}

  该 API 用于将一个尚未绑定开放平台帐号的公众号或小程序绑定至指定开放平台帐号上。

  二者须主体相同。
  """
  @spec create(WeChat.client(), WeChat.appid(), WeChat.appid()) :: WeChat.response()
  def create(client, appid, open_appid) do
    client.post(
      "/cgi-bin/open/bind",
      json_map(appid: appid, open_appid: open_appid),
      query: [access_token: client.get_access_token()]
    )
  end

  @doc """
  将公众号/小程序从开放平台帐号下解绑 -
  [官方文档](#{@doc_link}/account/unbind.html){:target="_blank"}

  该 API 用于将一个公众号或小程序与指定开放平台帐号解绑。

  开发者须确认所指定帐号与当前该公众号或小程序所绑定的开放平台帐号一致。
  """
  @spec unbind(WeChat.client(), WeChat.appid(), WeChat.appid()) :: WeChat.response()
  def unbind(client, appid, open_appid) do
    client.post(
      "/cgi-bin/open/unbind",
      json_map(appid: appid, open_appid: open_appid),
      query: [access_token: client.get_access_token()]
    )
  end

  @doc """
  获取公众号/小程序所绑定的开放平台帐号 -
  [官方文档](#{@doc_link}/account/get.html){:target="_blank"}

  该 API 用于获取公众号或小程序所绑定的开放平台帐号。
  """
  @spec get(WeChat.client(), WeChat.appid()) :: WeChat.response()
  def get(client, appid) do
    client.post(
      "/cgi-bin/open/get",
      json_map(appid: appid),
      query: [access_token: client.get_access_token()]
    )
  end

  def get_access_token(component_appid),
    do: Cache.get_cache(component_appid, :component_access_token)
end
