defmodule WeChat.Work.Contacts.Department do
  @moduledoc "通讯录管理-部门管理"

  import Jason.Helpers
  alias WeChat.Work

  @typedoc """
  部门ID - [官方文档](https://developer.work.weixin.qq.com/document/path/90665#部门id){:target="_blank"}

  在管理后台->“通讯录”->“组织架构”->点击某个部门右边的小圆点可以看到
  """
  @type id :: integer
  @type id_list :: [id]

  @doc """
  创建部门 -
  [官方文档](https://developer.work.weixin.qq.com/document/path/90205){:target="_blank"}

  注意，部门的最大层级为15层；部门总数不能超过3万个；每个部门下的节点不能超过3万个。建议保证创建的部门和对应部门成员是串行化处理。
  """
  @spec create(Work.client(), Work.agent(), body :: map) :: WeChat.response()
  def create(client, agent, body) do
    client.post("/cgi-bin/department/create", body,
      query: [access_token: client.get_access_token(agent)]
    )
  end

  @doc """
  更新部门 -
  [官方文档](https://developer.work.weixin.qq.com/document/path/90206){:target="_blank"}
  """
  @spec update(Work.client(), Work.agent(), body :: map) :: WeChat.response()
  def update(client, agent, body) do
    client.post("/cgi-bin/department/update", body,
      query: [access_token: client.get_access_token(agent)]
    )
  end

  @doc """
  删除部门 -
  [官方文档](https://developer.work.weixin.qq.com/document/path/90207){:target="_blank"}

  **注：不能删除根部门；不能删除含有子部门、成员的部门**
  """
  @spec delete(Work.client(), Work.agent(), id) :: WeChat.response()
  def delete(client, agent, id) do
    client.post("/cgi-bin/department/delete", json_map(id: id),
      query: [access_token: client.get_access_token(agent)]
    )
  end

  @doc """
  获取部门列表 -
  [官方文档](https://developer.work.weixin.qq.com/document/path/90208){:target="_blank"}

  获取指定部门及其下的子部门（以及及子部门的子部门等等，递归）。
  如果不填 `department_id`，默认获取全量组织架构
  """
  @spec list(Work.client(), Work.agent()) :: WeChat.response()
  def list(client, agent) do
    client.get("/cgi-bin/department/list",
      query: [access_token: client.get_access_token(agent)]
    )
  end

  @spec list(Work.client(), Work.agent(), id) :: WeChat.response()
  def list(client, agent, id) do
    client.get("/cgi-bin/department/list",
      query: [id: id, access_token: client.get_access_token(agent)]
    )
  end

  @doc """
  获取子部门ID列表 -
  [官方文档](https://developer.work.weixin.qq.com/document/path/95350){:target="_blank"}
  """
  @spec list_id(Work.client(), Work.agent()) :: WeChat.response()
  def list_id(client, agent) do
    client.get("/cgi-bin/department/simplelist",
      query: [access_token: client.get_access_token(agent)]
    )
  end

  @spec list_id(Work.client(), Work.agent(), id) :: WeChat.response()
  def list_id(client, agent, id) do
    client.get("/cgi-bin/department/simplelist",
      query: [id: id, access_token: client.get_access_token(agent)]
    )
  end

  @doc """
  获取单个部门详情 -
  [官方文档](https://developer.work.weixin.qq.com/document/path/95351){:target="_blank"}
  """
  @spec get(Work.client(), Work.agent(), id) :: WeChat.response()
  def get(client, agent, id) do
    client.get("/cgi-bin/department/get",
      query: [id: id, access_token: client.get_access_token(agent)]
    )
  end
end
