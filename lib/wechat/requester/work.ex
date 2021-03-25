defmodule WeChat.Requester.Work do
  @moduledoc """
  默认的请求客户端(企业微信)

  ```
  use Tesla
  adapter: Finch
  BaseUrl: "https://qyapi.weixin.qq.com"
  ```
  """
  use Tesla, only: [:get, :post]

  adapter(Tesla.Adapter.Finch, name: WeChat.Finch, pool_timeout: 5_000, receive_timeout: 5_000)

  plug(Tesla.Middleware.BaseUrl, "https://qyapi.weixin.qq.com")
  plug(Tesla.Middleware.Logger)
  plug(Tesla.Middleware.JSON, decode_content_types: ["text/plain"])
end
