defmodule WeChat.Work.OA.Checkin do
  @moduledoc "OA - 打卡"

  import Jason.Helpers
  alias WeChat.Work
  alias Work.Contacts.User

  @doc_link WeChat.Utils.work_doc_link_prefix()

  @typedoc """
  打卡类型

  - `1`: 上下班打卡
  - `2`: 外出打卡
  - `3`: 全部打卡
  """
  @type type :: 1..3
  @type timestamp :: integer
  @typep start_time :: timestamp
  @typep end_time :: timestamp
  @typedoc "打卡规则的规则ID"
  @type group_id :: integer
  @typedoc "对应 `group_id` 规则下的班次id，通过预先拉取规则信息获取，0代表休息"
  @type schedule_id :: integer
  @typedoc "排班表月份，格式为年月，如202011"
  @type year_month :: String.t()
  @typedoc "要设置的天日期，取值在1-31之间。联合 `year_month` 组成唯一日期 比如20201205"
  @type day :: 1..31
  @typedoc "过滤类型，1表示按打卡时间过滤，2表示按设备上传打卡记录的时间过滤，默认值是1"
  @type filter_type :: 1 | 2

  @doc """
  获取企业所有打卡规则
  - [官方文档](#{@doc_link}/93384){:target="_blank"}
  """
  @spec list_options(Work.client(), Work.agent()) :: WeChat.response()
  def list_options(client, agent) do
    client.post("/cgi-bin/checkin/getcorpcheckinoption", "{}",
      query: [access_token: client.get_access_token(agent)]
    )
  end

  @doc """
  获取员工打卡规则
  - [官方文档](#{@doc_link}/90263){:target="_blank"}
  """
  @spec get_user_option(Work.client(), Work.agent(), timestamp, User.userid_list()) ::
          WeChat.response()
  def get_user_option(client, agent, timestamp, userid_list) do
    client.post(
      "/cgi-bin/checkin/getcheckinoption",
      json_map(datetime: timestamp, useridlist: userid_list),
      query: [access_token: client.get_access_token(agent)]
    )
  end

  @doc """
  获取打卡记录数据
  - [官方文档](#{@doc_link}/90262){:target="_blank"}
  """
  @spec list_data(Work.client(), Work.agent(), type, start_time, end_time, User.userid_list()) ::
          WeChat.response()
  def list_data(client, agent, type, start_time, end_time, userid_list) do
    client.post(
      "/cgi-bin/checkin/getcheckindata",
      json_map(
        opencheckindatatype: type,
        starttime: start_time,
        endtime: end_time,
        useridlist: userid_list
      ),
      query: [access_token: client.get_access_token(agent)]
    )
  end

  @doc """
  获取打卡日报数据
  - [官方文档](#{@doc_link}/93374){:target="_blank"}
  """
  @spec list_day_data(Work.client(), Work.agent(), start_time, end_time, User.userid_list()) ::
          WeChat.response()
  def list_day_data(client, agent, start_time, end_time, userid_list) do
    client.post(
      "/cgi-bin/checkin/getcheckin_daydata",
      json_map(
        starttime: start_time,
        endtime: end_time,
        useridlist: userid_list
      ),
      query: [access_token: client.get_access_token(agent)]
    )
  end

  @doc """
  获取打卡月报数据
  - [官方文档](#{@doc_link}/93387){:target="_blank"}
  """
  @spec list_month_data(Work.client(), Work.agent(), start_time, end_time, User.userid_list()) ::
          WeChat.response()
  def list_month_data(client, agent, start_time, end_time, userid_list) do
    client.post(
      "/cgi-bin/checkin/getcheckin_monthdata",
      json_map(
        starttime: start_time,
        endtime: end_time,
        useridlist: userid_list
      ),
      query: [access_token: client.get_access_token(agent)]
    )
  end

  @doc """
  获取打卡人员排班信息
  - [官方文档](#{@doc_link}/93380){:target="_blank"}
  """
  @spec list_scheduling(Work.client(), Work.agent(), start_time, end_time, User.userid_list()) ::
          WeChat.response()
  def list_scheduling(client, agent, start_time, end_time, userid_list) do
    client.post(
      "/cgi-bin/checkin/getcheckinschedulist",
      json_map(
        starttime: start_time,
        endtime: end_time,
        useridlist: userid_list
      ),
      query: [access_token: client.get_access_token(agent)]
    )
  end

  @doc """
  为打卡人员排班
  - [官方文档](#{@doc_link}/93385){:target="_blank"}
  """
  @spec set_scheduling(
          Work.client(),
          Work.agent(),
          group_id,
          year_month,
          items :: list({User.userid(), day, schedule_id})
        ) :: WeChat.response()
  def set_scheduling(client, agent, group_id, year_month, items) do
    items =
      Enum.map(items, fn {userid, day, schedule_id} ->
        json_map(
          userid: userid,
          day: day,
          schedule_id: schedule_id
        )
      end)

    client.post(
      "/cgi-bin/checkin/setcheckinschedulist",
      json_map(
        groupid: group_id,
        items: items,
        yearmonth: year_month
      ),
      query: [access_token: client.get_access_token(agent)]
    )
  end

  @doc """
  为打卡人员补卡
  - [官方文档](#{@doc_link}/95803){:target="_blank"}
  """
  @spec re_checkin(
          Work.client(),
          Work.agent(),
          User.userid(),
          schedule_date_time :: timestamp,
          schedule_checkin_time :: timestamp,
          checkin_time :: timestamp,
          remark :: String.t()
        ) :: WeChat.response()
  def re_checkin(
        client,
        agent,
        userid,
        schedule_date_time,
        schedule_checkin_time \\ nil,
        checkin_time,
        remark \\ ""
      ) do
    body =
      if schedule_checkin_time do
        json_map(
          userid: userid,
          schedule_date_time: schedule_date_time,
          schedule_checkin_time: schedule_checkin_time,
          checkin_time: checkin_time,
          remark: remark
        )
      else
        json_map(
          userid: userid,
          schedule_date_time: schedule_date_time,
          checkin_time: checkin_time,
          remark: remark
        )
      end

    client.post("/cgi-bin/checkin/punch_correction", body,
      query: [access_token: client.get_access_token(agent)]
    )
  end

  @doc """
  录入打卡人员人脸信息
  - [官方文档](#{@doc_link}/93378){:target="_blank"}
  """
  @spec set_user_face(Work.client(), Work.agent(), User.userid(), user_face :: String.t()) ::
          WeChat.response()
  def set_user_face(client, agent, userid, user_face) do
    client.post(
      "/cgi-bin/checkin/addcheckinuserface",
      json_map(userid: userid, userface: user_face),
      query: [access_token: client.get_access_token(agent)]
    )
  end

  @doc """
  获取设备打卡数据
  - [官方文档](#{@doc_link}/94126){:target="_blank"}
  """
  @spec get_hardware_checkin_data(
          Work.client(),
          Work.agent(),
          filter_type,
          start_time,
          end_time,
          User.userid_list()
        ) :: WeChat.response()
  def get_hardware_checkin_data(
        client,
        agent,
        filter_type \\ 1,
        start_time,
        end_time,
        userid_list
      ) do
    client.post(
      "/cgi-bin/hardware/get_hardware_checkin_data",
      json_map(
        filter_type: filter_type,
        starttime: start_time,
        endtime: end_time,
        useridlist: userid_list
      ),
      query: [access_token: client.get_access_token(agent)]
    )
  end
end
