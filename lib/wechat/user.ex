defmodule WeChat.User do
  @moduledoc "用户管理"
  import Jason.Helpers
  alias WeChat.Requester

  @doc_link "#{WeChat.doc_link_prefix()}/offiaccount/User_Management"

  @typedoc """
  国家地区语言
    * `"zh_CN"` - 简体
    * `"zh_TW"` - 繁体
    * `"en"` - 英语
  """
  @type lang :: String.t()

  @doc """
  设置用户备注名

  ## API Docs
    [link](#{@doc_link}/Configuring_user_notes.html){:target="_blank"}
  """
  @spec update_remark(WeChat.client(), WeChat.openid(), remark :: String.t()) :: WeChat.response()
  def update_remark(client, openid, remark) do
    Requester.post(
      "/cgi-bin/user/info/updateremark",
      json_map(openid: openid, remark: remark),
      query: [access_token: WeChat.get_cache(client.appid(), :access_token)]
    )
  end

  @doc """
  获取用户基本信息(UnionID机制)

  ## API Docs
    [link](#{@doc_link}/Get_users_basic_information_UnionID.html#UinonId){:target="_blank"}
  """
  @spec user_info(WeChat.client(), WeChat.openid()) :: WeChat.response()
  def user_info(client, openid) do
    Requester.get("/cgi-bin/user/info",
      query: [
        openid: openid,
        access_token: WeChat.get_cache(client.appid(), :access_token)
      ]
    )
  end

  @doc """
  获取用户基本信息(UnionID机制)

  ## API Docs
    [link](#{@doc_link}/Get_users_basic_information_UnionID.html#UinonId){:target="_blank"}
  """
  @spec user_info(WeChat.client(), WeChat.openid(), lang) :: WeChat.response()
  def user_info(client, openid, lang) do
    Requester.get("/cgi-bin/user/info",
      query: [
        openid: openid,
        lang: lang,
        access_token: WeChat.get_cache(client.appid(), :access_token)
      ]
    )
  end

  @doc """
  批量获取用户基本信息

  ## API Docs
    [link](#{@doc_link}/Get_users_basic_information_UnionID.html){:target="_blank"}
  """
  @spec batch_get_user_info(WeChat.client(), [map]) :: WeChat.response()
  def batch_get_user_info(client, user_list) do
    Requester.post(
      "/cgi-bin/user/info/batchget",
      json_map(user_list: user_list),
      query: [access_token: WeChat.get_cache(client.appid(), :access_token)]
    )
  end

  @doc """
  通过code换取网页授权access_token

  ## API Docs
    [link](#{WeChat.doc_link_prefix()}/offiaccount/OA_Web_Apps/Wechat_webpage_authorization.html#1)
  """
  @spec code2access_token(WeChat.client(), code :: String.t()) :: WeChat.response()
  def code2access_token(client, code) do
    appid = client.appid()

    Requester.get("/sns/oauth2/access_token",
      query: [
        appid: appid,
        secret: client.appsecret(),
        grant_type: "authorization_code",
        code: code,
        access_token: WeChat.get_cache(client.appid(), :access_token)
      ]
    )
  end

  @doc """
  刷新access_token

  ## API Docs
    [link](#{WeChat.doc_link_prefix()}/offiaccount/OA_Web_Apps/Wechat_webpage_authorization.html#2)
  """
  @spec refresh_token(WeChat.client(), refresh_token :: String.t()) :: WeChat.response()
  def refresh_token(client, refresh_token) do
    Requester.get("/sns/oauth2/refresh_token",
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
    [link](#{WeChat.doc_link_prefix()}/offiaccount/OA_Web_Apps/Wechat_webpage_authorization.html#3){:target="_blank"}
  """
  @spec sns_user_info(WeChat.openid(), access_token :: String.t()) ::
          WeChat.response()
  def sns_user_info(openid, access_token) do
    Requester.get("/sns/userinfo",
      query: [
        access_token: access_token,
        openid: openid
      ]
    )
  end

  @doc """
  检验授权凭证（access_token）是否有效

  ## API Docs
    [link](#{WeChat.doc_link_prefix()}/offiaccount/OA_Web_Apps/Wechat_webpage_authorization.html#4){:target="_blank"}
  """
  @spec auth(WeChat.openid(), access_token :: String.t()) :: WeChat.response()
  def auth(openid, access_token) do
    Requester.get("/sns/auth",
      query: [
        access_token: access_token,
        openid: openid
      ]
    )
  end

  @doc """
  获取用户列表

  ## API Docs
    [link](#{@doc_link}/Getting_a_User_List.html){:target="_blank"}
  """
  @spec get_users(WeChat.client()) :: WeChat.response()
  def get_users(client) do
    Requester.get("/cgi-bin/user/get",
      query: [access_token: WeChat.get_cache(client.appid(), :access_token)]
    )
  end

  @doc """
  获取用户列表

  ## API Docs
    [link](#{@doc_link}/Getting_a_User_List.html){:target="_blank"}
  """
  @spec get_users(WeChat.client(), WeChat.openid()) :: WeChat.response()
  def get_users(client, next_openid) do
    Requester.get("/cgi-bin/user/get",
      query: [
        next_openid: next_openid,
        access_token: WeChat.get_cache(client.appid(), :access_token)
      ]
    )
  end
end
