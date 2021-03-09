defmodule WeChat.MiniProgram.Live.Role do
  @moduledoc """
  小程序 - 直播成员管理
  """
  import Jason.Helpers
  import WeChat.Utils, only: [doc_link_prefix: 0]
  alias WeChat.User

  @doc_link "#{doc_link_prefix()}/miniprogram/dev/framework/liveplayer/role-manage.html"

  @typedoc "成员角色 [1-管理员，2-主播，3-运营者]，设置超级管理员将无效"
  @type role :: 1..3
  @typedoc """
  成员角色 - 用于查询

  - `-1`: 所有成员
  - `0`: 超级管理员
  - `1`: 管理员
  - `2`: 主播
  - `3`: 运营者
  """
  @type search_role :: -1..3
  @typedoc "搜索的微信号或昵称，不传则返回全部"
  @type search_keyword :: String.t()
  @type options :: [role: search_role, keyword: search_keyword]
  @type offset :: integer
  @type limit :: 1..30

  @doc """
  设置成员角色 -
  [官方文档](#{@doc_link}#1){:target="_blank"}

  调用此接口设置小程序直播成员的管理员、运营者和主播角色
  """
  @spec add_role(WeChat.client(), User.username(), role) :: WeChat.response()
  def add_role(client, username, role) do
    client.post(
      "/wxaapi/broadcast/role/addrole",
      json_map(username: username, role: role),
      query: [access_token: client.get_access_token()]
    )
  end

  @doc """
  解除成员角色 -
  [官方文档](#{@doc_link}#2){:target="_blank"}

  调用此接口移除小程序直播成员的管理员、运营者和主播角色
  """
  @spec delete_role(WeChat.client(), User.username(), role) :: WeChat.response()
  def delete_role(client, username, role) do
    client.post(
      "/wxaapi/broadcast/role/deleterole",
      json_map(username: username, role: role),
      query: [access_token: client.get_access_token()]
    )
  end

  @doc """
  查询成员列表 -
  [官方文档](#{@doc_link}#3){:target="_blank"}

  调用此接口查询小程序直播成员列表
  """
  @spec get_role_list(WeChat.client(), options, offset, limit) :: WeChat.response()
  def get_role_list(client, options, offset \\ 0, limit \\ 10) do
    client.get("/wxaapi/broadcast/role/getrolelist",
      query: [offset: offset, limit: limit, access_token: client.get_access_token()] ++ options
    )
  end
end
