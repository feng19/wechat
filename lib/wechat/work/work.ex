defmodule WeChat.Work do
  @moduledoc """
  企业微信

  ```elixir
  use WeChat.Work,
    corp_id: "corp_id",
    agents: [
      contacts_agent(secret: "contacts_secret"),
      customer_agent(secret: "customer_secret"),
      agent(10000, name: :agent_name, secret: "agent_secret"),
      ...
    ]
  ```
  """
  import WeChat.Utils, only: [work_doc_link_prefix: 0]
  alias WeChat.Work.Agent

  @doc_link "#{work_doc_link_prefix()}/90135"

  @type client :: module()

  @typedoc """
  每个企业都拥有唯一的 corpid -
  [官方文档](#{@doc_link}/90665#corpid)

  获取此信息可在管理后台“我的企业”－“企业信息”下查看“企业ID”（需要有管理员权限）

  """
  @type corp_id :: String.t()

  @typedoc """
  每个应用都有唯一的 agentid -
  [官方文档](#{@doc_link}/90665#agentid)

  在管理后台->“应用与小程序”->“应用”，点进某个应用，即可看到 agentid
  """
  @type agent_id :: Agent.agent_id()
  @type agent_name :: Agent.agent_name()
  @type agent :: agent_name | agent_id
  @type agents :: [Agent.t(), ...]

  @typedoc """
  secret 是企业应用里面用于保障数据安全的“钥匙” -
  [官方文档](#{@doc_link}/90665#secret)

  每一个应用都有一个独立的访问密钥，为了保证数据的安全，secret务必不能泄漏。
  目前 `secret` 有：

  - 自建应用 `secret`
    在管理后台->“应用与小程序”->“应用”->“自建”，点进某个应用，即可看到。
  - 基础应用 `secret`
    某些基础应用（如“审批”“打卡”应用），支持通过API进行操作。在管理后台->“应用与小程序”->“应用->”“基础”，点进某个应用，点开“API”小按钮，即可看到。
  - 通讯录管理 `secret`
    在“管理工具”-“通讯录同步”里面查看（需开启“API接口同步”）；
  - 外部联系人管理 `secret`
    在“客户联系”栏，点开“API”小按钮，即可看到。
  """
  @type secret :: Agent.secret()

  @typedoc """
  参数

  ## 参数说明

  - `corp_id`: `t:corp_id/0` - 必填
  - `agents`: 应用列表 - `t:agents/0` - 必填 & 至少一个
  - `server_role`: `t:WeChat.server_role/0`
  - `storage`: `t:WeChat.Storage.Adapter.t/0`
  - `requester`: 请求客户端 - `t:module/0`

  ## 默认参数:

  - `server_role`: `:client`
  - `storage`: `WeChat.Storage.File`
  - `requester`: `WeChat.WorkRequester`
  - 其余参数皆为可选
  """
  @type options :: [
          corp_id: corp_id,
          agents: agents,
          server_role: WeChat.server_role(),
          storage: WeChat.Storage.Adapter.t(),
          requester: module
        ]

  @typedoc """
  access_token 是企业后台去企业微信的后台获取信息时的重要票据 -
  [官方文档](#{@doc_link}/90665#access_token)

  由 `corpid` 和 `secret` 产生。所有接口在通信时都需要携带此信息用于验证接口的访问权限
  """
  @type access_token :: String.t()

  @doc false
  defmacro __using__(options \\ []) do
    quote do
      import WeChat.Work.Agent,
        only: [agent: 1, agent: 2, contacts_agent: 1, customer_agent: 1, kf_agent: 1]

      use WeChat.Builder.Work, unquote(options)
    end
  end

  @doc "动态构建 client"
  @spec build_client(client, options) :: {:ok, client}
  def build_client(client, options) do
    with {:module, module, _binary, _term} <-
           Module.create(
             client,
             quote do
               @moduledoc false
               use WeChat.Builder.Work, unquote(Macro.escape(options))
             end,
             Macro.Env.location(__ENV__)
           ) do
      {:ok, module}
    end
  end

  @doc """
  获取 access_token - [官方文档](#{@doc_link}/91039){:target="_blank"}
  """
  @spec get_access_token(client, agent) :: WeChat.response()
  def get_access_token(client, agent) do
    corp_secret = client.agent_secret(agent)

    client.get("/cgi-bin/gettoken",
      query: [corpid: client.appid(), corpsecret: corp_secret]
    )
  end
end
