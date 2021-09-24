defmodule WeChat.Work.Customer.Transfer do
  @moduledoc "客户继承"

  import Jason.Helpers
  import WeChat.Utils, only: [work_doc_link_prefix: 0]
  alias WeChat.{Work, Work.User, Work.Customer}

  @doc_link "#{work_doc_link_prefix()}/90135"

  @doc """
  分配在职成员的客户 -
  [官方文档](#{@doc_link}/92125){:target="_blank"}

  企业可通过此接口，转接在职成员的客户给其他成员。
  """
  @spec transfer_customer(
          Work.client(),
          Work.agent(),
          User.userid(),
          User.userid(),
          Customer.external_userid_list(),
          transfer_success_msg :: String.t()
        ) :: WeChat.response()
  def transfer_customer(
        client,
        agent,
        handover_userid,
        takeover_userid,
        external_userid_list,
        transfer_success_msg \\ nil
      ) do
    body =
      if is_binary(transfer_success_msg) do
        json_map(
          handover_userid: handover_userid,
          takeover_userid: takeover_userid,
          external_userid_list: List.wrap(external_userid_list),
          transfer_success_msg: transfer_success_msg
        )
      else
        json_map(
          handover_userid: handover_userid,
          takeover_userid: takeover_userid,
          external_userid_list: List.wrap(external_userid_list)
        )
      end

    client.post("/cgi-bin/externalcontact/transfer_customer", body,
      query: [access_token: client.get_access_token(agent)]
    )
  end

  @doc """
  查询客户接替状态 -
  [官方文档](#{@doc_link}/94088){:target="_blank"}

  企业和第三方可通过此接口查询在职成员的客户转接情况。
  """
  @spec transfer_result(
          Work.client(),
          Work.agent(),
          User.userid(),
          User.userid(),
          cursor :: String.t()
        ) :: WeChat.response()
  def transfer_result(client, agent, handover_userid, takeover_userid, cursor \\ nil) do
    body =
      if cursor do
        json_map(
          handover_userid: handover_userid,
          takeover_userid: takeover_userid,
          cursor: cursor
        )
      else
        json_map(handover_userid: handover_userid, takeover_userid: takeover_userid)
      end

    client.post("/cgi-bin/externalcontact/transfer_result", body,
      query: [access_token: client.get_access_token(agent)]
    )
  end

  @doc """
  获取待分配的离职成员列表 -
  [官方文档](#{@doc_link}/92124){:target="_blank"}

  企业和第三方可通过此接口，获取所有离职成员的客户列表，并可进一步调用分配离职成员的客户接口将这些客户重新分配给其他企业成员。
  """
  @spec get_unassigned_list(Work.client(), Work.agent(), body :: map) :: WeChat.response()
  def get_unassigned_list(client, agent, body) do
    client.post("/cgi-bin/externalcontact/get_unassigned_list", body,
      query: [access_token: client.get_access_token(agent)]
    )
  end

  @doc """
  分配离职成员的客户(离职继承) -
  [官方文档](#{@doc_link}/94081){:target="_blank"}

  企业可通过此接口，分配离职成员的客户给其他成员。
  """
  @spec resigned_transfer_customer(
          Work.client(),
          Work.agent(),
          User.userid(),
          User.userid(),
          Customer.external_userid_list()
        ) :: WeChat.response()
  def resigned_transfer_customer(
        client,
        agent,
        handover_userid,
        takeover_userid,
        external_userid_list
      ) do
    client.post(
      "/cgi-bin/externalcontact/resigned/transfer_customer",
      json_map(
        handover_userid: handover_userid,
        takeover_userid: takeover_userid,
        external_userid_list: List.wrap(external_userid_list)
      ),
      query: [access_token: client.get_access_token(agent)]
    )
  end

  @doc """
  查询客户接替状态(离职继承) -
  [官方文档](#{@doc_link}/94082){:target="_blank"}

  企业和第三方可通过此接口查询离职成员的客户分配情况。
  """
  @spec resigned_transfer_result(
          Work.client(),
          Work.agent(),
          User.userid(),
          User.userid(),
          cursor :: String.t()
        ) :: WeChat.response()
  def resigned_transfer_result(client, agent, handover_userid, takeover_userid, cursor \\ nil) do
    body =
      if cursor do
        json_map(
          handover_userid: handover_userid,
          takeover_userid: takeover_userid,
          cursor: cursor
        )
      else
        json_map(handover_userid: handover_userid, takeover_userid: takeover_userid)
      end

    client.post("/cgi-bin/externalcontact/resigned/transfer_result", body,
      query: [access_token: client.get_access_token(agent)]
    )
  end

  @doc """
  分配离职成员的客户群 -
  [官方文档](#{@doc_link}/92127){:target="_blank"}

  企业可通过此接口，将已离职成员为群主的群，分配给另一个客服成员。
  """
  @spec resigned_transfer_group_chat(
          Work.client(),
          Work.agent(),
          Customer.GroupChat.chat_id_list(),
          User.userid()
        ) :: WeChat.response()
  def resigned_transfer_group_chat(client, agent, chat_id_list, new_owner) do
    Customer.GroupChat.resigned_transfer(client, agent, chat_id_list, new_owner)
  end
end
