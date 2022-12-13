defmodule WeChat.Work.Customer.GroupMsg do
  @moduledoc """
  企业群发

  群发助手和客户群群发有以下两种类型

  - 企业发表
    > 管理员或者业务负责人创建内容，成员确认后，即可发送给客户或者客户群
  - 个人发表
    > 成员自己创建的内容，可直接发送给客户或客户群
  """

  import Jason.Helpers
  alias WeChat.Work

  @doc_link WeChat.Utils.new_work_doc_link_prefix()

  @typedoc "企业群发消息的id，可用于获取群发消息发送结果"
  @type msg_id :: String.t()

  @doc """
  创建企业群发 -
  [官方文档](#{@doc_link}/92135){:target="_blank"}

  - 企业跟第三方应用可通过此接口添加企业群发消息的任务并通知成员发送给相关客户或客户群。（注：企业微信终端需升级到2.7.5版本及以上）
  - 注意：调用该接口并不会直接发送消息给客户/客户群，需要成员确认后才会执行发送（客服人员的企业微信需要升级到2.7.5及以上版本）
  - 旧接口创建企业群发已经废弃，接口升级后支持发送视频文件，并且支持最多同时发送9个附件。
  - 同一个企业每个自然月内仅可针对一个客户/客户群发送4条消息，超过接收上限的客户将无法再收到群发消息。
  """
  @spec add_template(Work.client(), Work.agent(), body :: map) :: WeChat.response()
  def add_template(client, agent, body) do
    client.post("/cgi-bin/externalcontact/add_msg_template", body,
      query: [access_token: client.get_access_token(agent)]
    )
  end

  @doc """
  提醒成员群发 -
  [官方文档](#{@doc_link}/97610){:target="_blank"}

  企业和第三方应用可调用此接口，重新触发群发通知，提醒成员完成群发任务，24小时内每个群发最多触发三次提醒。
  """
  @spec remind(Work.client(), Work.agent(), msg_id) :: WeChat.response()
  def remind(client, agent, msg_id) do
    client.post("/cgi-bin/externalcontact/remind_groupmsg_send", json_map(msgid: msg_id),
      query: [access_token: client.get_access_token(agent)]
    )
  end

  @doc """
  停止企业群发 -
  [官方文档](#{@doc_link}/97611){:target="_blank"}

  企业和第三方应用可调用此接口，停止无需成员继续发送的企业群发。
  """
  @spec cancel(Work.client(), Work.agent(), msg_id) :: WeChat.response()
  def cancel(client, agent, msg_id) do
    client.post("/cgi-bin/externalcontact/cancel_groupmsg_send", json_map(msgid: msg_id),
      query: [access_token: client.get_access_token(agent)]
    )
  end

  @doc """
  获取群发记录列表 -
  [官方文档](#{@doc_link}/93338#获取群发记录列表){:target="_blank"}

  企业和第三方应用可通过此接口获取企业与成员的群发记录。
  """
  @spec list(Work.client(), Work.agent(), body :: map) :: WeChat.response()
  def list(client, agent, body) do
    client.post("/cgi-bin/externalcontact/get_groupmsg_list_v2", body,
      query: [access_token: client.get_access_token(agent)]
    )
  end

  @doc """
  获取群发成员发送任务列表 -
  [官方文档](#{@doc_link}/93338#获取群发成员发送任务列表){:target="_blank"}
  """
  @spec list_task(Work.client(), Work.agent(), body :: map) :: WeChat.response()
  def list_task(client, agent, body) do
    client.post("/cgi-bin/externalcontact/get_groupmsg_task", body,
      query: [access_token: client.get_access_token(agent)]
    )
  end

  @doc """
  获取企业群发成员执行结果 -
  [官方文档](#{@doc_link}/93338#获取企业群发成员执行结果){:target="_blank"}
  """
  @spec get_send_result(Work.client(), Work.agent(), body :: map) :: WeChat.response()
  def get_send_result(client, agent, body) do
    client.post("/cgi-bin/externalcontact/get_groupmsg_send_result", body,
      query: [access_token: client.get_access_token(agent)]
    )
  end
end
