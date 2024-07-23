defmodule WeChat.Pay.Bill do
  @moduledoc "微信支付-交易账单"
  alias WeChat.Pay

  @typedoc """
  账单日期

  格式 `yyyy-MM-DD`，仅支持三个月内的账单下载申请。
  """
  @type bill_date :: String.t()
  @typedoc """
  账单类型

  不填则默认是 `"ALL"`, 可选取值：

  - `"ALL"`: 返回当日所有订单信息（不含充值退款订单）
  - `"SUCCESS"`: 返回当日成功支付的订单（不含充值退款订单）
  - `"REFUND"`: 返回当日退款订单（不含充值退款订单）
  - `"RECHARGE_REFUND"`: 返回当日充值退款订单
  - `"ALL_SPECIAL"`: 返回个性化账单当日所有订单信息
  - `"SUC_SPECIAL"`: 返回个性化账单当日成功支付的订单
  - `"REF_SPECIAL"`: 返回个性化账单当日退款订单
  """
  @type bill_type :: String.t()

  @typedoc """
  资金账户类型

  不填默认是`"BASIC"`, 可选取值：

  - `"BASIC"`: 基本账户
  - `"OPERATION"`: 运营账户
  - `"FEES"`: 手续费账户
  - `"ALL"`: 所有账户（该枚举值只限电商平台下载二级商户资金流水账单场景使用）
  """
  @type account_type :: String.t()
  @typedoc """
  是否压缩

  - `false`: 不压缩的方式返回数据流
  - `true`: GZIP 格式压缩，返回格式为 `.gzip` 的压缩包账单
  """
  @type zip? :: boolean

  @doc """
  申请交易账单 -
  [官方文档](https://pay.weixin.qq.com/docs/merchant/apis/bill-download/trade-bill/get-trade-bill.html){:target="_blank"}

  微信支付按天提供交易账单文件，商户可以通过该接口获取账单文件的下载地址。
  文件内包含交易相关的金额、时间、营销等信息，供商户核对订单、退款、银行到账等情况。

  注意：

  - 微信侧未成功下单的交易不会出现在对账单中。支付成功后撤销的交易会出现在对账单中，跟原支付单订单号一致；
  - 对账单中涉及金额的字段单位为“元”；
  - 对账单接口只能下载三个月以内的账单；
  - 小微商户不单独提供对账单下载，如有需要，可联系发起交易的服务商。
  """
  @spec trade_bill(Pay.client(), bill_date, bill_type, zip?) :: WeChat.response()
  def trade_bill(client, bill_date, bill_type \\ "ALL", zip? \\ false)

  def trade_bill(client, bill_date, bill_type, true) do
    client.get("/v3/bill/tradebill",
      query: [bill_date: bill_date, bill_type: bill_type, tar_type: "GZIP"]
    )
  end

  def trade_bill(client, bill_date, bill_type, false) do
    client.get("/v3/bill/tradebill", query: [bill_date: bill_date, bill_type: bill_type])
  end

  @doc """
  申请资金账单 -
  [官方文档](https://pay.weixin.qq.com/docs/merchant/apis/bill-download/fund-bill/get-fund-bill.html){:target="_blank"}

  ## 下载接口说明

  微信支付按天提供微信支付账户的资金流水账单文件，商户可以通过该接口获取账单文件的下载地址。
  文件内包含该账户资金操作相关的业务单号、收支金额、记账时间等信息，供商户进行核对。

  注意：

  - 资金账单中的数据反映的是商户微信账户资金变动情况；
  - 当日账单在次日上午9点开始生成，建议商户在上午10点以后获取；
  - 资金账单中涉及金额的字段单位为“元”。

  ## 文件格式说明

  账单文件包括明细数据和汇总数据两部分，每一部分都包含一行表头和若干行具体数据。
  明细数据每一行对应一笔资金操作，同时每一个数据前加入了字符 \`，以避免数据被 Excel 按科学计数法处理。
  如需汇总金额等数据，可以批量替换掉该字符。
  """
  @spec fund_flow_bill(Pay.client(), bill_date, account_type, zip?) :: WeChat.response()
  def fund_flow_bill(client, bill_date, account_type \\ "BASIC", zip? \\ false)

  def fund_flow_bill(client, bill_date, account_type, true) do
    client.get("/v3/bill/fundflowbill",
      query: [bill_date: bill_date, account_type: account_type, tar_type: "GZIP"]
    )
  end

  def fund_flow_bill(client, bill_date, account_type, false) do
    client.get("/v3/bill/fundflowbill",
      query: [bill_date: bill_date, account_type: account_type]
    )
  end

  @doc """
  下载 交易/资金 账单 -
  [官方文档](https://pay.weixin.qq.com/docs/merchant/apis/bill-download/download-bill.html){:target="_blank"}

  本接口适用于下载交易账单和资金账单。

  注意

  - 该接口响应的信息请求头中不包含微信接口响应的签名值，因此需要跳过验签的流程。
  - 账单文件的下载地址的有效时间为5min。
  - 建议商户比对实际下载账单文件的哈希值和从接口获取到的哈希值是否一致，以确认下载账单数据的完整性。
  - 微信将在次日9点开始生成前一天的对账单，建议商户在10点后获取。
  """
  def download_bill(client, url) do
    WeChat.Requester.Pay.download_url(client, url)
  end
end
