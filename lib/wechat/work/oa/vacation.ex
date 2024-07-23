defmodule WeChat.Work.OA.Vacation do
  @moduledoc "假期管理"

  import Jason.Helpers
  alias WeChat.Work
  alias Work.Contacts.User

  @typedoc "假期ID"
  @type vacation_id :: integer
  @typedoc """
  假期余额

  单位为秒
  不能大于1000天或24000小时，当假期时间刻度为

  - 按小时请假时，必须为360整倍数，即0.1小时整倍数，
  - 按天请假时，必须为8640整倍数，即0.1天整倍数
  """
  @type left_duration :: integer
  @typedoc """
  假期时间刻度

  - `0`: 按天请假
  - `1`: 按小时请假

  主要用于校验，必须等于企业假期管理配置中设置的假期时间刻度类型
  """
  @type time_attr :: 0 | 1
  @typedoc """
  备注

  用于显示在假期余额的修改记录当中，可对修改行为作说明，不超过200字符
  """
  @type remarks :: String.t()

  @doc """
  获取企业假期管理配置
  - [官方文档](https://developer.work.weixin.qq.com/document/path/93375){:target="_blank"}
  """
  @spec list_configs(Work.client(), Work.agent()) :: WeChat.response()
  def list_configs(client, agent) do
    client.get("/cgi-bin/oa/vacation/getcorpconf",
      query: [access_token: client.get_access_token(agent)]
    )
  end

  @doc """
  获取成员假期余额
  - [官方文档](https://developer.work.weixin.qq.com/document/path/93376){:target="_blank"}
  """
  @spec get_user_quota(Work.client(), Work.agent(), User.userid()) :: WeChat.response()
  def get_user_quota(client, agent, userid) do
    client.post("/cgi-bin/vacation/getuservacationquota", json_map(userid: userid),
      query: [access_token: client.get_access_token(agent)]
    )
  end

  @doc """
  修改成员假期余额
  - [官方文档](https://developer.work.weixin.qq.com/document/path/93377){:target="_blank"}
  """
  @spec set_user_quota(
          Work.client(),
          Work.agent(),
          User.userid(),
          vacation_id,
          left_duration,
          time_attr,
          remarks
        ) :: WeChat.response()
  def set_user_quota(client, agent, userid, vacation_id, left_duration, time_attr, remarks \\ "") do
    client.post(
      "/cgi-bin/vacation/setoneuserquota",
      json_map(
        userid: userid,
        vacation_id: vacation_id,
        leftduration: left_duration,
        time_attr: time_attr,
        remarks: remarks
      ),
      query: [access_token: client.get_access_token(agent)]
    )
  end
end
