defmodule WeChat.Pay.Transactions do
  @moduledoc """
  微信支付 - 交易
  """
  import Jason.Helpers
  alias WeChat.Pay
  @currency "CNY"

  @typedoc "微信支付订单号"
  @type transaction_id :: String.t()
  @typedoc """
  商户订单号

  商户系统内部订单号，可以是数字、大小写字母_-*的任意组合，且在同一个商户号下唯一
  """
  @type out_trade_no :: String.t()
  @typedoc """
  预支付交易会话标识

  预支付交易会话标识。用于后续接口调用中使用，该值有效期为2小时
  """
  @type prepay_id :: String.t()
  @typedoc "商品描述"
  @type description :: String.t()
  @typedoc "订单金额，单位为分"
  @type amount :: non_neg_integer
  @typedoc """
  通知地址

  异步接收微信支付结果通知的回调地址，通知URL必须为外网可访问的URL，不能携带参数。
  公网域名必须为HTTPS，如果是走专线接入，使用专线NAT IP或者私有回调域名可使用HTTP
  """
  @type notify_url :: String.t()
  @typep body :: map()

  @doc "same as `jsapi/2`"
  @spec jsapi(
          Pay.client(),
          WeChat.appid(),
          description,
          out_trade_no,
          notify_url,
          amount,
          payer :: WeChat.openid()
        ) :: WeChat.response()
  def jsapi(client, appid, description, out_trade_no, notify_url, amount, payer) do
    jsapi(
      client,
      json_map(
        appid: appid,
        mchid: client.mch_id(),
        description: description,
        out_trade_no: out_trade_no,
        notify_url: notify_url,
        amount: %{total: amount, currency: @currency},
        payer: %{openid: payer}
      )
    )
  end

  @doc """
  JSAPI下单 -
  [官方文档](https://pay.weixin.qq.com/docs/merchant/apis/jsapi-payment/direct-jsons/jsapi-prepay.html){:target="_blank"}

  商户系统先调用该接口在微信支付服务后台生成预支付交易单，返回正确的预支付交易会话标识后再按Native、JSAPI、APP等不同场景生成交易串调起支付
  """
  @spec jsapi(Pay.client(), body) :: WeChat.response()
  def jsapi(client, body) do
    client.post("/v3/pay/transactions/jsapi", body)
  end

  @doc """
  JSAPI调起支付 -
  [官方文档](https://pay.weixin.qq.com/docs/merchant/apis/jsapi-payment/jsapi-transfer-payment.html){:target="_blank"}

  通过 JSAPI下单 接口获取到发起支付的必要参数 `t:prepay_id/0`，然后使用微信支付提供的 前端JS方法 调起支付窗口
  """
  @spec request_payment_args(Pay.client(), WeChat.appid(), prepay_id) :: map
  def request_payment_args(client, appid, prepay_id) do
    timestamp = WeChat.Utils.now_unix() |> to_string()
    nonce_str = :crypto.strong_rand_bytes(24) |> Base.encode64()
    package = "prepay_id=#{prepay_id}"
    sign = request_sign(client, appid, timestamp, nonce_str, package)

    %{
      "appId" => appid,
      "timeStamp" => timestamp,
      "nonceStr" => nonce_str,
      "package" => package,
      "signType" => "RSA",
      "paySign" => sign
    }
  end

  defp request_sign(client, appid, timestamp, nonce_str, package) do
    "#{appid}\n#{timestamp}\n#{nonce_str}\n#{package}\n"
    |> :public_key.sign(:sha256, client.private_key())
    |> Base.encode64()
  end

  @doc """
  APP 下单 -
  [官方文档](https://pay.weixin.qq.com/docs/merchant/apis/in-app-payment/direct-jsons/app-prepay.html){:target="_blank"}

  商户系统先调用该接口在微信支付服务后台生成预支付交易单，返回正确的预支付交易会话标识后再按Native、JSAPI、APP等不同场景生成交易串调起支付
  """
  @spec app(Pay.client(), body) :: WeChat.response()
  def app(client, body) do
    client.post("/v3/pay/transactions/app", body)
  end

  @doc """
  APP 调起支付 -
  [官方文档](https://pay.weixin.qq.com/docs/merchant/apis/in-app-payment/app-transfer-payment.html){:target="_blank"}

  通过App下单接口获取到发起支付的必要参数prepay_id，可以按照接口定义中的规则，使用微信支付提供的SDK调起App支付
  """
  @spec app_request_payment_args(Pay.client(), WeChat.appid(), prepay_id) :: map
  def app_request_payment_args(client, appid, prepay_id) do
    timestamp = WeChat.Utils.now_unix() |> to_string()
    nonce_str = :crypto.strong_rand_bytes(24) |> Base.encode64()
    sign = request_sign(client, appid, timestamp, nonce_str, prepay_id)

    %{
      "appid" => appid,
      "partnerid" => client.mch_id(),
      "prepayid" => prepay_id,
      "package" => "Sign=WXPay",
      "noncestr" => nonce_str,
      "timestamp" => timestamp,
      "sign" => sign
    }
  end

  @doc """
  H5 下单 -
  [官方文档](https://pay.weixin.qq.com/docs/merchant/apis/h5-payment/direct-jsons/h5-prepay.html){:target="_blank"}

  商户系统先调用该接口在微信支付服务后台生成预支付交易单，返回正确的预支付交易会话标识后再按Native、JSAPI、APP等不同场景生成交易串调起支付
  """
  @spec h5(Pay.client(), body) :: WeChat.response()
  def h5(client, body) do
    client.post("/v3/pay/transactions/h5", body)
  end

  @doc """
  Native 下单 -
  [官方文档](https://pay.weixin.qq.com/docs/merchant/apis/h5-payment/direct-jsons/h5-prepay.html){:target="_blank"}

  通过本接口来生成支付链接参数code_url，然后将该参数值生成二维码图片展示给用户。
  用户在使用微信客户端扫描二维码后，可以直接跳转到微信支付页面完成支付操作
  """
  @spec native(Pay.client(), body) :: WeChat.response()
  def native(client, body) do
    client.post("/v3/pay/transactions/native", body)
  end

  @spec query_by_out_trade_no(Pay.client(), out_trade_no) :: WeChat.response()
  def query_by_out_trade_no(client, out_trade_no) do
    client.get(
      "/v3/pay/transactions/out-trade-no/#{out_trade_no}",
      query: [mchid: client.mch_id()]
    )
  end

  @spec query_by_id(Pay.client(), transaction_id) :: WeChat.response()
  def query_by_id(client, transaction_id) do
    client.get("/v3/pay/transactions/id/#{transaction_id}", query: [mchid: client.mch_id()])
  end

  @doc """
  关闭订单

  以下情况需要调用关单接口：

  - 商户订单支付失败需要生成新单号重新发起支付，要对原订单号调用关单，避免重复支付
  - 系统下单后，用户支付超时，系统退出不再受理，避免用户继续，请调用关单接口
  """
  @spec close(Pay.client(), out_trade_no) :: WeChat.response()
  def close(client, out_trade_no) do
    client.post(
      "/v3/pay/transactions/out-trade-no/#{out_trade_no}/close",
      json_map(mchid: client.mch_id())
    )
  end

  @doc """
  付款码支付(v2) -
  [官方文档](https://pay.weixin.qq.com/wiki/doc/api/micropay.php?chapter=9_10){:target="_blank"}

  收银员使用扫码设备读取微信用户付款码以后，二维码或条码信息会传送至商户收银台，由商户收银台或者商户后台调用该接口发起支付

  [支付流程](https://pay.weixin.qq.com/wiki/doc/api/micropay.php?chapter=5_4){:target="_blank"}
  """
  @spec pay_by_scan(Pay.client(), body) :: WeChat.response()
  def pay_by_scan(client, body) do
    client.v2_post("/pay/micropay", body)
  end

  @doc """
  撤销订单(v2) -
  [官方文档](https://pay.weixin.qq.com/wiki/doc/api/micropay.php?chapter=9_11){:target="_blank"}

  **需要配置证书**

  支付交易返回失败或支付系统超时，调用该接口撤销交易

    - 如果此订单用户支付失败，微信支付系统会将此订单关闭；
    - 如果用户支付成功，微信支付系统会将此订单资金退还给用户。

  注意：7天以内的交易单可调用撤销，其他正常支付的单如需实现相同功能请调用申请退款API。提交支付交易后调用【查询订单API】，没有明确的支付结果再调用【撤销订单API】
  """
  @spec revoke(Pay.client(), body) :: WeChat.response()
  def revoke(client, body) do
    client.v2_post("/secapi/pay/reverse", body, ssl?: true)
  end
end
