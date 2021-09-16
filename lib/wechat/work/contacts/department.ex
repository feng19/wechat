defmodule WeChat.Work.Contacts.Department do
  @moduledoc "通讯录管理-部门管理"

  import WeChat.Utils, only: [work_doc_link_prefix: 0]
  alias WeChat.Work

  @doc_link "#{work_doc_link_prefix()}/90000/90135"

  @typedoc """
  部门ID - [官方文档](#{@doc_link}/90665#部门id){:target="_blank"}

  在管理后台->“通讯录”->“组织架构”->点击某个部门右边的小圆点可以看到
  """
  @type party_id :: integer
  @type party_id_list :: [party_id]

  @doc """
  获取部门列表 -
  [官方文档](#{@doc_link}/90208){:target="_blank"}

  获取指定部门及其下的子部门（以及及子部门的子部门等等，递归）。
  如果不填 `department_id`，默认获取全量组织架构
  """
  @spec list(Work.client()) :: WeChat.response()
  def list(client) do
    client.get("/cgi-bin/department/list",
      query: [access_token: client.get_access_token(:contacts)]
    )
  end

  @spec list(Work.client(), party_id) :: WeChat.response()
  def list(client, party_id) do
    client.get("/cgi-bin/department/list",
      query: [id: party_id, access_token: client.get_access_token(:contacts)]
    )
  end
end
