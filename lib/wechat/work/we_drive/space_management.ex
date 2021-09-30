defmodule WeChat.Work.WeDrive.SpaceManagement do
  @moduledoc "微盘-空间管理"

  import Jason.Helpers
  import WeChat.Utils, only: [work_doc_link_prefix: 0]
  alias WeChat.Work
  alias Work.Contacts.User

  @doc_link "#{work_doc_link_prefix()}/90135/93655"
  @agent :we_drive
  @type space_id :: String.t()
  @type space_name :: String.t()

  @doc """
  新建空间
  - [官方文档](#{@doc_link}#新建空间){:target="_blank"}
  """
  @spec create(Work.client(), body :: map) :: WeChat.response()
  def create(client, body) do
    client.post("/cgi-bin/wedrive/create", body,
      query: [access_token: client.get_access_token(@agent)]
    )
  end

  @doc """
  重命名空间
  - [官方文档](#{@doc_link}#重命名空间){:target="_blank"}
  """
  @spec rename(Work.client(), User.userid(), space_id, space_name) :: WeChat.response()
  def rename(client, userid, space_id, space_name) do
    client.post(
      "/cgi-bin/wedrive/space_rename",
      json_map(userid: userid, spaceid: space_id, space_name: space_name),
      query: [access_token: client.get_access_token(@agent)]
    )
  end

  @doc """
  解散空间
  - [官方文档](#{@doc_link}#解散空间){:target="_blank"}
  """
  @spec dismiss(Work.client(), User.userid(), space_id) :: WeChat.response()
  def dismiss(client, userid, space_id) do
    client.post("/cgi-bin/wedrive/space_dismiss", json_map(userid: userid, spaceid: space_id),
      query: [access_token: client.get_access_token(@agent)]
    )
  end

  @doc """
  获取空间信息
  - [官方文档](#{@doc_link}#获取空间信息){:target="_blank"}
  """
  @spec info(Work.client(), User.userid(), space_id) :: WeChat.response()
  def info(client, userid, space_id) do
    client.post("/cgi-bin/wedrive/space_info", json_map(userid: userid, spaceid: space_id),
      query: [access_token: client.get_access_token(@agent)]
    )
  end
end
