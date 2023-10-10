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
          client_cert: "client_cert",
          client_key: "client_key"
      end

  定义参数说明请看 `t:options/0`

  ## 启动支付 Client 进程

      defmodule YourApp.Application do
        def start(_type, _args) do
          start_options = [serial_no: "serial_no", cacerts: ["cacert1", "cacert2"]]

          children = [
            # ...
            {YourApp.WeChatAppCodeName, start_options},
            # ...
          ]

          Supervisor.start_link(children, strategy: :one_for_one, name: YourApp.Supervisor)
        end
      end

  启动参数说明请看 `t:start_options/0`
  """
  import WeChat.Utils, only: [pay_doc_link_prefix: 0]

  @typedoc "商户号"
  @type mch_id :: binary
  @typedoc """
  平台证书的序列号 -
  [官方文档](#{pay_doc_link_prefix()}/merchant/development/interface-rules/certificate-faqs.html){:target="_blank"}
  """
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
  @type client_cert :: binary
  @typedoc """
  商户 API 私钥 -
  [官方文档](#{pay_doc_link_prefix()}/merchant/development/interface-rules/privatekey-and-certificate.html){:target="_blank"}
  """
  @type client_key :: binary
  @typedoc """
  API v3密钥 -
  [官方文档](#{pay_doc_link_prefix()}/merchant/development/interface-rules/apiv3key.html){:target="_blank"}
  """
  @type api_secret_key :: binary
  @type client :: module

  @typedoc """
  构建参数

  ## 参数说明

  - `mch_id`: `t:mch_id/0` - 必填
  - `api_secret_key`: `t:binary/0` - 必填
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
          client_cert: client_cert,
          client_key: client_key,
          requester: module,
          storage: module
        ]

  @typedoc """
  启动参数

  ## 参数说明

  - `cacerts`: `t:cacerts/0` - 必填
  - `serial_no`: `t:serial_no/0` - 必填
  - `refresher`: 刷新器 - `t:module/0`

  ## 默认参数:

  - `refresher`: `WeChat.Refresher.Pay`
  """
  @type start_options :: [
          cacerts: cacerts,
          serial_no: serial_no,
          refresher: module
        ]
  @type requester_id :: :A | :B
  @type requester_opts :: %{
          id: requester_id,
          name: atom,
          serial_no: serial_no
        }

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

  @doc "保存请求器配置"
  @spec put_requester_opts(client, requester_id, serial_no) :: :ok
  def put_requester_opts(client, id, serial_no) do
    name = finch_name(client, id)

    :persistent_term.put({:wechat, {client, :requester_opts}}, %{
      id: id,
      name: name,
      serial_no: serial_no
    })
  end

  @doc "获取请求器配置"
  @spec get_requester_opts(client) :: requester_opts
  def get_requester_opts(client) do
    :persistent_term.get({:wechat, {client, :requester_opts}})
  end

  defp finch_name(client, id), do: :"#{client}.Finch.#{id}"

  def get_requester_spec(id, client, cacerts) when is_atom(id) do
    name = finch_name(client, id)

    finch_pool =
      Application.get_env(:wechat, :finch_pool, size: 32, count: 8) ++
        [
          conn_opts: [
            transport_opts: [
              cacerts: cacerts,
              cert: client.client_cert(),
              key: client.client_key()
            ]
          ]
        ]

    options = [name: name, pools: %{:default => finch_pool}]
    spec = Finch.child_spec(options)
    %{spec | id: id}
  end

  # [平台证书更新指引](#{pay_doc_link_prefix()}/merchant/development/interface-rules/wechatpay-certificates-rotation.html)
  # * 证书切换
  #  * 通过 Supervisor 开启新的 Finch 进程
  #  * 然后 将新的 Finch 进程名写入到 :persistent_term 保存
  #  * 请求的时候，从 :persistent_term 获取 Finch 进程名，然后再请求
  def start_next_requester(client, opts) do
    %{id: now_id} = get_requester_opts(client)
    new_id = List.delete([:A, :B], now_id) |> hd()
    finch_spec = get_requester_spec(new_id, client, opts.cacerts)
    sup = :"#{client}.Supervisor"

    with :ok <- Supervisor.terminate_child(sup, new_id),
         :ok <- Supervisor.delete_child(sup, new_id),
         {:ok, _} = return <- Supervisor.start_child(sup, finch_spec) do
      put_requester_opts(client, new_id, opts.serial_no)
      return
    end
  end

  def init_cacerts() do

  end

  def init_cacerts2storage(client, cacerts) do
    storage = client.storage()
    storage.store(client.mch_id(), :cacerts, cacerts)
  end
end
