defmodule WeChat.Pay.CombineTransactions do
  @moduledoc "微信支付-合单支付"
  import Jason.Helpers
  import WeChat.Utils, only: [pay_doc_link_prefix: 0]
  alias WeChat.Pay.Transactions

  @typedoc """
  合单商户订单号

  合单支付总订单号，最短2个字符，最长32个字符，只能是数字、大小写字母，以及_-|* ，且在同一个商户号下唯一
  """
  @type combine_out_trade_no :: String.t()
  @type sub_orders :: sub_order
  @type sub_order :: map
  @typep body :: map

  @doc "same as `jsapi/2`"
  @spec jsapi(
          WeChat.client(),
          WeChat.appid(),
          combine_out_trade_no,
          sub_orders,
          Transactions.notify_url(),
          payer :: WeChat.openid()
        ) :: WeChat.response()
  def jsapi(client, appid, combine_out_trade_no, sub_orders, notify_url, payer) do
    jsapi(
      client,
      json_map(
        combine_appid: appid,
        combine_mchid: client.mch_id(),
        combine_out_trade_no: combine_out_trade_no,
        sub_orders: sub_orders,
        notify_url: notify_url,
        combine_payer_info: %{openid: payer}
      )
    )
  end

  @doc """
  JSAPI下单 -
  [官方文档](#{pay_doc_link_prefix()}/merchant/apis/combine-payment/orders/jsapi-prepay.html){:target="_blank"}

  使用合单支付接口，用户只输入一次密码，即可完成多个订单的支付。目前最多一次可支持50笔订单进行合单支付。
  """
  @spec jsapi(WeChat.client(), body) :: WeChat.response()
  def jsapi(client, body) do
    client.post("/v3/combine-transactions/jsapi", body)
  end
end
