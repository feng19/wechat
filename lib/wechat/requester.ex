defmodule WeChat.Requester do
  use Tesla, only: [:get, :post]

  adapter(Tesla.Adapter.Finch, name: WeChat.Finch, pool_timeout: 5_000, receive_timeout: 5_000)

  plug(Tesla.Middleware.BaseUrl, "https://api.weixin.qq.com")
  plug(Tesla.Middleware.Logger)
  plug(Tesla.Middleware.JSON, decode_content_types: ["text/plain"])
end
