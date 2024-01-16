defmodule WeChat.Pay.Sandbox do
  @moduledoc """
  支付沙盒(仅适用于v2)

  [官方文档](https://pay.weixin.qq.com/wiki/doc/api/jsapi.php?chapter=23_1&index=2)
  """

  @spec get_sign_key(Pay.client(), nonce_str :: binary) :: WeChat.response()
  def get_sign_key(client, nonce_str) do
    client.v2_post(
      "xdc/apiv2getsignkey/sign/getsignkey",
      %{
        "mch_id" => client.mch_id(),
        "nonce_str" => nonce_str
      },
      opts: [auth_verify_sign: false]
    )
  end
end
