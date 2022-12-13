defmodule WeChat.Work.Customer.Tag do
  @moduledoc """
  客户标签管理

  企业客户标签是针对企业的外部联系人进行标记和分类的标签，由企业统一配置后，企业成员可使用此标签对客户进行标记。
  """

  alias WeChat.{Work, Work.Customer, Work.Customer.Strategy}

  @doc_link WeChat.Utils.new_work_doc_link_prefix()

  @typedoc "标签的id 或 标签组的id"
  @type id :: tag_id | group_id
  @typedoc "标签的id"
  @type tag_id :: String.t()
  @type tag_ids :: [tag_id]
  @typedoc "标签组的id"
  @type group_id :: String.t()
  @type group_ids :: [group_id]
  @typep opts :: Enumerable.t()

  ######################
  # 管理企业标签
  # 企业客户标签是针对企业的外部联系人进行标记和分类的标签，
  # 由企业统一配置后，企业成员可使用此标签对客户进行标记。
  ######################

  @doc """
  获取企业标签库 -
  [官方文档](#{@doc_link}/92117#获取企业标签库){:target="_blank"}

  企业可通过此接口获取企业客户标签详情。
  """
  @spec get_corp_tag_list(Work.client(), Work.agent()) :: WeChat.response()
  def get_corp_tag_list(client, agent) do
    client.get("/cgi-bin/externalcontact/get_corp_tag_list",
      query: [access_token: client.get_access_token(agent)]
    )
  end

  @doc """
  添加企业客户标签 -
  [官方文档](#{@doc_link}/92117#添加企业客户标签){:target="_blank"}

  企业可通过此接口向客户标签库中添加新的标签组和标签，每个企业最多可配置3000个企业标签。
  """
  @spec add_corp_tag(Work.client(), Work.agent(), body :: map) :: WeChat.response()
  def add_corp_tag(client, agent, body) do
    client.post("/cgi-bin/externalcontact/add_corp_tag", body,
      query: [access_token: client.get_access_token(agent)]
    )
  end

  @doc """
  编辑企业客户标签 -
  [官方文档](#{@doc_link}/92117#编辑企业客户标签){:target="_blank"}

  企业可通过此接口获取企业客户标签详情。
  """
  @spec edit_corp_tag(Work.client(), Work.agent(), id, opts) :: WeChat.response()
  def edit_corp_tag(client, agent, id, opts \\ []) do
    client.post(
      "/cgi-bin/externalcontact/edit_corp_tag",
      Map.new(opts) |> Map.put("id", id),
      query: [access_token: client.get_access_token(agent)]
    )
  end

  @doc """
  删除企业客户标签 -
  [官方文档](#{@doc_link}/92117#删除企业客户标签){:target="_blank"}

  企业可通过此接口获取企业客户标签详情。
  """
  @spec del_corp_tag(Work.client(), Work.agent(), nil | tag_ids, nil | group_ids) ::
          WeChat.response()
  def del_corp_tag(client, agent, tag_ids, group_ids) do
    body =
      [tag_id: List.wrap(tag_ids), group_id: List.wrap(group_ids)]
      |> Enum.reject(&Enum.empty?(elem(&1, 1)))
      |> Map.new()

    client.post("/cgi-bin/externalcontact/del_corp_tag", body,
      query: [access_token: client.get_access_token(agent)]
    )
  end

  ######################
  # 管理企业规则组下的客户标签
  # 企业规则组下的客户标签仅可被该规则组管理范围内的企业成员使用。
  ######################

  @doc """
  获取指定规则组下的企业客户标签 -
  [官方文档](#{@doc_link}/94882#获取指定规则组下的企业客户标签){:target="_blank"}

  企业可通过此接口获取某个规则组内的企业客户标签详情。
  """
  @spec get_strategy_tag_list(Work.client(), Work.agent(), body :: map) :: WeChat.response()
  def get_strategy_tag_list(client, agent, body) do
    client.post("/cgi-bin/externalcontact/get_strategy_tag_list", body,
      query: [access_token: client.get_access_token(agent)]
    )
  end

  @doc """
  为指定规则组创建企业客户标签 -
  [官方文档](#{@doc_link}/94882#为指定规则组创建企业客户标签){:target="_blank"}

  企业可通过此接口向规则组中添加新的标签组和标签，每个企业的企业标签和规则组标签合计最多可配置3000个。
  """
  @spec add_strategy_tag(Work.client(), Work.agent(), Strategy.strategy_id(), opts) ::
          WeChat.response()
  def add_strategy_tag(client, agent, strategy_id, opts \\ []) do
    client.post(
      "/cgi-bin/externalcontact/add_strategy_tag",
      Map.new(opts) |> Map.put("strategy_id", strategy_id),
      query: [access_token: client.get_access_token(agent)]
    )
  end

  @doc """
  编辑指定规则组下的企业客户标签 -
  [官方文档](#{@doc_link}/94882#编辑指定规则组下的企业客户标签){:target="_blank"}

  企业可通过此接口编辑指定规则组下的客户标签/标签组的名称或次序值，但不可重新指定标签/标签组所属规则组。
  """
  @spec edit_strategy_tag(Work.client(), Work.agent(), id, opts) :: WeChat.response()
  def edit_strategy_tag(client, agent, id, opts \\ []) do
    client.post(
      "/cgi-bin/externalcontact/edit_strategy_tag",
      Map.new(opts) |> Map.put("id", id),
      query: [access_token: client.get_access_token(agent)]
    )
  end

  @doc """
  删除指定规则组下的企业客户标签 -
  [官方文档](#{@doc_link}/94882#删除指定规则组下的企业客户标签){:target="_blank"}

  企业可通过此接口删除某个规则组下的标签，或删除整个标签组。
  """
  @spec del_strategy_tag(Work.client(), Work.agent(), nil | tag_ids, nil | group_ids) ::
          WeChat.response()
  def del_strategy_tag(client, agent, tag_ids, group_ids) do
    body =
      [tag_id: List.wrap(tag_ids), group_id: List.wrap(group_ids)]
      |> Enum.reject(&Enum.empty?(elem(&1, 1)))
      |> Map.new()

    client.post("/cgi-bin/externalcontact/del_strategy_tag", body,
      query: [access_token: client.get_access_token(agent)]
    )
  end

  @doc """
  编辑客户企业标签 -
  [官方文档](#{@doc_link}/92118){:target="_blank"}

  企业可通过此接口为指定成员的客户添加上由企业统一配置的标签。
  """
  @spec mark_tag(
          Work.client(),
          Work.agent(),
          User.userid(),
          Customer.external_userid(),
          nil | tag_ids,
          nil | tag_ids
        ) :: WeChat.response()
  def mark_tag(client, agent, userid, external_userid, add_tags, remove_tags) do
    body =
      [add_tag: List.wrap(add_tags), group_id: List.wrap(remove_tags)]
      |> Enum.reject(&Enum.empty?(elem(&1, 1)))
      |> Enum.into(%{userid: userid, external_userid: external_userid})

    client.post("/cgi-bin/externalcontact/mark_tag", body,
      query: [access_token: client.get_access_token(agent)]
    )
  end
end
