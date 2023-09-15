defmodule WeChat.Requester.Pay do
  @moduledoc """
  默认的请求客户端(微信支付)
  """

  alias Tesla.Middleware.{BaseUrl, Headers, Logger, JSON}

  @middleware [
    {BaseUrl, "https://api.mch.weixin.qq.com"},
    {Headers, [{"accept", "application/json"}, {"user-agent", "Tesla"}]},
    JSON,
    Logger
  ]
  @adapter_options [pool_timeout: 5_000, receive_timeout: 5_000]

  def new(client, name, serial_no) do
    authorization_middleware =
      {WeChat.Pay.Authorization,
       mch_id: client.mch_id(), private_key: client.private_key(), serial_no: serial_no}

    Tesla.client(
      @middleware ++ [authorization_middleware],
      {Tesla.Adapter.Finch, [{:name, name} | @adapter_options]}
    )
  end
end
