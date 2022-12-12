defmodule WeChat.Work.App.Menu do
  @moduledoc "应用自定义菜单"

  import WeChat.Work.Agent, only: [agent2id: 2]
  alias WeChat.Work

  @doc_link WeChat.Utils.new_work_doc_link_prefix()

  @doc """
  创建菜单 - [官方文档](#{@doc_link}/90231){:target="_blank"}
  """
  @spec create(Work.client(), Work.agent(), opts :: Enumerable.t()) :: WeChat.response()
  def create(client, agent, opts \\ []) do
    client.post("/cgi-bin/menu/create", Map.new(opts),
      query: [
        agentid: agent2id(client, agent),
        access_token: client.get_access_token(agent)
      ]
    )
  end

  @doc """
  获取菜单 - [官方文档](#{@doc_link}/90232){:target="_blank"}
  """
  @spec get(Work.client(), Work.agent()) :: WeChat.response()
  def get(client, agent) do
    client.get(
      "/cgi-bin/menu/get",
      query: [
        agentid: agent2id(client, agent),
        access_token: client.get_access_token(agent)
      ]
    )
  end

  @doc """
  删除菜单 - [官方文档](#{@doc_link}/90233){:target="_blank"}
  """
  @spec delete(Work.client(), Work.agent()) :: WeChat.response()
  def delete(client, agent) do
    client.get(
      "/cgi-bin/menu/delete",
      query: [
        agentid: agent2id(client, agent),
        access_token: client.get_access_token(agent)
      ]
    )
  end
end
