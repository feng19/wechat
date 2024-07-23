defmodule WeChat.EInvoice do
  @moduledoc """
  电子发票

  [官方文档](https://developers.weixin.qq.com/doc/offiaccount/WeChat_Invoice/E_Invoice/Instruction.html){:target="_blank"}
  """

  @doc_link "https://developers.weixin.qq.com/doc/offiaccount/WeChat_Invoice/E_Invoice/Vendor_API_List.html"

  @doc """
  获取授权页链接 -
  [官方文档](#{@doc_link}#2){:target="_blank"}
  """
  @spec get_auth_url(WeChat.client(), body :: map) :: WeChat.response()
  def get_auth_url(client, body) do
    client.post("/card/invoice/getauthurl", body,
      query: [access_token: client.get_access_token()]
    )
  end

  @doc """
  查询授权完成状态 -
  [官方文档](#{@doc_link}#7){:target="_blank"}
  """
  @spec get_auth_data(WeChat.client(), body :: map) :: WeChat.response()
  def get_auth_data(client, body) do
    client.post("/card/invoice/getauthdata", body,
      query: [access_token: client.get_access_token()]
    )
  end

  @doc """
  拒绝开票 -
  [官方文档](#{@doc_link}#8){:target="_blank"}
  """
  @spec reject_insert(WeChat.client(), body :: map) :: WeChat.response()
  def reject_insert(client, body) do
    client.post("/card/invoice/rejectinsert", body,
      query: [access_token: client.get_access_token()]
    )
  end

  @doc """
  设置授权页字段信息 -
  [官方文档](#{@doc_link}#9){:target="_blank"}
  """
  @spec set_auth_field(WeChat.client(), body :: map) :: WeChat.response()
  def set_auth_field(client, body) do
    client.post("/card/invoice/setbizattr", body,
      query: [action: "set_auth_field", access_token: client.get_access_token()]
    )
  end

  @doc """
  查询授权页字段信息 -
  [官方文档](#{@doc_link}#10){:target="_blank"}
  """
  @spec get_auth_field(WeChat.client()) :: WeChat.response()
  def get_auth_field(client) do
    client.post("/card/invoice/setbizattr", %{},
      query: [action: "get_auth_field", access_token: client.get_access_token()]
    )
  end

  @doc """
  关联商户号与开票平台 -
  [官方文档](#{@doc_link}#11){:target="_blank"}
  """
  @spec set_pay_mch(WeChat.client(), body :: map) :: WeChat.response()
  def set_pay_mch(client, body) do
    client.post("/card/invoice/setbizattr", body,
      query: [action: "set_pay_mch", access_token: client.get_access_token()]
    )
  end

  @doc """
  查询商户号与开票平台关联情况 -
  [官方文档](#{@doc_link}#12){:target="_blank"}
  """
  @spec get_pay_mch(WeChat.client()) :: WeChat.response()
  def get_pay_mch(client) do
    client.post("/card/invoice/setbizattr", %{},
      query: [action: "get_pay_mch", access_token: client.get_access_token()]
    )
  end

  @doc """
  设置商户联系方式 -
  [官方文档](#{@doc_link}#14){:target="_blank"}
  """
  @spec set_contact(WeChat.client(), body :: map) :: WeChat.response()
  def set_contact(client, body) do
    client.post("/card/invoice/setbizattr", body,
      query: [action: "set_contact", access_token: client.get_access_token()]
    )
  end

  @doc """
  查询商户联系方式 -
  [官方文档](#{@doc_link}#15){:target="_blank"}
  """
  @spec get_contact(WeChat.client()) :: WeChat.response()
  def get_contact(client) do
    client.post("/card/invoice/setbizattr", %{},
      query: [action: "get_contact", access_token: client.get_access_token()]
    )
  end
end
