defmodule WeChat.Work.Customer do
  @moduledoc "客户联系"

  alias WeChat.Work
  alias Work.Contacts.{User, Department}

  @doc_link WeChat.Utils.work_doc_link_prefix()

  @type external_userid :: String.t()
  @type external_userid_list :: [external_userid]
  @typep opts :: Enumerable.t()
  @typep time :: integer

  @doc """
  获取配置了客户联系功能的成员列表 -
  [官方文档](#{@doc_link}/92576){:target="_blank"}

  企业和第三方服务商可通过此接口获取配置了客户联系功能的成员列表。
  """
  @spec get_enabled_user_list(Work.client(), Work.agent()) :: WeChat.response()
  def get_enabled_user_list(client, agent) do
    client.get("/cgi-bin/externalcontact/get_follow_user_list",
      query: [access_token: client.get_access_token(agent)]
    )
  end

  @doc """
  获取客户列表 -
  [官方文档](#{@doc_link}/92264){:target="_blank"}

  企业可通过此接口获取指定成员添加的客户列表。客户是指配置了客户联系功能的成员所添加的外部联系人。没有配置客户联系功能的成员，所添加的外部联系人将不会作为客户返回。
  """
  @spec list_user_customers(Work.client(), Work.agent(), User.userid()) :: WeChat.response()
  def list_user_customers(client, agent, userid) do
    client.get("/cgi-bin/externalcontact/list",
      query: [
        userid: userid,
        access_token: client.get_access_token(agent)
      ]
    )
  end

  @doc """
  获取客户详情 -
  [官方文档](#{@doc_link}/92265){:target="_blank"}

  企业可通过此接口，根据外部联系人的 userid，拉取客户详情。
  """
  @spec get_customer_info(Work.client(), Work.agent(), external_userid, cursor :: String.t()) ::
          WeChat.response()
  def get_customer_info(client, agent, external_userid, cursor \\ nil) do
    q = [
      external_userid: external_userid,
      access_token: client.get_access_token(agent)
    ]

    query =
      if cursor do
        [{:cursor, cursor} | q]
      else
        q
      end

    client.get("/cgi-bin/externalcontact/get", query: query)
  end

  @doc """
  批量获取客户详情 -
  [官方文档](#{@doc_link}/93010){:target="_blank"}

  企业/第三方可通过此接口获取指定成员添加的客户信息列表。
  """
  @spec get_customer_info_by_user(Work.client(), Work.agent(), User.userid_list(), opts) ::
          WeChat.response()
  def get_customer_info_by_user(client, agent, userid_list, opts \\ []) do
    client.post(
      "/cgi-bin/externalcontact/batch/get_by_user",
      Map.new(opts) |> Map.put("userid_list", userid_list),
      query: [access_token: client.get_access_token(agent)]
    )
  end

  @doc """
  修改客户备注信息 -
  [官方文档](#{@doc_link}/92694){:target="_blank"}

  企业可通过此接口修改指定用户添加的客户的备注信息。
  """
  @spec remark_customer(Work.client(), Work.agent(), User.userid(), external_userid, opts) ::
          WeChat.response()
  def remark_customer(client, agent, userid, external_userid, opts \\ []) do
    client.post(
      "/cgi-bin/externalcontact/remark",
      Map.new(opts) |> Map.merge(%{"userid" => userid, "external_userid" => external_userid}),
      query: [access_token: client.get_access_token(agent)]
    )
  end

  @doc """
  获取「联系客户统计」数据 -
  [官方文档](#{@doc_link}/92132){:target="_blank"}

  企业可通过此接口获取成员联系客户的数据，包括发起申请数、新增客户数、聊天数、发送消息数和删除/拉黑成员的客户数等指标。
  """
  @spec get_user_behavior_data(
          Work.client(),
          Work.agent(),
          time,
          time,
          nil | User.userid_list(),
          nil | Department.id_list()
        ) :: WeChat.response()
  def get_user_behavior_data(client, agent, start_time, end_time, userid_list, party_id_list) do
    body =
      [userid: List.wrap(userid_list), partyid: List.wrap(party_id_list)]
      |> Enum.reject(&Enum.empty?(elem(&1, 1)))
      |> Enum.into(%{start_time: start_time, end_time: end_time})

    client.post("/cgi-bin/externalcontact/get_user_behavior_data", body,
      query: [access_token: client.get_access_token(agent)]
    )
  end
end
