defmodule WeChat.Pay.Refund do
  @moduledoc "微信支付-退款"
  import Jason.Helpers
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
  @typedoc "微信支付退款号"
  @type refund_id :: String.t()
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
  [官方文档](https://pay.weixin.qq.com/docs/merchant/apis/refund/refunds/create.html){:target="_blank"}

  当交易发生之后一段时间内，由于买家或者卖家的原因需要退款时，卖家可以通过退款接口将支付款退还给买家，
  微信支付将在收到退款请求并且验证成功之后，按照退款规则将支付款按原路退到买家帐号上。
  """
  @spec refund(WeChat.client(), body) :: WeChat.response()
  def refund(client, body) do
    client.post("/v3/refund/domestic/refunds", body)
  end

  @doc """
  查询单笔退款(通过商户退款单号) -
  [官方文档](https://pay.weixin.qq.com/docs/merchant/apis/refund/refunds/query-by-out-refund-no.html){:target="_blank"}

  提交退款申请后，通过调用该接口查询退款状态。
  退款有一定延时，建议查询退款状态在提交退款申请后1分钟发起，一般来说零钱支付的退款5分钟内到账，银行卡支付的退款1-3个工作日到账。
  """
  @spec query_refund(WeChat.client(), out_refund_no) :: WeChat.response()
  def query_refund(client, out_refund_no) do
    client.get("/v3/refund/domestic/refunds/#{out_refund_no}")
  end

  @doc """
  发起异常退款 -
  [官方文档](https://pay.weixin.qq.com/docs/merchant/apis/refund/refunds/create-abnormal-refund.html){:target="_blank"}

  提交退款申请后，查询退款确认状态为退款异常，可调用此接口发起异常退款处理。支持退款至用户、退款至交易商户银行账户两种处理方式。

  注意：

  - 退款至用户时，仅支持以下银行的借记卡：招行、交通银行、农行、建行、工商、中行、平安、浦发、中信、光大、民生、兴业、广发、邮储、宁波银行。
  - 请求频率限制：150qps，即每秒钟正常的申请退款请求次数不超过150次
  """
  @spec abnormal_refund(WeChat.client(), refund_id, body) :: WeChat.response()
  def abnormal_refund(client, refund_id, body) do
    client.post("/v3/refund/domestic/refunds/#{refund_id}/apply-abnormal-refund", body)
  end
end
