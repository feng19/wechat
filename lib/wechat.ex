defmodule WeChat do
  @moduledoc """
  WeChat SDK for Elixir

  ## 定义 Client 模块

  ### 公众号(默认)

      defmodule YourApp.WeChatAppCodeName do
        @moduledoc "CodeName"
        use WeChat,
          appid: "wx-appid",
          appsecret: "appsecret"
      end

  ### 小程序

      defmodule YourApp.WeChatAppCodeName do
        @moduledoc "CodeName"
        use WeChat,
          app_type: :mini_program,
          appid: "wx-appid",
          appsecret: "appsecret"
      end

  ### 第三方应用

      defmodule YourApp.WeChatAppCodeName do
        @moduledoc "CodeName"
        use WeChat,
          by_component?: true,
          app_type: :official_account | :mini_program, # 默认为 :official_account
          appid: "wx-appid",
          component_appid: "wx-third-appid", # 第三方 appid
      end

  ## 定义参数说明

  请看 `t:options/0`

  ## 接口调用

  支持两种方式调用:

  - 调用 `client` 方法:

    `YourApp.WeChatAppCodeName.Material.batch_get_material(:image, 2)`

  - 原生调用方法

    `WeChat.Material.batch_get_material(YourApp.WeChatAppCodeName, :image, 2)`

  ## 企业微信

  详情请看 `WeChat.Work`

  ## 微信支付

  详情请看 `WeChat.Pay`
  """
  import WeChat.Utils, only: [doc_link_prefix: 0]
  alias WeChat.{Refresher, HubClient, HubServer}
  alias WeChat.Work.Agent, as: WorkAgent

  @typedoc """
  OpenID 普通用户的标识，对当前公众号唯一

  加密后的微信号，每个用户对每个公众号的 `OpenID` 是唯一的。对于不同公众号，同一用户的 `OpenID` 不同

  [Docs Link](#{doc_link_prefix()}/doc/offiaccount/User_Management/Get_users_basic_information_UnionID.html){:target="_blank"}
  """
  @type openid :: String.t()
  @type openid_list :: [openid]

  @typedoc """
  UnionID 不同应用下的唯一ID

  同一用户，对同一个微信开放平台下的不同应用，`UnionID` 是相同的

  [Docs Link](#{doc_link_prefix()}/doc/offiaccount/User_Management/Get_users_basic_information_UnionID.html){:target="_blank"}
  """
  @type unionid :: String.t()

  @typedoc """
  服务器角色

  `:client`: 默认，主动刷新 `AccessToken`
  `:hub`: 中控服务器，主动刷新 `AccessToken`
  `:hub_client`: 逻辑服务器，从 `hub` 获取 `AccessToken`
  """
  @type server_role :: :client | :hub | :hub_client
  @typedoc "是否第三方平台开发"
  @type by_component? :: boolean
  @typedoc """
  `client` 的应用类型

  - `:official_account`: 公众号
  - `:mini_program`: 小程序
  """
  @type app_type :: :official_account | :mini_program
  @typedoc "公众号/小程序 应用id"
  @type appid :: String.t()
  @typedoc "公众号/小程序 应用代码"
  @type code_name :: String.t()
  @typedoc "应用秘钥"
  @type appsecret :: String.t()
  @typedoc "第三方平台应用id"
  @type component_appid :: String.t()
  @typedoc "第三方平台应用秘钥"
  @type component_appsecret :: String.t()
  @typedoc """
  服务器配置里的 `token` 值，在接收消息时用于校验签名
  """
  @type token :: String.t()
  @typedoc "错误码"
  @type err_code :: non_neg_integer
  @typedoc "错误信息"
  @type err_msg :: String.t()
  @type env_option :: :runtime_env | {:runtime_env, app} | :compile_env | {:compile_env, app}
  @typep app :: atom

  @typedoc """
  参数

  ## 参数说明

  - `appid`: 应用ID，必填
  - `app_type`: 应用类型, 默认值: `:official_account`
  - `code_name`: 如不指定，默认为模块名最后一个名称的全小写格式
  - `by_component?`: 是否第三方平台开发, 默认值: `false`
  - `server_role`: 服务器角色, 默认值: `:client`
  - `storage`: 存储器, 默认值: `WeChat.Storage.File`
  - `appsecret`: 应用秘钥, 仅在 `by_component?` 设定为 `false` 时才有效
  - `component_appid`: 第三方平台应用id, 仅在 `by_component?` 设定为 `true` 时才有效
  - `component_appsecret`: 第三方平台应用秘钥, 仅在 `by_component?` 设定为 `true` 时才有效
  - `encoding_aes_key`: 在编译时会自动将 `encoding_aes_key` 转换为 `aes_key`
  - `token`: Token
  - `requester`: 请求客户端, 默认值: `WeChat.Requester`
  - `gen_sub_module?`: 是否生成子模块，默认值: true
  - `sub_modules`: 指定生成子模块的列表
  """
  @type options :: [
          server_role: server_role | env_option,
          by_component?: by_component? | env_option,
          app_type: app_type | env_option,
          storage: WeChat.Storage.Adapter.t() | env_option,
          appid: appid,
          appsecret: appsecret | env_option,
          component_appid: component_appid,
          component_appsecret: component_appsecret | env_option,
          encoding_aes_key: WeChat.ServerMessage.Encryptor.encoding_aes_key() | env_option,
          token: token | env_option,
          requester: module
        ]
  @type client :: module
  @type requester :: module
  @type response :: Tesla.Env.result()
  @type start_options :: %{
          optional(:hub_springboard_url) => HubClient.hub_springboard_url(),
          optional(:oauth2_callbacks) => HubServer.oauth2_callbacks(),
          optional(:refresh_before_expired) => Refresher.Default.refresh_before_expired(),
          optional(:refresh_retry_interval) => Refresher.Default.refresh_retry_interval(),
          optional(:refresh_options) => Refresher.DefaultSettings.refresh_options()
        }

  @doc false
  defmacro __using__(options \\ []) do
    quote do
      use WeChat.Builder.OfficialAccount, unquote(options)
    end
  end

  @doc """
  通过 `appid` 或者 `code_name` 获取 `client`
  """
  @spec get_client(appid | code_name) :: nil | client
  defdelegate get_client(app_flag), to: WeChat.Storage.Cache, as: :search_client

  @spec get_client_agent(appid | code_name, WeChat.Work.agent() | String.t()) ::
          nil | {client, WorkAgent.t()}
  defdelegate get_client_agent(app_flag, agent_flag),
    to: WeChat.Storage.Cache,
    as: :search_client_agent

  @doc "动态构建 client"
  @spec build_client(client, options) :: {:ok, client}
  def build_client(client, options) do
    with {:module, module, _binary, _term} <-
           Module.create(
             client,
             quote do
               @moduledoc false
               use WeChat.Builder.OfficialAccount, unquote(Macro.escape(options))
             end,
             Macro.Env.location(__ENV__)
           ) do
      {:ok, module}
    end
  end

  @doc "动态启动 client"
  @spec start_client(client, start_options) :: :ok
  def start_client(client, options \\ %{}) do
    {setup_options, options} = Map.split(options, [:hub_springboard_url, :oauth2_callbacks])

    if match?(:work, client.app_type()) do
      WeChat.Setup.setup_work_client(client, setup_options)
    else
      WeChat.Setup.setup_client(client, setup_options)
    end

    if Map.get(options, :refresh_token?, true) do
      if Map.get(options, :check_token?, true) and client.app_type() != :work do
        WeChat.TokenChecker.add_to_check_clients(client)
      end

      add_to_refresher(client, options)
    end

    :ok
  end

  @doc "动态关闭 client"
  @spec shutdown_client(client) :: :ok
  def shutdown_client(client) do
    if client.app_type() != :work do
      WeChat.TokenChecker.remove_from_check_clients(client)
      WeChat.TokenChecker.remove_client(client)
    end

    module = refresher()
    module.remove(client)
    HubServer.clean_oauth2_callbacks(client)
    WeChat.Storage.Cache.clean(client)
  end

  @doc """
  刷新器
    
  默认为 `WeChat.Refresher.Default`
  """
  @spec refresher :: module
  def refresher do
    Application.get_env(:wechat, :refresher, Refresher.Default)
  end

  @doc "将 client 添加到刷新器"
  @spec add_to_refresher(client, Refresher.Default.client_setting()) :: :ok
  def add_to_refresher(client, options \\ %{}) do
    module = refresher()
    module.add(client, options)
  end
end
