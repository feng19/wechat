defmodule WeChat.Work.App do
  @moduledoc "应用管理"

  import WeChat.Utils, only: [work_doc_link_prefix: 0]
  alias WeChat.Work

  @doc_link "#{work_doc_link_prefix()}/90000/90135"

  @doc """
  获取指定的应用详情 -
  [官方文档](#{@doc_link}/90227#获取指定的应用详情){:target="_blank"}

  对于互联企业的应用，如果需要获取应用可见范围内其他互联企业的部门与成员，请调用
  [互联企业-获取应用可见范围接口](#{@doc_link}/90227#24275)
  """
  @spec get(Work.client(), Work.agent()) :: WeChat.response()
  def get(client, agent) do
    client.get("/cgi-bin/agent/get",
      query: [
        agentid: Work.Agent.agent2id(client, agent),
        access_token: client.get_access_token(agent)
      ]
    )
  end

  @doc """
  获取access_token对应的应用列表 -
  [官方文档](#{@doc_link}/90227#获取指定的应用详情){:target="_blank"}
  """
  @spec list(Work.client(), Work.agent()) :: WeChat.response()
  def list(client, agent) do
    client.get("/cgi-bin/agent/list",
      query: [access_token: client.get_access_token(agent)]
    )
  end

  @doc """
  设置应用 - [官方文档](#{@doc_link}/90228){:target="_blank"}
  """
  @spec set(Work.client(), Work.agent(), opts :: Keyword.t()) :: WeChat.response()
  def set(client, agent, opts \\ []) do
    client.post(
      "/cgi-bin/agent/set",
      Map.new(opts) |> Map.put("agentid", Work.Agent.agent2id(client, agent)),
      query: [access_token: client.get_access_token(agent)]
    )
  end
end
