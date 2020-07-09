defmodule WeChat.Card do
  @moduledoc """
  微信卡券

  [API Docs Link](https://developers.weixin.qq.com/doc/offiaccount/Cards_and_Offer/WeChat_Coupon_Interface.html){:target="_blank"}
  """
  import Jason.Helpers
  alias WeChat.Requester

  @doc_link "#{WeChat.doc_link_prefix()}/offiaccount/Cards_and_Offer"

  @type card_id :: String.t()
  @typedoc """
  卡券类型
    * `"GROUPON"`         - 团购券
    * `"DISCOUNT"`        - 折扣券
    * `"GIFT"`            - 礼品券
    * `"CASH"`            - 代金券
    * `"GENERAL_COUPON"`  - 通用券
    * `"MEMBER_CARD"`     - 会员卡
    * `"SCENIC_TICKET"`   - 景点门票
    * `"MOVIE_TICKET"`    - 电影票
    * `"BOARDING_PASS"`   - 飞机票
    * `"MEETING_TICKET"`  - 会议门票
    * `"BUS_TICKET"`      - 汽车票
  """
  @type card_type :: String.t()
  @type card_code :: String.t()
  @typedoc """
  支持开发者拉出指定状态的卡券列表
    * `"CARD_STATUS_NOT_VERIFY"`  - 待审核
    * `"CARD_STATUS_VERIFY_FAIL"` - 审核失败
    * `"CARD_STATUS_VERIFY_OK"`   - 通过审核
    * `"CARD_STATUS_DELETE"`      - 卡券被商户删除
    * `"CARD_STATUS_DISPATCH"`    - 在公众平台投放过的卡券
  """
  @type card_status :: String.t()
  @typedoc """
  | type                      | description      | 适用核销方式                                                 |
  | ------------------------- | ---------------- | ------------------------------------------------------------ |
  | `"CODE_TYPE_QRCODE"`      | 二维码显示code   | 适用于扫码/输码核销                                          |
  | `"CODE_TYPE_BARCODE"`     | 一维码显示code   | 适用于扫码/输码核销                                          |
  | `"CODE_TYPE_ONLY_QRCODE"` | 二维码不显示code | 仅适用于扫码核销                                             |
  | `"CODE_TYPE_TEXT"`        | 仅code类型       | 仅适用于输码核销                                             |
  | `"CODE_TYPE_NONE"`        | 无code类型       | 仅适用于线上核销，开发者须自定义跳转链接跳转至H5页面，允许用户核销掉卡券，自定义cell的名称可以命名为“立即使用” |
  """
  @type code_type :: String.t()
  @type date :: Date.t() | String.t()
  @typedoc """
  卡券来源
    * `0` - 为公众平台创建的卡券数据
    * `1` - 是API创建的卡券数据
  """
  @type cond_source :: 0 | 1

  @doc """
  创建卡券 - [Official API Docs Link](#{@doc_link}/Create_a_Coupon_Voucher_or_Card.html#8){:target="_blank"}
  """
  @spec create(WeChat.client(), body :: map) :: WeChat.response()
  def create(client, body) do
    Requester.post("/card/create", body,
      query: [access_token: WeChat.get_cache(client.appid(), :access_token)]
    )
  end

  @doc """
  设置快速买单 - [Official API Docs Link](#{@doc_link}/Create_a_Coupon_Voucher_or_Card.html#11){:target="_blank"}

  ## 功能介绍

  微信卡券买单功能是微信卡券的一项新的能力，可以方便消费者买单时，直接录入消费金额，自动使用领到的优惠（券或卡）抵扣，并拉起微信支付快速完成付款。

  微信买单（以下统称微信买单）的好处：

  * 无需商户具备微信支付开发能力，即可完成订单生成，与微信支付打通。
  * 可以通过手机公众号、电脑商户后台，轻松操作收款并查看核销记录，交易对账，并支持离线下载。
  * 支持会员营销，二次营销，如会员卡交易送积分，抵扣积分，买单后赠券等。
  """
  @spec set_pay_cell(WeChat.client(), card_id, is_open :: boolean) :: WeChat.response()
  def set_pay_cell(client, card_id, is_open) do
    Requester.post(
      "/card/paycell/set",
      json_map(card_id: card_id, is_open: is_open),
      query: [access_token: WeChat.get_cache(client.appid(), :access_token)]
    )
  end

  @doc """
  设置自助核销 - [Official API Docs Link](#{@doc_link}/Create_a_Coupon_Voucher_or_Card.html#14){:target="_blank"}

  ## 功能介绍

  自助核销与扫码/输码核销互为补充，卡券商户助手通过扫码/输码完成核销的同时，也确保了用券的真实性，适合有强对账需求的商户使用；而自助核销由用户发起，全程由用户操作，适合对账需求不强的商户使用。

  目前，自助核销可能适合以下场景使用:
    * 不允许店员上班期间带手机；
    * 高峰期店内人流量大，扫码/输码核销速度不能满足短时需求；
    * 会议入场，短时有大量核销任务；
  """
  @spec set_self_consume_cell(WeChat.client(), card_id, is_open :: boolean) :: WeChat.response()
  def set_self_consume_cell(client, card_id, is_open) do
    Requester.post(
      "/card/selfconsumecell/set",
      json_map(card_id: card_id, is_open: is_open),
      query: [access_token: WeChat.get_cache(client.appid(), :access_token)]
    )
  end

  @doc """
  查询Code - [Official API Docs Link](#{@doc_link}/Redeeming_a_coupon_voucher_or_card.html#1){:target="_blank"}

  我们强烈建议开发者在调用核销code接口之前调用查询code接口，并在核销之前对非法状态的code(如转赠中、已删除、已核销等)做出处理。
  """
  @spec check_card_code(WeChat.client(), card_id, card_code, check_consume :: boolean) ::
          WeChat.response()
  def check_card_code(client, card_id, card_code, check_consume \\ true) do
    Requester.post(
      "/card/code/get",
      json_map(card_id: card_id, code: card_code, check_consume: check_consume),
      query: [access_token: WeChat.get_cache(client.appid(), :access_token)]
    )
  end

  @doc """
  核销Code接口 - [Official API Docs Link](#{@doc_link}/Redeeming_a_coupon_voucher_or_card.html#2){:target="_blank"}

  消耗code接口是核销卡券的唯一接口,开发者可以调用当前接口将用户的优惠券进行核销，该过程不可逆。
  """
  @spec consume_code(WeChat.client(), card_code) :: WeChat.response()
  def consume_code(client, card_code) do
    Requester.post(
      "/card/code/consume",
      json_map(code: card_code),
      query: [access_token: WeChat.get_cache(client.appid(), :access_token)]
    )
  end

  @doc """
  核销Code接口 - [Official API Docs Link](#{@doc_link}/Redeeming_a_coupon_voucher_or_card.html#2){:target="_blank"}

  消耗code接口是核销卡券的唯一接口,开发者可以调用当前接口将用户的优惠券进行核销，该过程不可逆。

  卡券ID(card_id): 创建卡券时use_custom_code填写true时必填。非自定义Code不必填写
  """
  @spec consume_code(WeChat.client(), card_id, card_code) :: WeChat.response()
  def consume_code(client, card_id, card_code) do
    Requester.post(
      "/card/code/consume",
      json_map(card_id: card_id, code: card_code),
      query: [access_token: WeChat.get_cache(client.appid(), :access_token)]
    )
  end

  @doc """
  Code解码接口 - [Official API Docs Link](#{@doc_link}/Redeeming_a_coupon_voucher_or_card.html#3){:target="_blank"}

  消耗code接口是核销卡券的唯一接口,开发者可以调用当前接口将用户的优惠券进行核销，该过程不可逆。
  """
  @spec decrypt_code(WeChat.client(), encrypt_code :: String.t()) :: WeChat.response()
  def decrypt_code(client, encrypt_code) do
    Requester.post(
      "/card/code/decrypt",
      json_map(encrypt_code: encrypt_code),
      query: [access_token: WeChat.get_cache(client.appid(), :access_token)]
    )
  end
end
