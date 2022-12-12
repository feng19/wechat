defmodule WeChat.Work.Contacts.Department do
  @moduledoc "通讯录管理-部门管理"

  import Jason.Helpers
  import WeChat.Utils, only: [new_work_doc_link_prefix: 0]
  alias WeChat.Work

  @doc_link new_work_doc_link_prefix()

  @typedoc """
  部门ID - [官方文档](#{@doc_link}/90665#部门id){:target="_blank"}

  在管理后台->“通讯录”->“组织架构”->点击某个部门右边的小圆点可以看到
  """
  @type id :: integer
  @type id_list :: [id]

  @doc """
  创建部门 -
  [官方文档](#{@doc_link}/90205){:target="_blank"}

  注意，部门的最大层级为15层；部门总数不能超过3万个；每个部门下的节点不能超过3万个。建议保证创建的部门和对应部门成员是串行化处理。
  """
  @spec create(Work.client(), body :: map) :: WeChat.response()
  def create(client, body) do
    client.post("/cgi-bin/department/create", body,
      query: [access_token: client.get_access_token(:contacts)]
    )
  end

  @doc """
  更新部门 -
  [官方文档](#{@doc_link}/90206){:target="_blank"}
  """
  @spec update(Work.client(), body :: map) :: WeChat.response()
  def update(client, body) do
    client.post("/cgi-bin/department/update", body,
      query: [access_token: client.get_access_token(:contacts)]
    )
  end

  @doc """
  删除部门 -
  [官方文档](#{@doc_link}/90207){:target="_blank"}

  **注：不能删除根部门；不能删除含有子部门、成员的部门**
  """
  @spec delete(Work.client(), id) :: WeChat.response()
  def delete(client, id) do
    client.post("/cgi-bin/department/delete", json_map(id: id),
      query: [access_token: client.get_access_token(:contacts)]
    )
  end

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

  @spec list(Work.client(), id) :: WeChat.response()
  def list(client, id) do
    client.get("/cgi-bin/department/list",
      query: [id: id, access_token: client.get_access_token(:contacts)]
    )
  end

  @doc """
  获取子部门ID列表 -
  [官方文档](#{@doc_link}/95350){:target="_blank"}
  """
  @spec list_id(Work.client()) :: WeChat.response()
  def list_id(client) do
    client.get("/cgi-bin/department/simplelist",
      query: [access_token: client.get_access_token(:contacts)]
    )
  end

  @spec list_id(Work.client(), id) :: WeChat.response()
  def list_id(client, id) do
    client.get("/cgi-bin/department/simplelist",
      query: [id: id, access_token: client.get_access_token(:contacts)]
    )
  end

  @doc """
  获取单个部门详情 -
  [官方文档](#{@doc_link}/95351){:target="_blank"}
  """
  @spec get(Work.client(), id) :: WeChat.response()
  def get(client, id) do
    client.get("/cgi-bin/department/get",
      query: [id: id, access_token: client.get_access_token(:contacts)]
    )
  end
end
