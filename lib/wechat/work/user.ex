defmodule WeChat.Work.User do
  @moduledoc "成员管理"

  import WeChat.Utils, only: [work_doc_link_prefix: 0]
  alias WeChat.Work

  @doc_link "#{work_doc_link_prefix()}/90000/90135"

  @typedoc """
  每个成员都有唯一的 userid -
  [官方文档](#{@doc_link}/90665#userid)

  即所谓“帐号”。在管理后台->“通讯录”->点进某个成员的详情页，可以看到。
  """
  @type user_id :: String.t()

  @doc """
  读取成员 -
  [官方文档](#{@doc_link}/92196){:target="_blank"}

  在通讯录同步助手中此接口可以读取企业通讯录的所有成员信息，而自建应用可以读取该应用设置的可见范围内的成员信息。
  """
  @spec get_user(Work.client(), Work.agent(), user_id) :: WeChat.response()
  def get_user(client, agent, user_id) do
    client.get("/cgi-bin/user/get",
      query: [userid: user_id, access_token: client.get_access_token(agent)]
    )
  end
end
