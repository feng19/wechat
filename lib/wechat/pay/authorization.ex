defmodule WeChat.Pay.Authorization do
  @moduledoc """
  微信支付 V3 Authorization 签名生成

  [官方文档](https://pay.weixin.qq.com/wiki/doc/apiv3/wechatpay/wechatpay4_0.shtml){:target="_blank"}
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
