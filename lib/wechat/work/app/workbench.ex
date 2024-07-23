defmodule WeChat.Work.App.Workbench do
  @moduledoc """
  工作台

  首先需要通过“设置应用在工作台展示的模版”接口设置应用自定义模版类型。然后再通过“设置应用在用户工作台展示的数据”接口设置用户模版数据。

  “设置应用在工作台展示的模版”同时也支持设置一个默认的企业级别的模版数据。在用户数据未设置的情况下，会展示企业级别的默认数据。

  若为第三方应用，目前仅支持行业类型为 **学前教育、初中等教育、教育行政单位** 的企业可看到自定义工作台设置入口
  """

  import Jason.Helpers
  import WeChat.Work.Agent, only: [agent2id: 2]
  alias WeChat.Work
  alias Work.Contacts.User

  @typedoc """
  模版类型

  - `normal`: 取消自定义模式，改为普通展示模式
  - `keydata`: 关键数据型
  - `image`: 图片型
  - `list`: 列表型
  - `webview`: webview型
  """
  @type type :: String.t()
  @type opts :: Enumerable.t()

  @doc """
  设置应用在工作台展示的模版 -
  [官方文档](https://developer.work.weixin.qq.com/document/path/92535#设置应用在工作台展示的模版){:target="_blank"}

  该接口指定应用自定义模版类型。同时也支持设置企业默认模版数据。若type指定为 “normal” 则为取消自定义模式，改为普通展示模式
  """
  @spec set_template(
          Work.client(),
          Work.agent(),
          type,
          type_map :: map,
          replace_user_data :: boolean
        ) :: WeChat.response()
  def set_template(client, agent, type, type_map, replace_user_data \\ false) do
    client.post(
      "/cgi-bin/agent/set_workbench_template",
      %{
        "agentid" => agent2id(client, agent),
        "type" => type,
        type => type_map,
        "replace_user_data" => replace_user_data
      },
      query: [access_token: client.get_access_token(agent)]
    )
  end

  @doc """
  获取应用在工作台展示的模版 -
  [官方文档](https://developer.work.weixin.qq.com/document/path/92535#获取应用在工作台展示的模版){:target="_blank"}

  该接口指定应用自定义模版类型。同时也支持设置企业默认模版数据。若type指定为 “normal” 则为取消自定义模式，改为普通展示模式
  """
  @spec get_template(Work.client(), Work.agent()) :: WeChat.response()
  def get_template(client, agent) do
    client.post(
      "/cgi-bin/agent/get_workbench_template",
      json_map(agentid: agent2id(client, agent)),
      query: [access_token: client.get_access_token(agent)]
    )
  end

  @doc """
  设置应用在用户工作台展示的数据 -
  [官方文档](https://developer.work.weixin.qq.com/document/path/92535#设置应用在用户工作台展示的数据){:target="_blank"}

  **每个用户每个应用接口限制10次/分钟**
  """
  @spec set_data(
          Work.client(),
          Work.agent(),
          User.userid(),
          type,
          type_map :: map,
          replace_user_data :: boolean
        ) :: WeChat.response()
  def set_data(client, agent, userid, type, type_map, replace_user_data \\ false) do
    client.post(
      "/cgi-bin/agent/set_workbench_data",
      %{
        "agentid" => agent2id(client, agent),
        "userid" => userid,
        "type" => type,
        type => type_map,
        "replace_user_data" => replace_user_data
      },
      query: [access_token: client.get_access_token(agent)]
    )
  end
end
