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

  if Mix.env() == :test do
    adapter Tesla.Mock
  else
    adapter Tesla.Adapter.Finch, name: WeChat.Finch, pool_timeout: 5_000, receive_timeout: 5_000
    plug Tesla.Middleware.BaseUrl, "https://qyapi.weixin.qq.com"
    plug Tesla.Middleware.Logger
  end

  plug Tesla.Middleware.Retry,
    delay: 500,
    max_retries: 3,
    max_delay: 2_000,
    should_retry: fn
      {:ok, %{status: status}} when status in [400, 500] -> true
      {:ok, _} -> false
      {:error, _} -> true
    end

  plug Tesla.Middleware.JSON, decode_content_types: ["text/plain"]
end
