defmodule WeChat.Work.WeDrive.FileManagement do
  @moduledoc "微盘-文件管理"

  import Jason.Helpers
  import WeChat.Utils, only: [work_doc_link_prefix: 0]
  alias WeChat.Work
  alias Work.Contacts.User
  alias Work.WeDrive.SpaceManagement

  @doc_link "#{work_doc_link_prefix()}/90135/93657"
  @agent :we_drive
  @type file_id :: String.t()
  @type file_id_list :: [file_id]
  @typedoc """
  列表排序方式

  - `1`: 名字升序
  - `2`: 名字降序
  - `3`: 大小升序
  - `4`: 大小降序
  - `5`: 修改时间升序
  - `6`: 修改时间降序
  """
  @type sort_type :: integer
  @typedoc """
  文件类型

  - `1`: 文件夹
  - `3`: 微文档(文档)
  - `4`: 微文档(表格)
  - `5`: 微文档(收集表)
  """
  @type file_type :: integer
  @typedoc "文件名字"
  @type file_name :: String.t()
  @typedoc "文件内容base64"
  @type file_base64_content :: String.t()

  @doc """
  获取文件列表
  - [官方文档](#{@doc_link}#获取文件列表){:target="_blank"}
  """
  @spec list(
          Work.client(),
          User.userid(),
          SpaceManagement.space_id(),
          father_id :: file_id,
          sort_type,
          start :: integer,
          limit :: 1..1000
        ) :: WeChat.response()
  def list(client, userid, space_id, father_id, sort_type \\ 1, start \\ 0, limit \\ 100) do
    client.post(
      "/cgi-bin/wedrive/file_list",
      json_map(
        userid: userid,
        spaceid: space_id,
        fatherid: father_id,
        sort_type: sort_type,
        start: start,
        limit: limit
      ),
      query: [access_token: client.get_access_token(@agent)]
    )
  end

  @doc """
  上传文件
  - [官方文档](#{@doc_link}#上传文件){:target="_blank"}

  **注意：只需要填入文件内容的Base64，不需要添加任何如：”data:application/x-javascript;base64” 的数据类型描述信息**
  """
  @spec upload(
          Work.client(),
          User.userid(),
          SpaceManagement.space_id(),
          father_id :: file_id,
          file_name,
          file_base64_content
        ) :: WeChat.response()
  def upload(client, userid, space_id, father_id, file_name, file_base64_content) do
    client.post(
      "/cgi-bin/wedrive/file_upload",
      json_map(
        userid: userid,
        spaceid: space_id,
        fatherid: father_id,
        file_name: file_name,
        file_base64_content: file_base64_content
      ),
      query: [access_token: client.get_access_token(@agent)]
    )
  end

  @doc """
  下载文件
  - [官方文档](#{@doc_link}#下载文件){:target="_blank"}
  """
  @spec download(Work.client(), User.userid(), file_id) :: WeChat.response()
  def download(client, userid, file_id) do
    client.post("/cgi-bin/wedrive/file_download", json_map(userid: userid, fileid: file_id),
      query: [access_token: client.get_access_token(@agent)]
    )
  end

  @doc """
  新建文件/微文档
  - [官方文档](#{@doc_link}#新建文件/微文档){:target="_blank"}
  """
  @spec create(
          Work.client(),
          User.userid(),
          SpaceManagement.space_id(),
          father_id :: file_id,
          file_type,
          file_name
        ) :: WeChat.response()
  def create(client, userid, space_id, father_id, file_type, file_name) do
    client.post(
      "/cgi-bin/wedrive/file_create",
      json_map(
        userid: userid,
        spaceid: space_id,
        fatherid: father_id,
        file_type: file_type,
        file_name: file_name
      ),
      query: [access_token: client.get_access_token(@agent)]
    )
  end

  @doc """
  重命名文件
  - [官方文档](#{@doc_link}#重命名文件){:target="_blank"}
  """
  @spec rename(Work.client(), User.userid(), file_id, file_name) :: WeChat.response()
  def rename(client, userid, file_id, new_name) do
    client.post(
      "/cgi-bin/wedrive/file_rename",
      json_map(userid: userid, fileid: file_id, new_name: new_name),
      query: [access_token: client.get_access_token(@agent)]
    )
  end

  @doc """
  移动文件
  - [官方文档](#{@doc_link}#重命名文件){:target="_blank"}

  ## 参数说明

  replace: 如果移动到的目标目录与需要移动的文件重名时，是否覆盖。

  - `true`: 重名文件覆盖
  - `false`: 重名文件进行冲突重命名处理（移动后文件名格式如xxx(1).txt xxx(1).doc等）
  """
  @spec move(Work.client(), User.userid(), father_id :: file_id, file_id_list, replace :: boolean) ::
          WeChat.response()
  def move(client, userid, father_id, file_id_list, replace \\ false) do
    client.post(
      "/cgi-bin/wedrive/file_move",
      json_map(userid: userid, fatherid: father_id, fileid: file_id_list, replace: replace),
      query: [access_token: client.get_access_token(@agent)]
    )
  end

  @doc """
  删除文件
  - [官方文档](#{@doc_link}#删除文件){:target="_blank"}
  """
  @spec delete(Work.client(), User.userid(), file_id_list) :: WeChat.response()
  def delete(client, userid, file_id_list) do
    client.post(
      "/cgi-bin/wedrive/file_delete",
      json_map(userid: userid, fileid: file_id_list),
      query: [access_token: client.get_access_token(@agent)]
    )
  end

  @doc """
  文件信息
  - [官方文档](#{@doc_link}#文件信息){:target="_blank"}
  """
  @spec info(Work.client(), User.userid(), file_id) :: WeChat.response()
  def info(client, userid, file_id) do
    client.post(
      "/cgi-bin/wedrive/file_info",
      json_map(userid: userid, fileid: file_id),
      query: [access_token: client.get_access_token(@agent)]
    )
  end
end
