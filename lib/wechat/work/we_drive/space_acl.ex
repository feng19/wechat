defmodule WeChat.Work.WeDrive.SpaceACL do
  @moduledoc "微盘-空间权限"

  import Jason.Helpers
  alias WeChat.Work
  alias Work.Contacts.User
  alias Work.WeDrive.SpaceManagement

  @doc_link WeChat.Utils.work_doc_link_prefix()
  @type auth_info :: [map]

  @doc """
  添加成员/部门
  - [官方文档](#{@doc_link}/93656){:target="_blank"}
  """
  @spec add(Work.client(), Work.agent(), User.userid(), SpaceManagement.space_id(), auth_info) ::
          WeChat.response()
  def add(client, agent, userid, space_id, auth_info) do
    client.post(
      "/cgi-bin/wedrive/space_acl_add",
      json_map(userid: userid, spaceid: space_id, auth_info: auth_info),
      query: [access_token: client.get_access_token(agent)]
    )
  end

  @doc """
  移除成员/部门
  - [官方文档](#{@doc_link}/97875){:target="_blank"}
  """
  @spec delete(Work.client(), Work.agent(), User.userid(), SpaceManagement.space_id(), auth_info) ::
          WeChat.response()
  def delete(client, agent, userid, space_id, auth_info) do
    client.post(
      "/cgi-bin/wedrive/space_acl_del",
      json_map(userid: userid, spaceid: space_id, auth_info: auth_info),
      query: [access_token: client.get_access_token(agent)]
    )
  end

  @doc """
  安全设置
  - [官方文档](#{@doc_link}/97876){:target="_blank"}
  """
  @spec setting(
          Work.client(),
          Work.agent(),
          User.userid(),
          SpaceManagement.space_id(),
          opts :: Enumerable.t()
        ) :: WeChat.response()
  def setting(client, agent, userid, space_id, opts) do
    body = Map.new(opts) |> Map.merge(%{userid: userid, spaceid: space_id})

    client.post("/cgi-bin/wedrive/space_setting", body,
      query: [access_token: client.get_access_token(agent)]
    )
  end

  @doc """
  获取邀请链接
  - [官方文档](#{@doc_link}/97877){:target="_blank"}
  """
  @spec share(Work.client(), Work.agent(), User.userid(), SpaceManagement.space_id()) ::
          WeChat.response()
  def share(client, agent, userid, space_id) do
    client.post("/cgi-bin/wedrive/space_share", json_map(userid: userid, spaceid: space_id),
      query: [access_token: client.get_access_token(agent)]
    )
  end

  @doc """
  获取空间信息
  - [官方文档](#{@doc_link}/97878){:target="_blank"}
  """
  @spec info(Work.client(), Work.agent(), SpaceManagement.space_id()) :: WeChat.response()
  def info(client, agent, space_id) do
    client.post("/cgi-bin/wedrive/new_space_info", json_map(spaceid: space_id),
      query: [access_token: client.get_access_token(agent)]
    )
  end
end
