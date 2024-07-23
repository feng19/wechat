defmodule WeChat.Work.OA.Calendar do
  @moduledoc "日历"

  import Jason.Helpers
  alias WeChat.Work

  @typedoc "日历ID"
  @type calendar_id :: String.t()
  @type calendar_id_list :: [calendar_id]

  @doc """
  创建日历 -
  [官方文档](https://developer.work.weixin.qq.com/document/path/93647){:target="_blank"}
  """
  @spec add(Work.client(), Work.agent(), body :: map) :: WeChat.response()
  def add(client, agent, body) do
    client.post("/cgi-bin/oa/calendar/add", body,
      query: [access_token: client.get_access_token(agent)]
    )
  end

  @doc """
  更新日历 -
  [官方文档](https://developer.work.weixin.qq.com/document/path/97716){:target="_blank"}
  """
  @spec update(Work.client(), Work.agent(), body :: map) :: WeChat.response()
  def update(client, agent, body) do
    client.post("/cgi-bin/oa/calendar/update", body,
      query: [access_token: client.get_access_token(agent)]
    )
  end

  @doc """
  获取日历详情 -
  [官方文档](https://developer.work.weixin.qq.com/document/path/97717){:target="_blank"}
  """
  @spec get(Work.client(), Work.agent(), calendar_id_list) :: WeChat.response()
  def get(client, agent, calendar_id_list) do
    client.post("/cgi-bin/oa/calendar/get", json_map(cal_id_list: calendar_id_list),
      query: [access_token: client.get_access_token(agent)]
    )
  end

  @doc """
  删除日历
  - [官方文档](https://developer.work.weixin.qq.com/document/path/97718){:target="_blank"}
  """
  @spec delete(Work.client(), Work.agent(), calendar_id) :: WeChat.response()
  def delete(client, agent, calendar_id) do
    client.post("/cgi-bin/oa/calendar/del", json_map(cal_id: calendar_id),
      query: [access_token: client.get_access_token(agent)]
    )
  end
end
