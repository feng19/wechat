defmodule WeChat.Requester.OfficialAccount do
  @moduledoc """
  默认的请求客户端(公众号&小程序&第三方)

  ```
  use Tesla
  adapter: Finch
  BaseUrl: "https://api.weixin.qq.com"
  ```
  """
  use Tesla, only: [:get, :post]

  @opts Application.compile_env(:wechat, __MODULE__, [])

  if Mix.env() == :test do
    adapter Tesla.Mock
  else
    @adapter_options @opts
                     |> Keyword.get(:adapter_options, pool_timeout: 5_000, receive_timeout: 5_000)
                     |> Keyword.put(:name, WeChat.Finch)
    adapter Tesla.Adapter.Finch, @adapter_options
    plug Tesla.Middleware.BaseUrl, "https://api.weixin.qq.com"
  end

  @retry_options Keyword.get(@opts, :retry_options,
                   delay: 500,
                   max_retries: 3,
                   max_delay: 2_000,
                   should_retry: &WeChat.Utils.request_should_retry/1
                 )
  plug Tesla.Middleware.Retry, @retry_options
  plug Tesla.Middleware.JSON, decode_content_types: ["text/plain"]
  plug Tesla.Middleware.Logger
end
