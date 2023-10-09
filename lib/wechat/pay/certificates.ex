defmodule WeChat.Pay.Certificates do
  @moduledoc """
  微信支付 - 平台证书

  [官方文档](https://pay.weixin.qq.com/docs/merchant/development/interface-rules/wechatpay-certificates.html){:target="_blank"}
  """
  alias WeChat.Pay.Utils

  @doc """
  下载平台证书 -
  [官方文档](https://pay.weixin.qq.com/docs/merchant/apis/platform-certificate/api-v3-get-certificates/get.html){:target="_blank"}
  """
  def certificates(client) do
    with {:ok, %{body: %{data: certificates}}} when is_list(certificates) <-
           client.get("/v3/certificates") do
      # IO.inspect(certificates, label: "certificates")
      api_secret_key = client.api_secret_key()
      {:ok, Enum.map(certificates, &Utils.decrypt_certificate(&1, api_secret_key))}
    end
  end
end
