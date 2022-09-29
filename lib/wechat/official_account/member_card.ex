defmodule WeChat.MemberCard do
  @moduledoc """
  微信卡券 - 会员卡

  [官方文档](https://developers.weixin.qq.com/doc/offiaccount/Cards_and_Offer/Membership_Cards/introduction.html){:target="_blank"}
  """
  import Jason.Helpers
  import WeChat.Utils, only: [doc_link_prefix: 0]
  alias WeChat.Card

  @create_doc_link "#{doc_link_prefix()}/doc/offiaccount/Cards_and_Offer/Membership_Cards/Create_a_membership_card.html"
  @mange_doc_link "#{doc_link_prefix()}/doc/offiaccount/Cards_and_Offer/Membership_Cards/Manage_Member_Card.html"

  @doc """
  创建会员卡接口 -
  [官方文档](#{@create_doc_link}#3){:target="_blank"}

  支持开发者调用该接口创建会员卡，并获取 `card_id`，用于投放。

  调用该接口前，请开发者详读创建卡券接口部分 [上传图片接口、首页](http://mp.weixin.qq.com/wiki?t=resource/res_main&id=mp1451025056&token=&lang=zh_CN&anchor=2.3) 部分，快速录入会员卡卡面必要信息。
  """
  @spec create(WeChat.client(), body :: map) :: WeChat.response()
  def create(client, body) do
    client.post("/card/create", body, query: [access_token: client.get_access_token()])
  end

  @doc """
  激活会员卡 - 接口激活 -
  [官方文档](#{@create_doc_link}#_6-1-接口激活){:target="_blank"}

  接口激活通常需要开发者开发用户填写资料的网页。通常有两种激活流程：

  - 用户必须在填写资料后才能领卡，领卡后开发者调用激活接口为用户激活会员卡；
  - 是用户可以先领取会员卡，点击激活会员卡跳转至开发者设置的资料填写页面，填写完成后开发者调用激活接口为用户激活会员卡。
  """
  @spec activate(WeChat.client(), body :: map) :: WeChat.response()
  def activate(client, body) do
    client.post("/card/membercard/activate", body,
      query: [access_token: client.get_access_token()]
    )
  end

  @doc """
  激活会员卡 - 一键激活 - 设置开卡字段
  [官方文档](#{@create_doc_link}#_6-2-一键激活){:target="_blank"}
  """
  @spec set_activate_user_form(WeChat.client(), body :: map) :: WeChat.response()
  def set_activate_user_form(client, body) do
    client.post("/card/membercard/activateuserform/set", body,
      query: [access_token: client.get_access_token()]
    )
  end

  @doc """
  激活会员卡 - 一键激活 - 获取用户提交资料
  [官方文档](#{@create_doc_link}#_6-2-一键激活){:target="_blank"}

  用户填写并提交开卡资料后，会跳转到商户的网页，商户可以在网页内获取用户已填写的信息并进行开卡资质判断，信息确认等动作。

  具体方式如下：

  - 用户点击提交后，微信会在商户的 `url` 后面拼接获取用户填写信息的参数：`activate_ticket`、`openid`、`card_id` 和加密 `code-encrypt_code`。
  - 开发者可以根据 `activate_ticket` 获取到用户填写的信息，用于开发者页面的逻辑判断。
  """
  @spec get_activate_temp_info(WeChat.client(), activate_ticket :: String.t()) ::
          WeChat.response()
  def get_activate_temp_info(client, activate_ticket) do
    client.post(
      "/card/membercard/activatetempinfo/get",
      json_map(activate_ticket: activate_ticket),
      query: [access_token: client.get_access_token()]
    )
  end

  @doc """
  拉取会员信息（积分查询）接口 -
  [官方文档](#{@mange_doc_link}#0){:target="_blank"}

  支持开发者根据 `card_id` 和 `code` 查询会员信息,包括激活资料、积分信息以及余额等信息。
  """
  @spec get_info(WeChat.client(), Card.card_id(), Card.card_code()) :: WeChat.response()
  def get_info(client, card_id, code) do
    client.post(
      "/card/membercard/userinfo/get",
      json_map(card_id: card_id, code: code),
      query: [access_token: client.get_access_token()]
    )
  end

  @doc """
  更改会员卡信息 -
  [官方文档](#{@mange_doc_link}#_8-2-更改会员卡信息接口){:target="_blank"}

  支持更改会员卡卡面信息以及卡券属性信息。
  """
  @spec update(WeChat.client(), body :: map) :: WeChat.response()
  def update(client, body) do
    client.post("/card/update", body, query: [access_token: client.get_access_token()])
  end

  @doc """
  设置支付后投放卡券 -
  [官方文档](#{@mange_doc_link}#_8-4-设置支付后投放卡券){:target="_blank"}

  支持商户设置支付后投放卡券规则，可以区分时间段和金额区间发会员卡。
  """
  @spec add_pay_gift_card(WeChat.client(), body :: map) :: WeChat.response()
  def add_pay_gift_card(client, body) do
    client.post("/card/paygiftcard/add", body, query: [access_token: client.get_access_token()])
  end

  @doc """
  删除支付后投放卡券规则 -
  [官方文档](#{@mange_doc_link}#_8-4-设置支付后投放卡券){:target="_blank"}

  删除之前已经设置的支付即会员规则。
  """
  @spec delete_pay_gift_card(WeChat.client(), rule_id :: integer) :: WeChat.response()
  def delete_pay_gift_card(client, rule_id) do
    client.post("/card/paygiftcard/delete", json_map(rule_id: rule_id),
      query: [access_token: client.get_access_token()]
    )
  end

  @doc """
  查询支付后投放卡券规则详情 -
  [官方文档](#{@mange_doc_link}#_8-4-设置支付后投放卡券){:target="_blank"}

  可以查询某个支付即会员规则内容。
  """
  @spec get_pay_gift_card(WeChat.client(), rule_id :: integer) :: WeChat.response()
  def get_pay_gift_card(client, rule_id) do
    client.post("/card/paygiftcard/getbyid", json_map(rule_id: rule_id),
      query: [access_token: client.get_access_token()]
    )
  end

  @doc """
  批量查询支付后投放卡券规则 -
  [官方文档](#{@mange_doc_link}#_8-4-设置支付后投放卡券){:target="_blank"}

  可以批量查询某个商户支付即会员规则内容。
  """
  @spec batch_get_pay_gift_card(WeChat.client(), body :: map) :: WeChat.response()
  def batch_get_pay_gift_card(client, body) do
    client.post("/card/paygiftcard/batchget", body,
      query: [access_token: client.get_access_token()]
    )
  end
end
