defmodule WeChat.Work.MiniProgram do
  @moduledoc "小程序"

  import WeChat.Utils, only: [work_doc_link_prefix: 0]
  alias WeChat.Work

  @doc_link "#{work_doc_link_prefix()}/90136"

  @doc """
  登录 - [官方文档](#{@doc_link}/91507){:target="_blank"}

  [登录流程](#{@doc_link}/92426){:target="_blank"}

  临时登录凭证校验接口是一个服务端 HTTPS 接口，开发者服务器使用临时登录凭证code获取 session_key、用户userid以及用户所在企业的corpid等信息。
  """
  @spec code2session(Work.client(), Work.agent(), code :: String.t()) :: WeChat.response()
  def code2session(client, agent, code) do
    agent = Work.Agent.fetch_agent!(client, agent)

    client.get("/cgi-bin/miniprogram/jscode2session",
      query: [
        appid: client.appid(),
        secret: agent.secret,
        js_code: code,
        grant_type: "authorization_code"
      ]
    )
  end
end
