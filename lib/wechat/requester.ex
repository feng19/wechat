defmodule WeChat.Requester do
  use Tesla

  adapter(Tesla.Adapter.Hackney)

  plug(Tesla.Middleware.BaseUrl, "https://api.weixin.qq.com")
  plug(Tesla.Middleware.Logger)
  plug(Tesla.Middleware.JSON)
end
