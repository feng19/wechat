defmodule WeChat.User do
  @moduledoc "用户管理"
  import Jason.Helpers
  alias WeChat.Requester

  @doc_link "#{WeChat.doc_link_prefix()}/offiaccount/User_Management"

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
  @spec user_info(WeChat.client(), WeChat.openid(), WeChat.lang()) :: WeChat.response()
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
