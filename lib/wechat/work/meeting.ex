defmodule WeChat.Work.Meeting do
  @moduledoc "会议"

  import Jason.Helpers
  alias WeChat.Work
  alias Work.Contacts.User

  @doc_link WeChat.Utils.new_work_doc_link_prefix()

  @typedoc "会议ID"
  @type meeting_id :: String.t()
  @type meeting_id_list :: [meeting_id]

  @doc """
  创建预约会议
  - [官方文档](#{@doc_link}/93627){:target="_blank"}
  """
  @spec create(Work.client(), Work.agent(), body :: map) :: WeChat.response()
  def create(client, agent, body) do
    client.post("/cgi-bin/meeting/create", body,
      query: [access_token: client.get_access_token(agent)]
    )
  end

  @doc """
  修改预约会议
  - [官方文档](#{@doc_link}/93631){:target="_blank"}
  """
  @spec update(Work.client(), Work.agent(), body :: map) :: WeChat.response()
  def update(client, agent, body) do
    client.post("/cgi-bin/meeting/update", body,
      query: [access_token: client.get_access_token(agent)]
    )
  end

  @doc """
  获取会议详情
  - [官方文档](#{@doc_link}/93629){:target="_blank"}
  """
  @spec get_info(Work.client(), Work.agent(), meeting_id) :: WeChat.response()
  def get_info(client, agent, meeting_id) do
    client.post("/cgi-bin/meeting/get_info", json_map(meetingid: meeting_id),
      query: [access_token: client.get_access_token(agent)]
    )
  end

  @doc """
  取消预约会议
  - [官方文档](#{@doc_link}/93630){:target="_blank"}
  """
  @spec cancel(Work.client(), Work.agent(), meeting_id) :: WeChat.response()
  def cancel(client, agent, meeting_id) do
    client.post("/cgi-bin/meeting/cancel", json_map(meetingid: meeting_id),
      query: [access_token: client.get_access_token(agent)]
    )
  end

  @doc """
  获取成员会议ID列表
  - [官方文档](#{@doc_link}/93628){:target="_blank"}

  通过此接口可以获取指定成员指定时间内的所有会议ID
  """
  @spec list_user_meeting_ids(
          Work.client(),
          Work.agent(),
          User.userid(),
          opts :: Enumerable.t()
        ) :: WeChat.response()
  def list_user_meeting_ids(client, agent, userid, opts \\ []) do
    body = Map.new(opts) |> Map.put("userid", userid)

    client.post("/cgi-bin/meeting/get_user_meetingid", body,
      query: [access_token: client.get_access_token(agent)]
    )
  end
end
