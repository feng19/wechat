defmodule WeChat.Pay.Transactions do
  @moduledoc """
  微信支付 - 交易
  """
  import Jason.Helpers

  def jsapi(client, appid, out_trade_no, notify_url, amount, payer) do
    client.post("/v3/pay/transactions/jsapi", %{
      "appid" => appid,
      "mchid" => client.mch_id(),
      "out_trade_no" => out_trade_no,
      "notify_url" => notify_url,
      "amount" => %{
        "total" => amount,
        "currency" => "CNY"
      },
      "payer" => %{"openid" => payer}
    })
  end

  def query_by_out_trade_no(client, out_trade_no) do
    client.get(
      "/v3/pay/transactions/out-trade-no/#{out_trade_no}",
      query: [mchid: client.mch_id()]
    )
  end

  def query_by_id(client, transaction_id) do
    client.get("/v3/pay/transactions/id/#{transaction_id}", query: [mchid: client.mch_id()])
  end

  def close(client, out_trade_no) do
    client.post(
      "/v3/pay/transactions/out-trade-no/#{out_trade_no}/close",
      json_map(mchid: client.mch_id())
    )
  end
end
