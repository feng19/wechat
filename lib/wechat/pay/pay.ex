defmodule WeChat.Pay do
  @moduledoc false

  @typedoc "商户号"
  @type mch_id :: binary
  @typedoc "平台证书的序列号"
  @type serial_no :: binary
  @typedoc "平台证书列表"
  @type cacerts :: [binary]
  @typedoc "商户API证书"
  @type client_cert :: binary
  @typedoc "商户API私钥"
  @type client_key :: binary
  @type client :: module()
  @type options :: Enumerable.t()

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

  def put_requester_opts(client, id, serial_no) do
    name = finch_name(client, id)

    :persistent_term.put({:wechat, {client, :requester_opts}}, %{
      id: id,
      name: name,
      serial_no: serial_no
    })
  end

  def get_requester_opts(client) do
    :persistent_term.get({:wechat, {client, :requester_opts}})
  end

  # 保存平台证书 serial_no => cert 的对应关系
  def put_cert(client, serial_no, cert) do
    :persistent_term.put({:wechat, {client, serial_no}}, cert)
  end

  # 获取平台证书 serial_no 对应的 cert
  def get_cert(client, serial_no) do
    :persistent_term.get({:wechat, {client, serial_no}})
  end

  def remove_cert(client, serial_no) do
    :persistent_term.erase({:wechat, {client, serial_no}})
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

  # [平台证书更新指引](https://pay.weixin.qq.com/wiki/doc/apiv3/wechatpay/wechatpay5_0.shtml)
  # * 证书切换
  #  * 通过 Supervisor 开启新的 Finch 进程
  #  * 然后 将新的 Finch 进程名写入到 :persistent_term 保存
  #  * 请求的时候，从 :persistent_term 获取 Finch 进程名，然后再请求
  def start_next_requester(client, opts) do
    %{id: now_id} = get_requester_opts(client)
    id = List.delete([:A, :B], now_id) |> hd()
    finch_spec = get_requester_spec(id, client, opts.cacerts)
    sup = :"#{client}.Supervisor"

    with :ok <- Supervisor.terminate_child(sup, id),
         :ok <- Supervisor.delete_child(sup, id),
         {:ok, _} = return <- Supervisor.start_child(sup, finch_spec) do
      put_requester_opts(client, id, opts.serial_no)
      return
    end
  end

  def init_cacerts2storage(client, cacerts) do
    storage = client.storage()
    storage.store(client.mch_id(), :cacerts, cacerts)
  end
end
