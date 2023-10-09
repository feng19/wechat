defmodule WeChat.Pay.Authorization do
  import WeChat.Utils, only: [pay_doc_link_prefix: 0]
  @moduledoc """
  微信支付 V3 Authorization 签名生成

  Tesla Middleware

  - [如何生成请求签名](#{pay_doc_link_prefix()}/merchant/development/interface-rules/signature-generation.html){:target="_blank"}
  - [签名相关问题](#{pay_doc_link_prefix()}/merchant/development/interface-rules/signature-faqs.html){:target="_blank"}
  """
  @behaviour Tesla.Middleware
  alias WeChat.Pay.Utils

  @impl Tesla.Middleware
  def call(env, next, options) do
    mch_id = Keyword.fetch!(options, :mch_id)
    serial_no = Keyword.fetch!(options, :serial_no)
    private_key = Keyword.fetch!(options, :private_key)
    token = Utils.get_token(mch_id, serial_no, private_key, env)

    env
    |> Tesla.put_headers([
      {"Authorization", "WECHATPAY2-SHA256-RSA2048 #{token}"}
    ])
    |> Tesla.run(next)
  end
end
