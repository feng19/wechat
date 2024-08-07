defmodule WeChat.Pay.Middleware.VerifySignature do
  @moduledoc """
  微信支付 V3 验证签名

  Tesla Middleware

  - [如何验证签名](https://pay.weixin.qq.com/docs/merchant/development/interface-rules/signature-verification.html){:target="_blank"}
  - [签名相关问题](https://pay.weixin.qq.com/docs/merchant/development/interface-rules/signature-faqs.html){:target="_blank"}
  """
  @behaviour Tesla.Middleware
  alias WeChat.Pay.{Crypto, Certificates}

  @impl Tesla.Middleware
  def call(env, next, client) do
    case Tesla.run(env, next) do
      {:ok, %{status: 200, body: body} = env} when is_binary(body) ->
        with nonce when is_binary(nonce) <- Tesla.get_header(env, "wechatpay-nonce"),
             signature when is_binary(signature) <- Tesla.get_header(env, "wechatpay-signature"),
             timestamp when is_binary(timestamp) <- Tesla.get_header(env, "wechatpay-timestamp"),
             serial_no when is_binary(serial_no) <- Tesla.get_header(env, "wechatpay-serial"),
             public_key when not is_nil(public_key) <- Certificates.get_cert(client, serial_no),
             true <- Crypto.verify(signature, timestamp, nonce, body, public_key) do
          Tesla.Middleware.JSON.decode(env, [])
        else
          _error -> {:error, :invaild_response}
        end

      {:ok, %{body: body} = env} when is_binary(body) ->
        Tesla.Middleware.JSON.decode(env, [])

      error ->
        error
    end
  end
end
