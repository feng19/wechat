defmodule WeChat.Account do
  @moduledoc "账号管理"
  import Jason.Helpers
  import WeChat.Utils, only: [doc_link_prefix: 0]

  @typedoc """
  二维码类型
    * `"QR_SCENE"`            为临时的整型参数值
    * `"QR_STR_SCENE"`        为临时的字符串参数值
    * `"QR_LIMIT_SCENE"`      为永久的整型参数值
    * `"QR_LIMIT_STR_SCENE"`  为永久的字符串参数值
  """
  @type qrcode_action_name :: String.t()

  @doc """
  获取AccessToken -
  [Official API Docs Link](#{doc_link_prefix()}/doc/offiaccount/Basic_Information/Get_access_token.html){:target="_blank"}
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

  @doc """
  生成二维码 -
  [Official API Docs Link](#{doc_link_prefix()}/doc/offiaccount/Account_Management/Generating_a_Parametric_QR_Code.html){:target="_blank"}
  """
  @spec create_qrcode(
          WeChat.client(),
          scene_id :: String.t(),
          qrcode_action_name,
          expire_seconds :: integer
        ) :: WeChat.response()
  def create_qrcode(client, scene_id, action_name \\ "QR_LIMIT_SCENE", expire_seconds \\ 1800)
      when action_name in [
             "QR_SCENE",
             "QR_STR_SCENE",
             "QR_LIMIT_SCENE",
             "QR_LIMIT_STR_SCENE"
           ] do
    scene_key = (action_name in ["QR_STR_SCENE", "QR_LIMIT_STR_SCENE"] && :scene_str) || :scene_id

    client.post(
      "/cgi-bin/qrcode/create",
      json_map(
        action_name: action_name,
        expire_seconds: expire_seconds,
        action_info: %{
          scene: %{scene_key => scene_id}
        }
      ),
      query: [access_token: client.get_access_token()]
    )
  end

  @doc """
  生成并获取二维码链接 -
  [Official API Docs Link](#{doc_link_prefix()}/doc/offiaccount/Account_Management/Generating_a_Parametric_QR_Code.html){:target="_blank"}
  """
  @spec get_qrcode_url(
          WeChat.client(),
          scene_id :: String.t(),
          qrcode_action_name,
          expire_seconds :: integer
        ) :: WeChat.response() | {:ok, url :: String.t()}
  def get_qrcode_url(client, scene_id, action_name \\ "QR_LIMIT_SCENE", expire_seconds \\ 1800) do
    with {:ok, %{status: 200, body: %{"ticket" => ticket}}} <-
           create_qrcode(client, scene_id, action_name, expire_seconds) do
      {:ok, "https://mp.weixin.qq.com/cgi-bin/showqrcode?ticket=#{ticket}"}
    end
  end

  @doc """
  生成并下载二维码 -
  [Official API Docs Link](#{doc_link_prefix()}/doc/offiaccount/Account_Management/Generating_a_Parametric_QR_Code.html){:target="_blank"}
  """
  @spec download_qrcode(
          WeChat.client(),
          scene_id :: String.t(),
          qrcode_action_name,
          expire_seconds :: integer,
          dir_name :: Path.t()
        ) :: WeChat.response() | {Collectable.t(), exit_status :: non_neg_integer}
  def download_qrcode(
        client,
        scene_id,
        action_name \\ "QR_LIMIT_SCENE",
        expire_seconds \\ 1800,
        dir_name \\ "."
      ) do
    File.mkdir_p!(dir_name)

    with {:ok, url} <- get_qrcode_url(client, scene_id, action_name, expire_seconds) do
      System.cmd("wget", ["-qO", "#{scene_id}.jpg", url], cd: dir_name)
    end
  end

  @doc """
  长链接转成短链接 -
  [Official API Docs Link](#{doc_link_prefix()}/doc/offiaccount/Account_Management/URL_Shortener.html){:target="_blank"}
  """
  @spec short_url(WeChat.client(), long_url :: String.t()) :: WeChat.response()
  def short_url(client, long_url) do
    client.get(
      "/cgi-bin/shorturl",
      json_map(action: "long2short", long_url: long_url),
      query: [access_token: client.get_access_token()]
    )
  end

  @doc """
  接口调用次数清零 -
  [Official API Docs Link](#{doc_link_prefix()}/doc/offiaccount/Message_Management/API_Call_Limits.html){:target="_blank"}
  """
  @spec clear_quota(WeChat.client()) :: WeChat.response()
  def clear_quota(client) do
    client.post("/cgi-bin/clear_quota", json_map(appid: client.appid()),
      query: [access_token: client.get_access_token()]
    )
  end

  @doc """
  获取公众号的自动回复规则 -
  [Official API Docs Link](#{doc_link_prefix()}/doc/offiaccount/Message_Management/Getting_Rules_for_Auto_Replies.html){:target="_blank"}

  获取公众号当前使用的自动回复规则，包括关注后自动回复、消息自动回复（60分钟内触发一次）、关键词自动回复。

  请注意：

  - 第三方平台开发者可以通过本接口，在旗下公众号将业务授权给你后，立即通过本接口检测公众号的自动回复配置。
  - 本接口仅能获取公众号在公众平台官网的自动回复功能中设置的自动回复规则，若公众号自行开发实现自动回复，或通过第三方平台开发者来实现，则无法获取。
  - 认证/未认证的服务号/订阅号，以及接口测试号，均拥有该接口权限。
  - 从第三方平台的公众号登录授权机制上来说，该接口从属于消息与菜单权限集。
  - 本接口中返回的图片/语音/视频为临时素材（临时素材每次获取都不同，3天内有效，通过素材管理-获取临时素材接口来获取这些素材），
  本接口返回的图文消息为永久素材素材（通过素材管理-获取永久素材接口来获取这些素材）。
  """
  @spec get_auto_reply_rules(WeChat.client()) :: WeChat.response()
  def get_auto_reply_rules(client) do
    client.get("/cgi-bin/get_current_autoreply_info",
      query: [access_token: client.get_access_token()]
    )
  end
end
