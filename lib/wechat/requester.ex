defmodule WeChat.Requester do
  use Tesla, only: [:get, :post]

  adapter(Tesla.Adapter.Hackney)

  plug(Tesla.Middleware.BaseUrl, "https://api.weixin.qq.com")
  plug(Tesla.Middleware.Logger)
  plug(Tesla.Middleware.JSON, decode_content_types: ["text/plain"])
end
