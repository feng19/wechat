defmodule WeChat.Work.OA.Schedule do
  @moduledoc "日程"

  import Jason.Helpers
  import WeChat.Utils, only: [work_doc_link_prefix: 0]
  alias WeChat.Work
  alias WeChat.Work.OA.Calendar

  @doc_link "#{work_doc_link_prefix()}/90135/93648"
  @typedoc "日程ID"
  @type schedule_id :: String.t()
  @type schedule_id_list :: [schedule_id]

  @doc """
  创建日程
  - [官方文档](#{@doc_link}#创建日程){:target="_blank"}
  """
  @spec add(Work.client(), Work.agent(), body :: map) :: WeChat.response()
  def add(client, agent, body) do
    client.post("/cgi-bin/oa/schedule/add", body,
      query: [access_token: client.get_access_token(agent)]
    )
  end

  @doc """
  更新日程
  - [官方文档](#{@doc_link}#更新日程){:target="_blank"}
  """
  @spec update(Work.client(), Work.agent(), body :: map) :: WeChat.response()
  def update(client, agent, body) do
    client.post("/cgi-bin/oa/schedule/update", body,
      query: [access_token: client.get_access_token(agent)]
    )
  end

  @doc """
  获取日程详情
  - [官方文档](#{@doc_link}#获取日程详情){:target="_blank"}
  """
  @spec get(Work.client(), Work.agent(), schedule_id_list) :: WeChat.response()
  def get(client, agent, schedule_id_list) do
    client.post("/cgi-bin/oa/schedule/get", json_map(schedule_id_list: schedule_id_list),
      query: [access_token: client.get_access_token(agent)]
    )
  end

  @doc """
  取消日程
  - [官方文档](#{@doc_link}#取消日程){:target="_blank"}
  """
  @spec delete(Work.client(), Work.agent(), schedule_id) :: WeChat.response()
  def delete(client, agent, schedule_id) do
    client.post("/cgi-bin/oa/schedule/del", json_map(schedule_id: schedule_id),
      query: [access_token: client.get_access_token(agent)]
    )
  end

  @doc """
  获取日历下的日程列表
  - [官方文档](#{@doc_link}#获取日历下的日程列表){:target="_blank"}
  """
  @spec get_by_calendar(
          Work.client(),
          Work.agent(),
          Calendar.calendar_id(),
          offset :: integer,
          limit :: 1..1000
        ) :: WeChat.response()
  def get_by_calendar(client, agent, calendar_id, offset \\ 0, limit \\ 500) do
    client.post(
      "/cgi-bin/oa/schedule/get_by_calendar",
      json_map(cal_id: calendar_id, offset: offset, limit: limit),
      query: [access_token: client.get_access_token(agent)]
    )
  end
end
