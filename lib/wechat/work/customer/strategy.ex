defmodule WeChat.Work.Customer.Strategy do
  @moduledoc "客户联系规则组管理"

  import Jason.Helpers
  alias WeChat.Work

  @typedoc "客户联系规则组ID"
  @type strategy_id :: integer
  @typep cursor :: String.t()
  @typep limit :: integer

  @doc """
  获取规则组列表 -
  [官方文档](https://developer.work.weixin.qq.com/document/path/94883#获取规则组列表){:target="_blank"}

  企业可通过此接口获取企业配置的所有客户规则组id列表。
  """
  @spec list(Work.client(), Work.agent(), cursor, limit) :: WeChat.response()
  def list(client, agent, cursor \\ nil, limit \\ 1000) do
    body =
      if cursor do
        json_map(cursor: cursor, limit: limit)
      else
        json_map(limit: limit)
      end

    client.post("/cgi-bin/externalcontact/customer_strategy/list", body,
      query: [access_token: client.get_access_token(agent)]
    )
  end

  @doc """
  获取规则组详情 -
  [官方文档](https://developer.work.weixin.qq.com/document/path/94883#获取规则组详情){:target="_blank"}

  企业可以通过此接口获取某个客户规则组的详细信息。
  """
  @spec get(Work.client(), Work.agent(), strategy_id) :: WeChat.response()
  def get(client, agent, strategy_id) do
    client.post(
      "/cgi-bin/externalcontact/customer_strategy/get",
      json_map(strategy_id: strategy_id),
      query: [access_token: client.get_access_token(agent)]
    )
  end

  @doc """
  获取规则组管理范围 -
  [官方文档](https://developer.work.weixin.qq.com/document/path/94883#获取规则组管理范围){:target="_blank"}

  企业可通过此接口获取某个客户规则组管理的成员和部门列表。
  """
  @spec get_range(Work.client(), Work.agent(), strategy_id, cursor, limit) :: WeChat.response()
  def get_range(client, agent, strategy_id, cursor \\ nil, limit \\ 1000) do
    body =
      if cursor do
        json_map(strategy_id: strategy_id, limit: limit, cursor: cursor)
      else
        json_map(strategy_id: strategy_id, limit: limit)
      end

    client.post("/cgi-bin/externalcontact/customer_strategy/get_range", body,
      query: [access_token: client.get_access_token(agent)]
    )
  end

  @doc """
  创建新的规则组 -
  [官方文档](https://developer.work.weixin.qq.com/document/path/94883#创建新的规则组){:target="_blank"}

  企业可通过此接口创建一个新的客户规则组。该接口仅支持串行调用，请勿并发创建规则组。
  """
  @spec create(Work.client(), Work.agent(), body :: map) :: WeChat.response()
  def create(client, agent, body) do
    client.post("/cgi-bin/externalcontact/customer_strategy/create", body,
      query: [access_token: client.get_access_token(agent)]
    )
  end

  @doc """
  编辑规则组及其管理范围 -
  [官方文档](https://developer.work.weixin.qq.com/document/path/94883#编辑规则组及其管理范围){:target="_blank"}

  企业可通过此接口编辑规则组的基本信息和修改客户规则组管理范围。该接口仅支持串行调用，请勿并发修改规则组。
  """
  @spec edit(Work.client(), Work.agent(), body :: map) :: WeChat.response()
  def edit(client, agent, body) do
    client.post("/cgi-bin/externalcontact/customer_strategy/edit", body,
      query: [access_token: client.get_access_token(agent)]
    )
  end

  @doc """
  删除规则组 -
  [官方文档](https://developer.work.weixin.qq.com/document/path/94883#删除规则组){:target="_blank"}

  企业可通过此接口删除某个规则组。
  """
  @spec delete(Work.client(), Work.agent(), strategy_id) :: WeChat.response()
  def delete(client, agent, strategy_id) do
    client.post(
      "/cgi-bin/externalcontact/customer_strategy/del",
      json_map(strategy_id: strategy_id),
      query: [access_token: client.get_access_token(agent)]
    )
  end
end
