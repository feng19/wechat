defmodule WeChat.Pay.Refund do
  @moduledoc "微信支付-退款"
  import Jason.Helpers
  import WeChat.Utils, only: [pay_doc_link_prefix: 0]
  alias WeChat.Pay.Transactions
  @currency "CNY"

  @typedoc """
  商户退款单号

  商户系统内部的退款单号，商户系统内部唯一，只能是数字、大小写字母_-|*@ ，同一退款单号多次请求只退一笔
  """
  @type out_refund_no :: String.t()
  @typedoc """
  退款原因

  若商户传入，会在下发给用户的退款消息中体现退款原因
  """
  @type reason :: String.t()
  @typep body :: map()

  @doc "same as `refund/2`"
  @spec refund_by_out_trade_no(
          WeChat.client(),
          Transactions.out_trade_no(),
          out_refund_no,
          refund_amount :: Transactions.amount(),
          total_amount :: Transactions.amount(),
          Transactions.notify_url(),
          reason
        ) :: WeChat.response()
  def refund_by_out_trade_no(
        client,
        out_trade_no,
        out_refund_no,
        refund_amount,
        total_amount,
        notify_url,
        reason \\ "系统退回"
      ) do
    refund(
      client,
      json_map(
        out_trade_no: out_trade_no,
        out_refund_no: out_refund_no,
        reason: reason,
        notify_url: notify_url,
        amount: %{
          refund: refund_amount,
          total: total_amount,
          currency: @currency
        }
      )
    )
  end

  @doc "same as `refund/2`"
  @spec refund_by_id(
          WeChat.client(),
          Transactions.transaction_id(),
          out_refund_no,
          refund_amount :: Transactions.amount(),
          total_amount :: Transactions.amount(),
          Transactions.notify_url(),
          reason
        ) :: WeChat.response()
  def refund_by_id(
        client,
        transaction_id,
        out_refund_no,
        refund_amount,
        total_amount,
        notify_url,
        reason \\ "系统退回"
      ) do
    refund(
      client,
      json_map(
        transaction_id: transaction_id,
        out_refund_no: out_refund_no,
        reason: reason,
        notify_url: notify_url,
        amount: %{
          refund: refund_amount,
          total: total_amount,
          currency: @currency
        }
      )
    )
  end

  @doc """
  退款申请 -
  [官方文档](#{pay_doc_link_prefix()}/merchant/apis/refund/refunds/create.html){:target="_blank"}

  当交易发生之后一段时间内，由于买家或者卖家的原因需要退款时，卖家可以通过退款接口将支付款退还给买家，
  微信支付将在收到退款请求并且验证成功之后，按照退款规则将支付款按原路退到买家帐号上。
  """
  @spec refund(WeChat.client(), body) :: WeChat.response()
  def refund(client, body) do
    client.post("/v3/refund/domestic/refunds", body)
  end
end
