defmodule WeChat.Pay.AuthorizationMiddleware do
  import WeChat.Utils, only: [pay_doc_link_prefix: 0]

  @moduledoc """
  微信支付 V3 Authorization 签名生成

  Tesla Middleware

  - [如何生成请求签名](#{pay_doc_link_prefix()}/merchant/development/interface-rules/signature-generation.html){:target="_blank"}
  - [签名相关问题](#{pay_doc_link_prefix()}/merchant/development/interface-rules/signature-faqs.html){:target="_blank"}
  """
  @behaviour Tesla.Middleware
  alias WeChat.Pay.Crypto

  @impl Tesla.Middleware
  def call(env, next, client) do
    token = gen_token(client.mch_id(), client.client_serial_no(), client.private_key(), env)

    env
    |> Tesla.put_headers([{"authorization", "WECHATPAY2-SHA256-RSA2048 #{token}"}])
    |> Tesla.run(next)
  end

  def gen_token(mch_id, serial_no, private_key, env) do
    timestamp = WeChat.Utils.now_unix()
    nonce_str = :crypto.strong_rand_bytes(16) |> Base.encode16()
    signature = Crypto.sign(env, timestamp, nonce_str, private_key)

    ~s(mchid="#{mch_id}",nonce_str="#{nonce_str}",timestamp="#{timestamp}",serial_no="#{serial_no}",signature="#{signature}")
  end
end
