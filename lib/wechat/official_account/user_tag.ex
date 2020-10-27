defmodule WeChat.UserTag do
  @moduledoc """
  标签管理

  [API Docs Link](https://developers.weixin.qq.com/doc/offiaccount/User_Management/User_Tag_Management.html){:target="_blank"}
  """
  import Jason.Helpers
  import WeChat.Utils, only: [doc_link_prefix: 0]
  alias WeChat.Requester

  @type tag_id :: integer
  @type tag_name :: String.t()

  @doc_link "#{doc_link_prefix()}/doc/offiaccount/User_Management/User_Tag_Management.html"

  @doc """
  创建标签 - [Official API Docs Link](#{@doc_link}#1){:target="_blank"}
  """
  @spec create(WeChat.client(), tag_name) :: WeChat.response()
  def create(client, name) do
    Requester.post(
      "/cgi-bin/tags/create",
      json_map(tag: %{name: name}),
      query: [access_token: client.get_access_token()]
    )
  end

  @doc """
  获取公众号已创建的标签 - [Official API Docs Link](#{@doc_link}#2){:target="_blank"}
  """
  @spec get(WeChat.client()) :: WeChat.response()
  def get(client) do
    Requester.get("/cgi-bin/tags/get",
      query: [access_token: client.get_access_token()]
    )
  end

  @doc """
  编辑标签 - [Official API Docs Link](#{@doc_link}#3){:target="_blank"}
  """
  @spec update(WeChat.client(), tag_id, tag_name) :: WeChat.response()
  def update(client, id, name) do
    Requester.post(
      "/cgi-bin/tags/update",
      json_map(tag: %{id: id, name: name}),
      query: [access_token: client.get_access_token()]
    )
  end

  @doc """
  删除标签 - [Official API Docs Link](#{@doc_link}#4){:target="_blank"}
  """
  @spec delete(WeChat.client(), tag_id) :: WeChat.response()
  def delete(client, id) do
    Requester.post(
      "/cgi-bin/tags/delete",
      json_map(tag: %{id: id}),
      query: [access_token: client.get_access_token()]
    )
  end

  @doc """
  获取标签下粉丝列表 - [Official API Docs Link](#{@doc_link}#5){:target="_blank"}
  """
  @spec get_tag_users(WeChat.client(), tag_id) :: WeChat.response()
  def get_tag_users(client, id) do
    Requester.post(
      "/cgi-bin/user/tag/get",
      json_map(tagid: id),
      query: [access_token: client.get_access_token()]
    )
  end

  @doc """
  获取标签下粉丝列表 - 翻页 - [Official API Docs Link](#{@doc_link}#5){:target="_blank"}
  """
  @spec get_tag_users(WeChat.client(), tag_id, next_openid :: WeChat.openid()) ::
          WeChat.response()
  def get_tag_users(client, id, next_openid) do
    Requester.post(
      "/cgi-bin/user/tag/get",
      json_map(tagid: id, next_openid: next_openid),
      query: [access_token: client.get_access_token()]
    )
  end

  @doc """
  批量为用户打标签 - [Official API Docs Link](#{@doc_link}){:target="_blank"}
  """
  @spec batch_tagging_users(WeChat.client(), tag_id, [WeChat.openid()]) :: WeChat.response()
  def batch_tagging_users(client, id, openid_list) do
    Requester.post(
      "/cgi-bin/tags/members/batchtagging",
      json_map(tagid: id, openid_list: openid_list),
      query: [access_token: client.get_access_token()]
    )
  end

  @doc """
  批量为用户取消标签 - [Official API Docs Link](#{@doc_link}){:target="_blank"}
  """
  @spec batch_untagging_users(WeChat.client(), tag_id, [WeChat.openid()]) :: WeChat.response()
  def batch_untagging_users(client, id, openid_list) do
    Requester.post(
      "/cgi-bin/tags/members/batchuntagging",
      json_map(tagid: id, openid_list: openid_list),
      query: [access_token: client.get_access_token()]
    )
  end

  @doc """
  获取用户身上的标签列表 - [Official API Docs Link](#{@doc_link}){:target="_blank"}
  """
  @spec get_user_tags(WeChat.client(), WeChat.openid()) :: WeChat.response()
  def get_user_tags(client, openid) do
    Requester.post(
      "/cgi-bin/tags/getidlist",
      json_map(openid: openid),
      query: [access_token: client.get_access_token()]
    )
  end
end
