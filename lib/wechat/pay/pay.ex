defmodule WeChat.Pay do
  @moduledoc """
  微信支付

  ** 注意 ** 未经上线测试，请谨慎使用

  ## 定义 Client 模块

      defmodule YourApp.WeChatAppCodeName do
        @moduledoc "CodeName"
        use WeChat.Pay,
          mch_id: "mch_id",
          api_secret_key: "api_secret_key",
          client_serial_no: "client_serial_no",
          client_cert: "client_cert",
          client_key: "client_key"
      end

  定义参数说明请看 `t:options/0`

  ## 初始化平台证书
      
      WeChat.Pay.init_cacerts(YourApp.WeChatAppCodeName)

  ## 启动支付 Client 进程

      defmodule YourApp.Application do
        def start(_type, _args) do
          children = [
            # ...
            YourApp.WeChatAppCodeName,
            # or
            {YourApp.WeChatAppCodeName, start_options},
            # ...
          ]


          Supervisor.start_link(children, strategy: :one_for_one, name: YourApp.Supervisor)
        end
      end

  启动参数说明请看 `t:start_options/0`
  """
  require Logger
  import WeChat.Utils, only: [pay_doc_link_prefix: 0]
  alias WeChat.Pay.Certificates

  @typedoc "商户号"
  @type mch_id :: binary
  @typedoc """
  平台 证书序列号 -
  [官方文档](#{pay_doc_link_prefix()}/merchant/development/interface-rules/certificate-faqs.html){:target="_blank"}
  """
  @type platform_serial_no :: serial_no
  @typedoc """
  商户API 证书序列号 -
  [官方文档](#{pay_doc_link_prefix()}/merchant/development/interface-rules/certificate-faqs.html){:target="_blank"}
  """
  @type client_serial_no :: serial_no
  @typedoc "证书的序列号"
  @type serial_no :: binary
  @typedoc """
  平台证书列表 -
  [官方文档](#{pay_doc_link_prefix()}/merchant/development/interface-rules/wechatpay-certificates.html){:target="_blank"}
  """
  @type cacerts :: list(binary)
  @typedoc """
  商户 API 证书 -
  [官方文档](#{pay_doc_link_prefix()}/merchant/development/interface-rules/privatekey-and-certificate.html){:target="_blank"}
  """
  @type client_cert :: pem_file
  @typedoc """
  商户 API 私钥 -
  [官方文档](#{pay_doc_link_prefix()}/merchant/development/interface-rules/privatekey-and-certificate.html){:target="_blank"}
  """
  @type client_key :: pem_file
  @typedoc """
  API v3密钥 -
  [官方文档](#{pay_doc_link_prefix()}/merchant/development/interface-rules/apiv3key.html){:target="_blank"}
  """
  @type api_secret_key :: binary | WeChat.env_option()
  @type client :: module
  @typep pem_file :: {:file, Path.t()} | {:app_dir, Application.app(), Path.t()}

  @typedoc """
  构建参数

  ## 参数说明

  - `mch_id`: `t:mch_id/0` - 必填
  - `api_secret_key`: `t:binary/0` - 必填
  - `client_serial_no`: `t:client_serial_no/0` - 必填
  - `client_cert`: `t:client_cert/0` - 必填
  - `client_key`: `t:client_key/0` - 必填
  - `storage`: `t:WeChat.Storage.Adapter.t()`
  - `requester`: 请求客户端 - `t:module/0`

  ## 默认参数:

  - `storage`: `WeChat.Storage.PayFile`
  - `requester`: `WeChat.Requester.Pay`
  """
  @type options :: [
          mch_id: mch_id,
          api_secret_key: binary,
          client_serial_no: client_serial_no,
          client_cert: client_cert,
          client_key: client_key,
          requester: module,
          storage: module
        ]

  @typedoc """
  启动参数

  - `refresher`: 刷新器 - `t:module/0`, 可选, 默认值: `WeChat.Refresher.Pay`
  """
  @type start_options :: [refresher: module]
  @type requester_id :: :A | :B
  @type requester_opts :: %{id: requester_id, name: atom}

  @doc false
  defmacro __using__(options \\ []) do
    quote do
      use WeChat.Builder.Pay, unquote(options)
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
               use WeChat.Builder.Pay, unquote(Macro.escape(options))
             end,
             Macro.Env.location(__ENV__)
           ) do
      {:ok, module}
    end
  end

  @doc false
  def finch_name(client), do: :"#{client}.Finch"

  def get_requester_spec(client) do
    name = finch_name(client)
    # todo config finch_pool
    finch_pool = Application.get_env(:wechat, :finch_pool, size: 32, count: 8)
    options = [name: name, pools: %{:default => finch_pool}]
    spec = Finch.child_spec(options)
    %{spec | id: Finch}
  end

  @doc "初始化平台证书"
  @spec init_cacerts(client) :: {:ok, cacerts :: list(map)}
  def init_cacerts(client) do
    with {:ok, cacerts} when is_list(cacerts) <- Certificates.certificates(client, true) do
      Certificates.put_certs(cacerts, client)
      storage = client.storage()
      result = storage.store(client.mch_id(), :cacerts, cacerts)
      Logger.info("store cacerts for mch_id:#{client.mch_id()} result: #{inspect(result)}.")
      {:ok, cacerts}
    else
      error ->
        Logger.warning("Init certificates error: #{inspect(error)}.")
        error
    end
  end
end
