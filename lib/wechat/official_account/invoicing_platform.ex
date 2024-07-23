defmodule WeChat.InvoicingPlatform do
  @moduledoc """
  开票平台

  [官方文档](https://developers.weixin.qq.com/doc/offiaccount/WeChat_Invoice/E_Invoice/Choosing_Access_Mode.html){:target="_blank"}
  """

  @doc_link "https://developers.weixin.qq.com/doc/offiaccount/WeChat_Invoice/E_Invoice/Invoicing_Platform_API_List.html"

  @doc """
  获取自身的开票平台识别码 -
  [官方文档](#{@doc_link}#1){:target="_blank"}
  """
  @spec get_url(WeChat.client()) :: WeChat.response()
  def get_url(client) do
    client.post("/card/invoice/seturl", %{}, query: [access_token: client.get_access_token()])
  end

  @doc """
  创建发票卡券模板 -
  [官方文档](#{@doc_link}#2){:target="_blank"}
  """
  @spec create_card(WeChat.client(), body :: map) :: WeChat.response()
  def create_card(client, body) do
    client.post("/card/invoice/platform/createcard", body,
      query: [access_token: client.get_access_token()]
    )
  end

  @doc """
  上传PDF -
  [官方文档](#{@doc_link}#3){:target="_blank"}
  """
  @spec set_pdf(WeChat.client(), body :: map) :: WeChat.response()
  def set_pdf(client, body) do
    client.post("/card/invoice/platform/setpdf", body,
      query: [access_token: client.get_access_token()]
    )
  end

  @doc """
  查询已上传的PDF文件 -
  [官方文档](#{@doc_link}#4){:target="_blank"}
  """
  @spec get_pdf(WeChat.client(), body :: map) :: WeChat.response()
  def get_pdf(client, body) do
    client.post("/card/invoice/platform/getpdf", body,
      query: [access_token: client.get_access_token()]
    )
  end

  @doc """
  将电子发票卡券插入用户卡包 -
  [官方文档](#{@doc_link}#5){:target="_blank"}
  """
  @spec insert(WeChat.client(), body :: map) :: WeChat.response()
  def insert(client, body) do
    client.post("/card/invoice/insert", body, query: [access_token: client.get_access_token()])
  end

  @doc """
  更新发票卡券状态 -
  [官方文档](#{@doc_link}#6){:target="_blank"}
  """
  @spec update_status(WeChat.client(), body :: map) :: WeChat.response()
  def update_status(client, body) do
    client.post("/card/invoice/platform/updatestatus", body,
      query: [access_token: client.get_access_token()]
    )
  end

  defdelegate decrypt_code(client, encrypt_code), to: WeChat.Card
end
