defmodule WeChat.Work.App do
  @moduledoc "应用管理"

  import WeChat.Work.Agent, only: [agent2id: 2]
  alias WeChat.Work

  @typep opts :: Enumerable.t()
  @typep redirect_uri :: String.t()

  @doc """
  获取指定的应用详情 -
  [官方文档](https://developer.work.weixin.qq.com/document/path/90227#获取指定的应用详情){:target="_blank"}
  """
  @spec get(Work.client(), Work.agent()) :: WeChat.response()
  def get(client, agent) do
    client.get("/cgi-bin/agent/get",
      query: [
        agentid: agent2id(client, agent),
        access_token: client.get_access_token(agent)
      ]
    )
  end

  @doc """
  获取access_token对应的应用列表 -
  [官方文档](https://developer.work.weixin.qq.com/document/path/90227#获取access-token对应的应用列表){:target="_blank"}
  """
  @spec list(Work.client(), Work.agent()) :: WeChat.response()
  def list(client, agent) do
    client.get("/cgi-bin/agent/list",
      query: [access_token: client.get_access_token(agent)]
    )
  end

  @doc """
  设置应用 - [官方文档](https://developer.work.weixin.qq.com/document/path/90228){:target="_blank"}
  """
  @spec set(Work.client(), Work.agent(), opts) :: WeChat.response()
  def set(client, agent, opts \\ []) do
    client.post(
      "/cgi-bin/agent/set",
      Map.new(opts) |> Map.put("agentid", agent2id(client, agent)),
      query: [access_token: client.get_access_token(agent)]
    )
  end

  @doc """
  构造独立窗口登录二维码 - [官方文档](https://developer.work.weixin.qq.com/document/path/91019#构造独立窗口登录二维码){:target="_blank"}
  """
  @spec qr_connect_url(
          WeChat.client(),
          Work.agent(),
          redirect_uri,
          state :: String.t(),
          lang :: String.t()
        ) :: url :: String.t()
  def qr_connect_url(client, agent, redirect_uri, state \\ "", lang \\ "") do
    [
      "https://open.work.weixin.qq.com/wwopen/sso/qrConnect?",
      ["appid=", client.appid()],
      ["&agentid=", to_string(agent2id(client, agent))],
      ["&redirect_uri=", URI.encode_www_form(redirect_uri)],
      if match?("", state) do
        []
      else
        ["&state=", state]
      end,
      if match?("", lang) do
        []
      else
        ["&lang=", lang]
      end
    ]
    |> IO.iodata_to_binary()
  end

  @doc """
  构造内嵌登录二维码 - [官方文档](https://developer.work.weixin.qq.com/document/path/91019#构造内嵌登录二维码){:target="_blank"}
  """
  @spec qr_connect_opts(WeChat.client(), Work.agent(), redirect_uri, opts) :: opts :: map
  def qr_connect_opts(client, agent, redirect_uri, opts \\ []) do
    Map.new(opts)
    |> Map.merge(%{
      "appid" => client.appid(),
      "agentid" => agent2id(client, agent),
      "redirect_uri" => URI.encode_www_form(redirect_uri)
    })
  end

  @doc """
  获取访问用户身份 - [官方文档](https://developer.work.weixin.qq.com/document/path/91437){:target="_blank"}

  该接口用于根据code获取成员信息

  - 当用户为企业成员时返回：`UserId`
  - 当用户为企业成员时返回：`OpenId`
  """
  @spec sso_user_info(WeChat.client(), Work.agent(), code :: String.t()) :: WeChat.response()
  def sso_user_info(client, agent, code) do
    client.get("/cgi-bin/user/getuserinfo",
      query: [code: code, access_token: client.get_access_token(agent)]
    )
  end
end
