defmodule WeChat.Requester.Pay do
  @moduledoc """
  默认的请求客户端(微信支付)
  """

  alias WeChat.Pay
  alias Tesla.Middleware

  @adapter_options [pool_timeout: 5_000, receive_timeout: 5_000]

  def new(client) do
    %{name: name} = WeChat.Pay.get_requester_opts(client)

    Tesla.client(
      [
        {Middleware.BaseUrl, "https://api.mch.weixin.qq.com"},
        {Middleware.Headers, [{"accept", "application/json"}, {"user-agent", "Tesla"}]},
        Middleware.EncodeJson,
        {Pay.AuthorizationMiddleware,
         [
           mch_id: client.mch_id(),
           serial_no: client.client_serial_no(),
           private_key: client.private_key()
         ]},
        {Pay.VerifySignatureMiddleware, client},
        Middleware.DecodeJson,
        Middleware.Logger
      ],
      {Tesla.Adapter.Finch, [{:name, name} | @adapter_options]}
    )
  end

  @doc false
  def first_time_download_certificates_client(client) do
    # 第一次下载平台证书 跳过验签: https://github.com/wechatpay-apiv3/CertificateDownloader#如何第一次下载证书
    Tesla.client(
      [
        {Middleware.BaseUrl, "https://api.mch.weixin.qq.com"},
        {Middleware.Headers, [{"accept", "application/json"}, {"user-agent", "Tesla"}]},
        Middleware.EncodeJson,
        {Pay.AuthorizationMiddleware,
         [
           mch_id: client.mch_id(),
           serial_no: client.client_serial_no(),
           private_key: client.private_key()
         ]},
        Middleware.DecodeJson,
        Middleware.Logger
      ],
      {Tesla.Adapter.Finch, [{:name, WeChat.Finch} | @adapter_options]}
    )
  end
end
