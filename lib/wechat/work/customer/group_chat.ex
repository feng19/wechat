defmodule WeChat.Work.Customer.GroupChat do
  @moduledoc "客户群管理"

  import Jason.Helpers
  import WeChat.Utils, only: [work_doc_link_prefix: 0]
  alias WeChat.Work
  alias WeChat.Work.Contacts.User

  @doc_link "#{work_doc_link_prefix()}/90135"

  @typedoc "客户群ID"
  @type chat_id :: String.t()
  @type chat_id_list :: [chat_id]
  @typedoc """
  是否需要返回群成员的名字 `group_chat.member_list.name`。

  - `0` 不返回
  - `1` 返回

  默认不返回
  """
  @type need_name :: 0 | 1
  @type open_gid :: String.t()

  @doc """
  获取客户群列表 -
  [官方文档](#{@doc_link}/92120){:target="_blank"}

  该接口用于获取配置过客户群管理的客户群列表。
  """
  @spec list(Work.client(), Work.agent(), body :: map) :: WeChat.response()
  def list(client, agent, body) do
    client.post("/cgi-bin/externalcontact/groupchat/list", body,
      query: [access_token: client.get_access_token(agent)]
    )
  end

  @doc """
  获取客户群详情 -
  [官方文档](#{@doc_link}/92122){:target="_blank"}

  通过客户群ID，获取详情。包括群名、群成员列表、群成员入群时间、入群方式。
  （客户群是由具有客户群使用权限的成员创建的外部群）

  需注意的是，如果发生群信息变动，会立即收到群变更事件，
  但是部分信息是异步处理，可能需要等一段时间调此接口才能得到最新结果。
  """
  @spec get(Work.client(), Work.agent(), chat_id, need_name) :: WeChat.response()
  def get(client, agent, chat_id, need_name \\ 0) do
    client.post(
      "/cgi-bin/externalcontact/groupchat/get",
      json_map(chat_id: chat_id, need_name: need_name),
      query: [access_token: client.get_access_token(agent)]
    )
  end

  @doc """
  客户群opengid转换 -
  [官方文档](#{@doc_link}/94822){:target="_blank"}

  用户在微信里的客户群里打开小程序时，某些场景下可以获取到群的opengid，
  如果该群是企业微信的客户群，则企业或第三方可以调用此接口将一个opengid转换为客户群chat_id
  """
  @spec open_gid2chat_id(Work.client(), Work.agent(), open_gid) :: WeChat.response()
  def open_gid2chat_id(client, agent, open_gid) do
    client.post(
      "/cgi-bin/externalcontact/groupchat/opengid_to_chatid",
      json_map(opengid: open_gid),
      query: [access_token: client.get_access_token(agent)]
    )
  end

  @doc """
  分配离职成员的客户群 -
  [官方文档](#{@doc_link}/92127){:target="_blank"}

  企业可通过此接口，将已离职成员为群主的群，分配给另一个客服成员。
  """
  @spec resigned_transfer(Work.client(), Work.agent(), chat_id_list, User.userid()) ::
          WeChat.response()
  def resigned_transfer(client, agent, chat_id_list, new_owner) do
    client.post(
      "/cgi-bin/externalcontact/groupchat/transfer",
      json_map(chat_id_list: List.wrap(chat_id_list), new_owner: new_owner),
      query: [access_token: client.get_access_token(agent)]
    )
  end

  @doc """
  获取「群聊数据统计」数据(按群主聚合的方式) -
  [官方文档](#{@doc_link}/92133#按群主聚合的方式){:target="_blank"}

  获取指定日期的统计数据。注意，企业微信仅存储180天的数据。
  """
  @spec statistic(Work.client(), Work.agent(), body :: map) :: WeChat.response()
  def statistic(client, agent, body) do
    client.post("/cgi-bin/externalcontact/groupchat/statistic", body,
      query: [access_token: client.get_access_token(agent)]
    )
  end

  @doc """
  获取「群聊数据统计」数据(按自然日聚合的方式) -
  [官方文档](#{@doc_link}/92133#按自然日聚合的方式){:target="_blank"}

  获取指定日期的统计数据。注意，企业微信仅存储180天的数据。
  """
  @spec statistic_by_day(Work.client(), Work.agent(), body :: map) :: WeChat.response()
  def statistic_by_day(client, agent, body) do
    client.post("/cgi-bin/externalcontact/groupchat/statistic_group_by_day", body,
      query: [access_token: client.get_access_token(agent)]
    )
  end
end
