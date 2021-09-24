defmodule WeChat.Work.Contacts.User do
  @moduledoc "通讯录管理-成员管理"

  import WeChat.Utils, only: [work_doc_link_prefix: 0]
  alias WeChat.Work
  alias Work.Contacts.Department

  @doc_link "#{work_doc_link_prefix()}/90135"

  @typedoc """
  每个成员都有唯一的 userid -
  [官方文档](#{@doc_link}/90665#userid)

  即所谓“帐号”。在管理后台->“通讯录”->点进某个成员的详情页，可以看到。
  """
  @type userid :: String.t()
  @type userid_list :: [userid]

  @doc """
  读取成员 -
  [官方文档](#{@doc_link}/92196){:target="_blank"}

  在通讯录同步助手中此接口可以读取企业通讯录的所有成员信息，而自建应用可以读取该应用设置的可见范围内的成员信息。
  """
  @spec get_user(Work.client(), userid) :: WeChat.response()
  def get_user(client, userid) do
    client.get("/cgi-bin/user/get",
      query: [userid: userid, access_token: client.get_access_token(:contacts)]
    )
  end

  @doc """
  获取部门成员列表(简要) -
  [官方文档](#{@doc_link}/90200){:target="_blank"}

  获取部门成员列表

  `fetch_child` 是否递归获取子部门下面的成员：
  - `1`: 递归获取
  - `0`: 只获取本部门
  """
  @spec get_department_users(Work.client(), Department.party_id()) :: WeChat.response()
  def get_department_users(client, department_id, fetch_child \\ 0) do
    client.get("/cgi-bin/user/simplelist",
      query: [
        department_id: department_id,
        fetch_child: fetch_child,
        access_token: client.get_access_token(:contacts)
      ]
    )
  end

  @doc """
  获取部门成员列表(详情) -
  [官方文档](#{@doc_link}/90201){:target="_blank"}

  获取部门成员列表(详情)

  `fetch_child` 是否递归获取子部门下面的成员：
  - `1`: 递归获取
  - `0`: 只获取本部门
  """
  @spec get_department_users_detail(Work.client(), Department.party_id()) :: WeChat.response()
  def get_department_users_detail(client, department_id, fetch_child \\ 0) do
    client.get("/cgi-bin/user/list",
      query: [
        department_id: department_id,
        fetch_child: fetch_child,
        access_token: client.get_access_token(:contacts)
      ]
    )
  end

  @doc """
  userid转openid -
  [官方文档](#{@doc_link}/90202){:target="_blank"}

  该接口使用场景为企业支付，在使用企业红包和向员工付款时，需要自行将企业微信的 `userid` 转成 `openid`。

  注：需要成员使用微信登录企业微信或者关注微工作台（原企业号）才能转成 `openid`;
  如果是外部联系人，请使用外部联系人 `openid` 转换 `openid`
  """
  @spec userid2openid(Work.client(), userid) :: WeChat.response()
  def userid2openid(client, userid) do
    client.post("/cgi-bin/user/convert_to_openid", %{"userid" => userid},
      query: [access_token: client.get_access_token(:contacts)]
    )
  end

  @doc """
  openid转userid -
  [官方文档](#{@doc_link}/90202){:target="_blank"}

  该接口主要应用于使用企业支付之后的结果查询。
  开发者需要知道某个结果事件的 `openid` 对应企业微信内成员的信息时，可以通过调用该接口进行转换查询。
  """
  @spec openid2userid(Work.client(), WeChat.openid()) :: WeChat.response()
  def openid2userid(client, openid) do
    client.post("/cgi-bin/user/convert_to_userid", %{"openid" => openid},
      query: [access_token: client.get_access_token(:contacts)]
    )
  end
end
