defmodule WeChat.Requester.Pay do
  @moduledoc """
  默认的请求客户端(微信支付)
  """

  alias WeChat.Pay
  alias Tesla.Middleware

  @adapter_options [pool_timeout: 5_000, receive_timeout: 5_000]

  def new(client, name, serial_no) do
    Tesla.client(
      [
        {Middleware.BaseUrl, "https://api.mch.weixin.qq.com"},
        {Middleware.Headers, [{"accept", "application/json"}, {"user-agent", "Tesla"}]},
        Middleware.EncodeJson,
        {Pay.AuthorizationMiddleware,
         [mch_id: client.mch_id(), serial_no: serial_no, private_key: client.private_key()]},
        {Pay.VerifySignatureMiddleware, [serial_no: serial_no, public_key: client.public_key()]},
        Middleware.DecodeJson,
        Middleware.Logger
      ],
      {Tesla.Adapter.Finch, [{:name, name} | @adapter_options]}
    )
  end
end
