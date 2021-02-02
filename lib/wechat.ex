defmodule WeChat do
  @moduledoc """
  WeChat SDK for Elixir

  ## 定义 `Client` 模块

  ### 公众号(默认):

  ```elixir
  defmodule YourApp.WeChatAppCodeName do
  @moduledoc "CodeName"
  use WeChat,
    appid: "wx-appid",
    appsecret: "appsecret"
  end
  ```

  ### 小程序:

  ```elixir
  defmodule YourApp.WeChatAppCodeName do
  @moduledoc "CodeName"
  use WeChat,
    app_type: :mini_program,
    appid: "wx-appid",
    appsecret: "appsecret"
  end
  ```

  ### 第三方应用:

  ```elixir
  defmodule YourApp.WeChatAppCodeName do
  @moduledoc "CodeName"
  use WeChat,
    by_component?: true,
    app_type: :official_account | :mini_program, # 默认为 :official_account
    appid: "wx-appid",
    component_appid: "wx-third-appid", # 第三方 appid
  end
  ```

  ## 参数说明

  请看 `t:options/0`

  ## 接口调用

  支持两种方式调用:

  - 调用 `client` 方法

      `YourApp.WeChatAppCodeName.Material.batch_get_material(:image, 2)`

  - 原生调用方法

      `WeChat.Material.batch_get_material(YourApp.WeChatAppCodeName, :image, 2)`

  """
  import WeChat.Utils, only: [doc_link_prefix: 0]

  @typedoc """
  OpenID 普通用户的标识，对当前公众号唯一

  加密后的微信号，每个用户对每个公众号的 `OpenID` 是唯一的。对于不同公众号，同一用户的 `OpenID` 不同

  [Docs Link](#{doc_link_prefix()}/doc/offiaccount/User_Management/Get_users_basic_information_UnionID.html){:target="_blank"}
  """
  @type openid :: String.t()

  @typedoc """
  UnionID 不同应用下的唯一ID

  同一用户，对同一个微信开放平台下的不同应用，`UnionID` 是相同的

  [Docs Link](#{doc_link_prefix()}/doc/offiaccount/User_Management/Get_users_basic_information_UnionID.html){:target="_blank"}
  """
  @type unionid :: String.t()

  @typedoc """
  服务器角色

  `:client`: 默认，刷新`token`
  `:hub`: 中控服务器，刷新`token`
  `:hub_client`: 逻辑服务器，获取`token`
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

  @typedoc """
  参数

  ## 参数说明

  - `appid`: `t:appid/0` - 必填
  - `app_type`: `t:app_type/0`
  - `by_component?`: `t:by_component?/0`
  - `server_role`: `t:server_role/0`
  - `storage`: `t:WeChat.Storage.Adapter.t()`
  - `appsecret`: `t:appsecret/0` - 仅在 `by_component?` 设定为 `false` 时才有效
  - `component_appid`: `t:component_appid/0` - 仅在 `by_component?` 设定为 `true` 时才有效
  - `component_appsecret`: `t:component_appsecret/0` - 仅在 `by_component?` 设定为 `true` 时才有效
  - `encoding_aes_key`: `t:WeChat.ServerMessage.Encryptor.encoding_aes_key/0` - 在编译时会自动将 `encoding_aes_key` 转换为 `aes_key`
  - `token`: `t:token/0`
  - `requester`: 请求客户端 - `t:module/0`

  ## 默认参数:

  - `server_role`: `:client`
  - `by_component?`: `false`
  - `app_type`: `:official_account`
  - `storage`: `WeChat.Storage.File`
  - `requester`: `WeChat.Requester`
  - 其余参数皆为可选
  """
  @type options :: [
          server_role: server_role,
          by_component?: by_component?,
          app_type: app_type,
          storage: WeChat.Storage.Adapter.t(),
          appid: appid,
          appsecret: appsecret,
          component_appid: component_appid,
          component_appsecret: component_appsecret,
          encoding_aes_key: WeChat.ServerMessage.Encryptor.encoding_aes_key(),
          token: token,
          requester: module
        ]
  @type client :: module()
  @type requester :: module()
  @type response :: Tesla.Env.result()

  defmacro __using__(options \\ []) do
    quote do
      use WeChat.ClientBuilder, unquote(options)
    end
  end

  @doc """
  根据 `appid` 获取 `client`
  """
  @spec get_client_by_appid(appid) :: nil | client
  defdelegate get_client_by_appid(appid), to: WeChat.Storage.Cache, as: :search_client

  @doc "动态构建 client"
  @spec build_client(client, options) :: {:ok, client}
  def build_client(client, options) do
    with {:module, module, _binary, _term} <-
           Module.create(
             client,
             quote do
               @moduledoc false
               use WeChat.ClientBuilder, unquote(options)
             end,
             Macro.Env.location(__ENV__)
           ) do
      {:ok, module}
    end
  end
end
