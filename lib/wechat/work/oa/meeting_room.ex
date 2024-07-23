defmodule WeChat.Work.OA.MeetingRoom do
  @moduledoc "会议室"

  import Jason.Helpers
  alias WeChat.Work

  @typedoc "会议室的ID"
  @type meeting_room_id :: integer
  @typedoc "会议的ID"
  @type meeting_id :: integer

  # management

  @doc """
  会议室管理-添加会议室 -
  [官方文档](https://developer.work.weixin.qq.com/document/path/93619#添加会议室){:target="_blank"}
  """
  @spec add(Work.client(), Work.agent(), body :: map) :: WeChat.response()
  def add(client, agent, body) do
    client.post("/cgi-bin/oa/meetingroom/add", body,
      query: [access_token: client.get_access_token(agent)]
    )
  end

  @doc """
  会议室管理-查询会议室 -
  [官方文档](https://developer.work.weixin.qq.com/document/path/93619#查询会议室){:target="_blank"}
  """
  @spec list(Work.client(), Work.agent(), body :: map) :: WeChat.response()
  def list(client, agent, body) do
    client.post("/cgi-bin/oa/meetingroom/list", body,
      query: [access_token: client.get_access_token(agent)]
    )
  end

  @doc """
  会议室管理-编辑会议室 -
  [官方文档](https://developer.work.weixin.qq.com/document/path/93619#编辑会议室){:target="_blank"}
  """
  @spec edit(Work.client(), Work.agent(), body :: map) :: WeChat.response()
  def edit(client, agent, body) do
    client.post("/cgi-bin/oa/meetingroom/edit", body,
      query: [access_token: client.get_access_token(agent)]
    )
  end

  @doc """
  会议室管理-删除会议室 -
  [官方文档](https://developer.work.weixin.qq.com/document/path/93619#删除会议室){:target="_blank"}
  """
  @spec delete(Work.client(), Work.agent(), meeting_room_id) :: WeChat.response()
  def delete(client, agent, meeting_room_id) do
    client.post("/cgi-bin/oa/meetingroom/del", json_map(meetingroom_id: meeting_room_id),
      query: [access_token: client.get_access_token(agent)]
    )
  end

  # booking

  @doc """
  会议室预定管理-查询会议室的预定信息 -
  [官方文档](https://developer.work.weixin.qq.com/document/path/93620#查询会议室的预定信息){:target="_blank"}
  """
  @spec list_booking(Work.client(), Work.agent(), body :: map) :: WeChat.response()
  def list_booking(client, agent, body) do
    client.post("/cgi-bin/oa/meetingroom/get_booking_info", body,
      query: [access_token: client.get_access_token(agent)]
    )
  end

  @doc """
  会议室预定管理-预定会议室 -
  [官方文档](https://developer.work.weixin.qq.com/document/path/93620#预定会议室){:target="_blank"}
  """
  @spec book(Work.client(), Work.agent(), body :: map) :: WeChat.response()
  def book(client, agent, body) do
    client.post("/cgi-bin/oa/meetingroom/book", body,
      query: [access_token: client.get_access_token(agent)]
    )
  end

  @doc """
  会议室预定管理-取消预定会议室 -
  [官方文档](https://developer.work.weixin.qq.com/document/path/93620#取消预定会议室){:target="_blank"}
  """
  @spec cancel_book(Work.client(), Work.agent(), body :: map) :: WeChat.response()
  def cancel_book(client, agent, body) do
    client.post("/cgi-bin/oa/meetingroom/cancel_book", body,
      query: [access_token: client.get_access_token(agent)]
    )
  end

  @doc """
  会议室预定管理-根据会议ID查询会议室的预定信息 -
  [官方文档](https://developer.work.weixin.qq.com/document/path/93620#根据会议id查询会议室的预定信息){:target="_blank"}
  """
  @spec get_booking_info_by_meeting_id(Work.client(), Work.agent(), meeting_room_id, meeting_id) ::
          WeChat.response()
  def get_booking_info_by_meeting_id(client, agent, meeting_room_id, meeting_id) do
    client.post(
      "/cgi-bin/oa/meetingroom/get_booking_info_by_meeting_id",
      json_map(meetingroom_id: meeting_room_id, meeting_id: meeting_id),
      query: [access_token: client.get_access_token(agent)]
    )
  end
end
