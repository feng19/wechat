defmodule WeChat.Pay.Certificates do
  @moduledoc false
  alias WeChat.Pay.Utils

  # [获取平台证书列表](https://pay.weixin.qq.com/wiki/doc/apiv3/wechatpay/wechatpay5_1.shtml)
  def certificates(client) do
    with {:ok, %{body: %{data: certificates}}} when is_list(certificates) <-
           client.get("/v3/certificates") do
      IO.inspect(certificates, label: "certificates")
      api_secret_key = client.api_secret_key()
      {:ok, Enum.map(certificates, &Utils.decrypt_certificate(&1, api_secret_key))}
    end
  end
end
