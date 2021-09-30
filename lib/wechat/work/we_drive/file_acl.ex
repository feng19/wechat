defmodule WeChat.Work.WeDrive.FileACL do
  @moduledoc "微盘-文件权限"

  import Jason.Helpers
  import WeChat.Utils, only: [work_doc_link_prefix: 0]
  alias WeChat.Work
  alias Work.Contacts.User
  alias Work.WeDrive.FileManagement

  @doc_link "#{work_doc_link_prefix()}/90135/93658"
  @agent :we_drive
  @type auth_info :: [map]
  @typedoc """
  权限范围

  - `1`: 指定人
  - `2`: 企业内
  - `3`: 企业外
  """
  @type auth_scope :: 1..3
  @typedoc """
  权限信息

  ## 普通文档
    `1`: 仅浏览（可下载)
    `4`: 仅预览（仅专业版企业可设置）

  ## 微文档：
    `1`: 仅浏览（可下载）
    `2`: 可编辑
  """
  @type auth :: integer

  @doc """
  新增指定人
  - [官方文档](#{@doc_link}#新增指定人){:target="_blank"}
  """
  @spec add(Work.client(), User.userid(), FileManagement.file_id(), auth_info) ::
          WeChat.response()
  def add(client, userid, file_id, auth_info) do
    client.post(
      "/cgi-bin/wedrive/file_acl_add",
      json_map(userid: userid, fileid: file_id, auth_info: auth_info),
      query: [access_token: client.get_access_token(@agent)]
    )
  end

  @doc """
  删除指定人
  - [官方文档](#{@doc_link}#删除指定人){:target="_blank"}
  """
  @spec delete(Work.client(), User.userid(), FileManagement.file_id(), auth_info) ::
          WeChat.response()
  def delete(client, userid, file_id, auth_info) do
    client.post(
      "/cgi-bin/wedrive/file_acl_del",
      json_map(userid: userid, fileid: file_id, auth_info: auth_info),
      query: [access_token: client.get_access_token(@agent)]
    )
  end

  @doc """
  分享设置
  - [官方文档](#{@doc_link}#分享设置){:target="_blank"}
  """
  @spec setting(Work.client(), User.userid(), FileManagement.file_id(), auth_scope, auth) ::
          WeChat.response()
  def setting(client, userid, file_id, auth_scope, auth) do
    client.post(
      "/cgi-bin/wedrive/file_setting",
      json_map(userid: userid, fileid: file_id, auth_scope: auth_scope, auth: auth),
      query: [access_token: client.get_access_token(@agent)]
    )
  end

  @doc """
  获取分享链接
  - [官方文档](#{@doc_link}#获取分享链接){:target="_blank"}
  """
  @spec share(Work.client(), User.userid(), FileManagement.file_id()) :: WeChat.response()
  def share(client, userid, file_id) do
    client.post(
      "/cgi-bin/wedrive/file_share",
      json_map(userid: userid, fileid: file_id),
      query: [access_token: client.get_access_token(@agent)]
    )
  end
end
