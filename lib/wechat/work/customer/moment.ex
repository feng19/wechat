defmodule WeChat.Work.Customer.Moment do
  @moduledoc "客户朋友圈"

  import Jason.Helpers
  import WeChat.Utils, only: [work_doc_link_prefix: 0]
  alias WeChat.{Work, Work.User}

  @doc_link "#{work_doc_link_prefix()}/90000/90135"

  @typedoc "朋友圈ID"
  @type moment_id :: String.t()
  @typedoc "规则组ID"
  @type strategy_id :: String.t()
  @typep opts :: Enumerable.t()
  @typep start_time :: integer
  @typep end_time :: integer

  ##########################
  # 获取客户朋友圈全部的发表记录 #
  ##########################

  @doc """
  获取企业全部的发表列表 -
  [官方文档](#{@doc_link}/93333#获取企业全部的发表列表){:target="_blank"}

  企业和第三方应用可通过该接口获取企业全部的发表内容。
  """
  @spec get_moment_list(Work.client(), Work.agent(), start_time, end_time, opts) ::
          WeChat.response()
  def get_moment_list(client, agent, start_time, end_time, opts \\ []) do
    client.post(
      "/cgi-bin/externalcontact/get_moment_list",
      Map.new(opts) |> Map.merge(%{start_time: start_time, end_time: end_time}),
      query: [access_token: client.get_access_token(agent)]
    )
  end

  @doc """
  获取客户朋友圈企业发表的列表 -
  [官方文档](#{@doc_link}/93333#获取客户朋友圈企业发表的列表){:target="_blank"}

  企业和第三方应用可通过该接口获取企业发表的朋友圈成员执行情况。
  """
  @spec get_moment_task(Work.client(), Work.agent(), moment_id, opts) :: WeChat.response()
  def get_moment_task(client, agent, moment_id, opts \\ []) do
    client.post(
      "/cgi-bin/externalcontact/get_moment_task",
      Map.new(opts) |> Map.put(:moment_id, moment_id),
      query: [access_token: client.get_access_token(agent)]
    )
  end

  @doc """
  获取客户朋友圈发表时选择的可见范围 -
  [官方文档](#{@doc_link}/93333#获取客户朋友圈发表时选择的可见范围){:target="_blank"}

  企业和第三方应用可通过该接口获取客户朋友圈创建时，选择的客户可见范围。
  """
  @spec get_moment_customer_list(Work.client(), Work.agent(), moment_id, User.userid(), opts) ::
          WeChat.response()
  def get_moment_customer_list(client, agent, moment_id, userid, opts \\ []) do
    client.post(
      "/cgi-bin/externalcontact/get_moment_customer_list",
      Map.new(opts) |> Map.merge(%{moment_id: moment_id, userid: userid}),
      query: [access_token: client.get_access_token(agent)]
    )
  end

  @doc """
  获取客户朋友圈发表后的可见客户列表 -
  [官方文档](#{@doc_link}/93333#获取客户朋友圈发表后的可见客户列表){:target="_blank"}

  企业和第三方应用可通过该接口获取客户朋友圈发表后，可在微信朋友圈中查看的客户列表。
  """
  @spec get_moment_send_result(Work.client(), Work.agent(), moment_id, User.userid(), opts) ::
          WeChat.response()
  def get_moment_send_result(client, agent, moment_id, userid, opts \\ []) do
    client.post(
      "/cgi-bin/externalcontact/get_moment_send_result",
      Map.new(opts) |> Map.merge(%{moment_id: moment_id, userid: userid}),
      query: [access_token: client.get_access_token(agent)]
    )
  end

  @doc """
  获取客户朋友圈的互动数据 -
  [官方文档](#{@doc_link}/93333#获取客户朋友圈的互动数据){:target="_blank"}

  企业和第三方应用可通过此接口获取客户朋友圈的互动数据。
  """
  @spec get_moment_comments(Work.client(), Work.agent(), moment_id, User.userid()) ::
          WeChat.response()
  def get_moment_comments(client, agent, moment_id, userid) do
    client.post(
      "/cgi-bin/externalcontact/get_moment_comments",
      json_map(moment_id: moment_id, userid: userid),
      query: [access_token: client.get_access_token(agent)]
    )
  end

  ####################
  # 客户朋友圈规则组管理 #
  ####################

  @doc """
  获取规则组列表 -
  [官方文档](#{@doc_link}/94890#获取规则组列表){:target="_blank"}

  企业可通过此接口获取企业配置的所有客户朋友圈规则组id列表。
  """
  @spec list_moment_strategy(Work.client(), Work.agent(), opts) :: WeChat.response()
  def list_moment_strategy(client, agent, opts) do
    client.post(
      "/cgi-bin/externalcontact/moment_strategy/list",
      Map.new(opts),
      query: [access_token: client.get_access_token(agent)]
    )
  end

  @doc """
  获取规则组详情 -
  [官方文档](#{@doc_link}/94890#获取规则组详情){:target="_blank"}

  企业可以通过此接口获取某个客户朋友圈规则组的详细信息。
  """
  @spec get_moment_strategy(Work.client(), Work.agent(), strategy_id) :: WeChat.response()
  def get_moment_strategy(client, agent, strategy_id) do
    client.post(
      "/cgi-bin/externalcontact/moment_strategy/get",
      json_map(strategy_id: strategy_id),
      query: [access_token: client.get_access_token(agent)]
    )
  end

  @doc """
  获取规则组管理范围 -
  [官方文档](#{@doc_link}/94890#获取规则组管理范围){:target="_blank"}

  企业可通过此接口获取某个朋友圈规则组管理的成员和部门列表。
  """
  @spec get_moment_strategy_range(Work.client(), Work.agent(), strategy_id, opts) ::
          WeChat.response()
  def get_moment_strategy_range(client, agent, strategy_id, opts) do
    client.post(
      "/cgi-bin/externalcontact/moment_strategy/get_range",
      Map.new(opts) |> Map.put("strategy_id", strategy_id),
      query: [access_token: client.get_access_token(agent)]
    )
  end

  @doc """
  创建新的规则组 -
  [官方文档](#{@doc_link}/94890#创建新的规则组){:target="_blank"}

  企业可通过此接口创建一个新的客户朋友圈规则组。该接口仅支持串行调用，请勿并发创建规则组。
  """
  @spec create_moment_strategy(Work.client(), Work.agent(), body :: map) :: WeChat.response()
  def create_moment_strategy(client, agent, body) do
    client.post("/cgi-bin/externalcontact/moment_strategy/create", body,
      query: [access_token: client.get_access_token(agent)]
    )
  end

  @doc """
  编辑规则组及其管理范围 -
  [官方文档](#{@doc_link}/94890#编辑规则组及其管理范围){:target="_blank"}

  企业可通过此接口编辑规则组的基本信息和修改客户朋友圈规则组管理范围。该接口仅支持串行调用，请勿并发修改规则组。
  """
  @spec edit_moment_strategy(Work.client(), Work.agent(), body :: map) :: WeChat.response()
  def edit_moment_strategy(client, agent, body) do
    client.post("/cgi-bin/externalcontact/moment_strategy/edit", body,
      query: [access_token: client.get_access_token(agent)]
    )
  end

  @doc """
  删除规则组 -
  [官方文档](#{@doc_link}/94890#删除规则组){:target="_blank"}

  企业可通过此接口删除某个客户朋友圈规则组。
  """
  @spec delete_moment_strategy(Work.client(), Work.agent(), strategy_id) :: WeChat.response()
  def delete_moment_strategy(client, agent, strategy_id) do
    client.post(
      "/cgi-bin/externalcontact/moment_strategy/del",
      json_map(strategy_id: strategy_id),
      query: [access_token: client.get_access_token(agent)]
    )
  end
end
