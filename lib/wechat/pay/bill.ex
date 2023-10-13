defmodule WeChat.Pay.Bill do
  @moduledoc "微信支付-交易账单"
  import Jason.Helpers
  import WeChat.Utils, only: [pay_doc_link_prefix: 0]

  @doc """
  申请交易账单 -
  [官方文档](#{pay_doc_link_prefix()}/merchant/apis/bill-download/trade-bill/get-trade-bill.html){:target="_blank"}
  """
  def tradebill(client, bill_date, bill_type \\ "ALL", zip? \\ false)

  def tradebill(client, bill_date, bill_type, false) do
    client.post(
      "/v3/bill/tradebill",
      json_map(bill_date: bill_date, bill_type: bill_type, tar_type: "GZIP")
    )
  end

  def tradebill(client, bill_date, bill_type, true) do
    client.post("/v3/bill/tradebill", json_map(bill_date: bill_date, bill_type: bill_type))
  end
end
