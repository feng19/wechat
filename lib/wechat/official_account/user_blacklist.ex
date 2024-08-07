defmodule WeChat.UserBlacklist do
  @moduledoc """
  黑名单管理

  [官方文档](https://developers.weixin.qq.com/doc/offiaccount/User_Management/Manage_blacklist.html){:target="_blank"}
  """
  import Jason.Helpers

  @doc_link "https://developers.weixin.qq.com/doc/offiaccount/User_Management/Manage_blacklist.html"

  @doc """
  获取公众号的黑名单列表 -
  [官方文档](#{@doc_link}#1){:target="_blank"}
  """
  @spec get_black_list(WeChat.client()) :: WeChat.response()
  def get_black_list(client) do
    client.post("/cgi-bin/tags/members/getblacklist", %{},
      query: [access_token: client.get_access_token()]
    )
  end

  @doc """
  获取公众号的黑名单列表 - 翻页 -
  [官方文档](#{@doc_link}#1){:target="_blank"}
  """
  @spec get_black_list(WeChat.client(), WeChat.openid()) :: WeChat.response()
  def get_black_list(client, begin_openid) do
    client.post(
      "/cgi-bin/tags/members/getblacklist",
      json_map(begin_openid: begin_openid),
      query: [access_token: client.get_access_token()]
    )
  end

  @doc """
  拉黑用户 -
  [官方文档](#{@doc_link}#2){:target="_blank"}
  """
  @spec batch_blacklist(WeChat.client(), WeChat.openid_list()) :: WeChat.response()
  def batch_blacklist(client, openid_list) do
    client.post(
      "/cgi-bin/tags/members/batchblacklist",
      json_map(openid_list: openid_list),
      query: [access_token: client.get_access_token()]
    )
  end

  @doc """
  取消拉黑用户 -
  [官方文档](#{@doc_link}#3){:target="_blank"}
  """
  @spec batch_unblacklist(WeChat.client(), WeChat.openid_list()) :: WeChat.response()
  def batch_unblacklist(client, openid_list) do
    client.post(
      "/cgi-bin/tags/members/batchunblacklist",
      json_map(openid_list: openid_list),
      query: [access_token: client.get_access_token()]
    )
  end
end
