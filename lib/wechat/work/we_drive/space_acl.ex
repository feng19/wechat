defmodule WeChat.Work.WeDrive.SpaceACL do
  @moduledoc "微盘-空间权限"

  import Jason.Helpers
  import WeChat.Utils, only: [work_doc_link_prefix: 0]
  alias WeChat.Work
  alias Work.Contacts.User
  alias Work.WeDrive.SpaceManagement

  @doc_link "#{work_doc_link_prefix()}/90135/93656"
  @agent :we_drive
  @type auth_info :: [map]

  @doc """
  添加成员/部门
  - [官方文档](#{@doc_link}#新建空间){:target="_blank"}
  """
  @spec add(Work.client(), User.userid(), SpaceManagement.space_id(), auth_info) ::
          WeChat.response()
  def add(client, userid, space_id, auth_info) do
    client.post(
      "/cgi-bin/wedrive/space_acl_add",
      json_map(userid: userid, spaceid: space_id, auth_info: auth_info),
      query: [access_token: client.get_access_token(@agent)]
    )
  end

  @doc """
  移除成员/部门
  - [官方文档](#{@doc_link}#移除成员/部门){:target="_blank"}
  """
  @spec delete(Work.client(), User.userid(), SpaceManagement.space_id(), auth_info) ::
          WeChat.response()
  def delete(client, userid, space_id, auth_info) do
    client.post(
      "/cgi-bin/wedrive/space_acl_del",
      json_map(userid: userid, spaceid: space_id, auth_info: auth_info),
      query: [access_token: client.get_access_token(@agent)]
    )
  end

  @doc """
  权限管理
  - [官方文档](#{@doc_link}#权限管理){:target="_blank"}
  """
  @spec setting(Work.client(), User.userid(), SpaceManagement.space_id(), opts :: Enumerable.t()) ::
          WeChat.response()
  def setting(client, userid, space_id, opts) do
    body = Map.new(opts) |> Map.merge(%{userid: userid, spaceid: space_id})

    client.post("/cgi-bin/wedrive/space_setting", body,
      query: [access_token: client.get_access_token(@agent)]
    )
  end

  @doc """
  获取邀请链接
  - [官方文档](#{@doc_link}#获取邀请链接){:target="_blank"}
  """
  @spec share(Work.client(), User.userid(), SpaceManagement.space_id()) :: WeChat.response()
  def share(client, userid, space_id) do
    client.post("/cgi-bin/wedrive/space_share", json_map(userid: userid, spaceid: space_id),
      query: [access_token: client.get_access_token(@agent)]
    )
  end
end
