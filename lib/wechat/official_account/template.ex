defmodule WeChat.Template do
  @moduledoc """
  消息管理 - 模板消息

  [官方文档](https://developers.weixin.qq.com/doc/offiaccount/Message_Management/Template_Message_Interface.html){:target="_blank"}
  """
  import Jason.Helpers

  @doc_link "https://developers.weixin.qq.com/doc/offiaccount/Message_Management/Template_Message_Interface.html"

  @type template_id :: String.t()
  @type title :: String.t()
  @type description :: String.t()
  @type url :: String.t()
  @type pic_url :: String.t()
  @type industry_id :: integer

  @doc """
  设置所属行业 -
  [官方文档](#{@doc_link}#0){:target="_blank"}

  每月可修改行业1次，帐号仅可使用所属行业中相关的模板
  """
  @spec api_set_industry(WeChat.client(), industry_id, industry_id) :: WeChat.response()
  def api_set_industry(client, industry_id1, industry_id2) do
    client.post(
      "/cgi-bin/template/api_set_industry",
      json_map(industry_id1: industry_id1, industry_id2: industry_id2),
      query: [access_token: client.get_access_token()]
    )
  end

  @doc """
  获取设置的行业信息 -
  [官方文档](#{@doc_link}#1){:target="_blank"}
  """
  @spec get_industry(WeChat.client()) :: WeChat.response()
  def get_industry(client) do
    client.get("/cgi-bin/template/get_industry",
      query: [access_token: client.get_access_token()]
    )
  end

  @doc """
  获得模板ID -
  [官方文档](#{@doc_link}#2){:target="_blank"}
  """
  @spec api_add_template(WeChat.client(), template_id_short :: String.t()) :: WeChat.response()
  def api_add_template(client, template_id_short) do
    client.post(
      "/cgi-bin/template/api_add_template",
      json_map(template_id_short: template_id_short),
      query: [access_token: client.get_access_token()]
    )
  end

  @doc """
  获取模板列表 -
  [官方文档](#{@doc_link}#3){:target="_blank"}
  """
  @spec get_all_private_template(WeChat.client()) :: WeChat.response()
  def get_all_private_template(client) do
    client.get("/cgi-bin/template/get_all_private_template",
      query: [access_token: client.get_access_token()]
    )
  end

  @doc """
  删除模板 -
  [官方文档](#{@doc_link}#4){:target="_blank"}
  """
  @spec del_private_template(WeChat.client(), template_id) :: WeChat.response()
  def del_private_template(client, template_id) do
    client.post(
      "/cgi-bin/template/del_private_template",
      json_map(template_id: template_id),
      query: [access_token: client.get_access_token()]
    )
  end

  @doc """
  发送模板消息 -
  [官方文档](#{@doc_link}#5){:target="_blank"}
  """
  @spec send_template_message(WeChat.client(), WeChat.openid(), template_id, data :: map) ::
          WeChat.response()
  def send_template_message(client, openid, template_id, data) do
    client.post(
      "/cgi-bin/message/template/send",
      json_map(touser: openid, template_id: template_id, data: data),
      query: [access_token: client.get_access_token()]
    )
  end

  @doc """
  发送模板消息 -
  [官方文档](#{@doc_link}#5){:target="_blank"}
  """
  @spec send_template_message(WeChat.client(), body :: map) :: WeChat.response()
  def send_template_message(client, body) do
    client.post("/cgi-bin/message/template/send", body,
      query: [access_token: client.get_access_token()]
    )
  end
end
