defmodule WeChat.Pay do
  @moduledoc """
  微信支付

  ## 添加依赖

      def deps do
        [
          {:wechat, "~> x.x", hex: :wechat_sdk},
          {:saxy, "~> 1.2"},
          {:x509, "~> x.x"}
        ]
      end

  ## 定义支付 Client 模块

      defmodule YourApp.WeChatAppCodeName do
        @moduledoc "CodeName"
        use WeChat.Pay,
          mch_id: "1900000109",
          api_secret_v2_key: "api_secret_v2_key",
          api_secret_key: "api_secret_v3_key",
          client_serial_no: "client_serial_no",
          client_key: {:file, "apiclient_key.pem"}
      end

  定义参数说明请看 `t:options/0`

  ## V2 SSL 配置

  部分 v2 的接口请求时需要用到证书，如：撤销订单，因此如果有使用到这部分接口，必须添加下面的配置

      config :wechat, YourApp.WeChatAppCodeName,
        v2_ssl: [
          certfile: "apiclient_cert.pem", # or {:app_dir, App, "priv/cert/apiclient_cert.pem"}
          keyfile: "apiclient_key.pem" # or {:app_dir, App, "priv/cert/apiclient_key.pem"}
        ]

  ## 启动支付 Client 进程

      defmodule YourApp.Application do
        def start(_type, _args) do
          children = [
            # ...
            YourApp.WeChatAppCodeName,
            # or
            {YourApp.WeChatAppCodeName, start_options}
          ]

          Supervisor.start_link(children, strategy: :one_for_one, name: YourApp.Supervisor)
        end
      end

  启动参数说明请看 `t:start_options/0`

  ## 处理回调消息

  详情请看 `WeChat.Pay.EventHandler`
  """
  require Logger
  import WeChat.Utils, only: [pay_doc_link_prefix: 0]
  alias WeChat.Utils
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
  商户 API 私钥 -
  [官方文档](#{pay_doc_link_prefix()}/merchant/development/interface-rules/privatekey-and-certificate.html){:target="_blank"}
  """
  @type client_key :: pem_file
  @typedoc """
  API 密钥 -
  [官方文档](#{pay_doc_link_prefix()}/merchant/development/interface-rules/apiv3key.html){:target="_blank"}
  """
  @type api_secret_key :: binary | WeChat.env_option()
  @type client :: module
  @type pem_file ::
          {:binary, binary} | {:file, Path.t()} | {:app_dir, Application.app(), Path.t()}

  @typedoc """
  构建参数

  ## 参数说明

  - `mch_id`: 商户ID `t:mch_id/0` - 必填
  - `api_secret_v2_key`: API v2密钥 `t:api_secret_key/0` - 必填
  - `api_secret_key`: API v3密钥 `t:api_secret_key/0` - 必填
  - `client_serial_no`: 客户端证书序列哈 `t:client_serial_no/0` - 必填
  - `client_key`: 客户端私钥 `t:client_key/0` - 必填
  - `storage`: 存储器 `t:WeChat.Storage.Adapter.t/0`
  - `requester`: 请求客户端 - `t:module/0`

  ## 默认参数:

  - `storage`: `WeChat.Storage.PayFile`
  - `requester`: `WeChat.Requester.Pay`
  """
  @type options :: [
          mch_id: mch_id,
          api_secret_v2_key: api_secret_key,
          api_secret_key: api_secret_key,
          client_serial_no: client_serial_no,
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
  # v3
  def finch_name(client), do: :"#{client}.Finch"
  @doc false
  def v2_ssl_finch_name(client), do: :"#{client}.v2ssl.Finch"

  @spec get_requester_specs(client) :: [map]
  def get_requester_specs(client) do
    client_config =
      case Application.fetch_env(:wechat, client) do
        {:ok, config} -> config
        _ -> %{}
      end

    finch_pool =
      case client_config[:finch_pool] do
        finch_pool when is_list(finch_pool) or is_map(finch_pool) -> finch_pool
        _ -> Application.get_env(:wechat, :finch_pool, size: 32, count: 8)
      end

    # v3
    v3_spec =
      Finch.child_spec(name: finch_name(client), pools: %{:default => finch_pool})
      |> Map.put(:id, Finch)

    v2_spec =
      case client_config[:v2_ssl] do
        ssl when is_list(ssl) ->
          certfile =
            Keyword.get_lazy(ssl, :certfile, fn ->
              raise ArgumentError, "missing :certfile for v2_ssl in config :wechat, #{client}"
            end)
            |> Utils.expand_file()
            |> case do
              {:ok, file} ->
                file

              {:error, error} ->
                raise ArgumentError, "certfile #{error} for v2_ssl in config :wechat, #{client}"
            end

          keyfile =
            Keyword.get_lazy(ssl, :keyfile, fn ->
              raise ArgumentError, "missing :keyfile for v2_ssl in config :wechat, #{client}"
            end)
            |> Utils.expand_file()
            |> case do
              {:ok, file} ->
                file

              {:error, error} ->
                raise ArgumentError, "keyfile #{error} for v2_ssl in config :wechat, #{client}"
            end

          v2_finch_pool =
            finch_pool ++
              [
                conn_opts: [
                  transport_opts: [certfile: certfile, keyfile: keyfile, versions: [:"tlsv1.2"]]
                ]
              ]

          Finch.child_spec(name: v2_ssl_finch_name(client), pools: %{:default => v2_finch_pool})
          |> Map.put(:id, V2.Finch)

        _ ->
          nil
      end

    if v2_spec do
      [v3_spec, v2_spec]
    else
      [v3_spec]
    end
  end

  @doc "初始化平台证书"
  @spec init_certs(client) :: {:ok, cacerts :: list(map)}
  def init_certs(client) do
    with {:ok, certs} when is_list(certs) <- Certificates.certificates(client, true) do
      Certificates.put_certs(certs, client)
      storage = client.storage()
      result = storage.store(client.mch_id(), :certs, certs)
      Logger.info("store cacerts for mch_id:#{client.mch_id()} result: #{inspect(result)}.")
      {:ok, certs}
    else
      error ->
        Logger.warning("Init certificates error: #{inspect(error)}.")
        error
    end
  end
end
