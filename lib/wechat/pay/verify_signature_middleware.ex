defmodule WeChat.Pay.VerifySignatureMiddleware do
  import WeChat.Utils, only: [pay_doc_link_prefix: 0]

  @moduledoc """
  微信支付 V3 验证签名

  Tesla Middleware

  - [如何验证签名](#{pay_doc_link_prefix()}/merchant/development/interface-rules/signature-verification.html){:target="_blank"}
  - [签名相关问题](#{pay_doc_link_prefix()}/merchant/development/interface-rules/signature-faqs.html){:target="_blank"}
  """
  @behaviour Tesla.Middleware
  alias WeChat.Pay.{Crypto, Certificates}

  @impl Tesla.Middleware
  def call(env, next, client) do
    with {:ok, env} <- Tesla.run(env, next) do
      with body when is_binary(body) <- env.body,
           nonce when is_binary(nonce) <- Tesla.get_header(env, "wechatpay-nonce"),
           signature when is_binary(signature) <- Tesla.get_header(env, "wechatpay-signature"),
           timestamp when is_binary(timestamp) <- Tesla.get_header(env, "wechatpay-timestamp"),
           serial_no when is_binary(serial_no) <- Tesla.get_header(env, "wechatpay-serial"),
           public_key when not is_nil(public_key) <- Certificates.get_cert(client, serial_no),
           true <- Crypto.verify(signature, timestamp, nonce, body, public_key) do
        {:ok, env}
      else
        _ -> {:error, :invaild_response}
      end
    end
  end
end
