defmodule WeChat.Work.OA.Pstncc do
  @moduledoc "紧急通知"

  import Jason.Helpers
  alias WeChat.Work
  alias Work.Contacts.User

  @typedoc "发起自动语音来电ID"
  @type call_id :: String.t()

  @doc """
  发起语音电话
  - [官方文档](https://developer.work.weixin.qq.com/document/path/91627){:target="_blank"}
  """
  @spec call(Work.client(), Work.agent(), User.userid_list()) :: WeChat.response()
  def call(client, agent, userid_list) do
    client.post("/cgi-bin/pstncc/call", json_map(callee_userid: userid_list),
      query: [access_token: client.get_access_token(agent)]
    )
  end

  @doc """
  获取接听状态
  - [官方文档](https://developer.work.weixin.qq.com/document/path/91628){:target="_blank"}
  """
  @spec get_states(Work.client(), Work.agent(), User.userid(), call_id) :: WeChat.response()
  def get_states(client, agent, userid, call_id) do
    client.post("/cgi-bin/pstncc/getstates", json_map(callee_userid: userid, callid: call_id),
      query: [access_token: client.get_access_token(agent)]
    )
  end
end
