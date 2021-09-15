defmodule WeChat.Work.Customer do
  @moduledoc "客户联系"

  import WeChat.Utils, only: [work_doc_link_prefix: 0]
  alias WeChat.Work
  alias Work.Contacts.User

  @doc_link "#{work_doc_link_prefix()}/90000/90135"

  @type external_userid :: String.t()
  @type external_userid_list :: [external_userid]

  @doc """
  获取配置了客户联系功能的成员列表 -
  [官方文档](#{@doc_link}/90227#获取指定的应用详情){:target="_blank"}

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
  [官方文档](#{@doc_link}/92113){:target="_blank"}

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
  [官方文档](#{@doc_link}/92114){:target="_blank"}

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
  [官方文档](#{@doc_link}/92994){:target="_blank"}

  企业/第三方可通过此接口获取指定成员添加的客户信息列表。
  """
  @spec get_customer_info_by_user(
          Work.client(),
          Work.agent(),
          User.userid_list(),
          opts :: Enumerable.t()
        ) :: WeChat.response()
  def get_customer_info_by_user(client, agent, userid_list, opts \\ []) do
    client.post(
      "/cgi-bin/externalcontact/batch/get_by_user",
      Map.new(opts) |> Map.put("userid_list", userid_list),
      query: [access_token: client.get_access_token(agent)]
    )
  end

  @doc """
  修改客户备注信息 -
  [官方文档](#{@doc_link}/92115){:target="_blank"}

  企业可通过此接口修改指定用户添加的客户的备注信息。
  """
  @spec remark_customer(
          Work.client(),
          Work.agent(),
          User.userid(),
          external_userid,
          opts :: Enumerable.t()
        ) :: WeChat.response()
  def remark_customer(client, agent, userid, external_userid, opts \\ []) do
    client.post(
      "/cgi-bin/externalcontact/remark",
      Map.new(opts) |> Map.merge(%{"userid" => userid, "external_userid" => external_userid}),
      query: [access_token: client.get_access_token(agent)]
    )
  end
end
