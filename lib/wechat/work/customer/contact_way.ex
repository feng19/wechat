defmodule WeChat.Work.Customer.ContactWay do
  @moduledoc "客户联系-联系我"

  import Jason.Helpers
  alias WeChat.{Work, Work.Customer, Work.Contacts.User}

  @type config_id :: String.t()

  @doc """
  配置客户联系「联系我」方式 -
  [官方文档](https://developer.work.weixin.qq.com/document/path/92228#配置客户联系「联系我」方式){:target="_blank"}

  企业可以在管理后台-客户联系-加客户中配置成员的「联系我」的二维码或者小程序按钮，客户通过扫描二维码或点击小程序上的按钮，即可获取成员联系方式，主动联系到成员。
  企业可通过此接口为具有客户联系功能的成员生成专属的「联系我」二维码或者「联系我」按钮。
  如果配置的是「联系我」按钮，需要开发者的小程序接入小程序插件。

  注意:
  通过API添加的「联系我」不会在管理端进行展示，每个企业可通过API最多配置50万个「联系我」。
  用户需要妥善存储返回的config_id，config_id丢失可能导致用户无法编辑或删除「联系我」。
  临时会话模式不占用「联系我」数量，但每日最多添加10万个，并且仅支持单人。
  临时会话模式的二维码，添加好友完成后该二维码即刻失效。
  """
  @spec add(Work.client(), Work.agent(), body :: map) :: WeChat.response()
  def add(client, agent, body) do
    client.post("/cgi-bin/externalcontact/add_contact_way", body,
      query: [access_token: client.get_access_token(agent)]
    )
  end

  @doc """
  获取企业已配置的「联系我」方式 -
  [官方文档](https://developer.work.weixin.qq.com/document/path/92228#获取企业已配置的「联系我」方式){:target="_blank"}

  获取企业配置的「联系我」二维码和「联系我」小程序按钮。
  """
  @spec get(Work.client(), Work.agent(), config_id) :: WeChat.response()
  def get(client, agent, config_id) do
    client.post("/cgi-bin/externalcontact/get_contact_way", json_map(config_id: config_id),
      query: [access_token: client.get_access_token(agent)]
    )
  end

  @doc """
  更新企业已配置的「联系我」方式 -
  [官方文档](https://developer.work.weixin.qq.com/document/path/92228#更新企业已配置的「联系我」方式){:target="_blank"}

  更新企业配置的「联系我」二维码和「联系我」小程序按钮中的信息，如使用人员和备注等。
  """
  @spec update(Work.client(), Work.agent(), body :: map) :: WeChat.response()
  def update(client, agent, body) do
    client.post("/cgi-bin/externalcontact/update_contact_way", body,
      query: [access_token: client.get_access_token(agent)]
    )
  end

  @doc """
  删除企业已配置的「联系我」方式 -
  [官方文档](https://developer.work.weixin.qq.com/document/path/92228#删除企业已配置的「联系我」方式){:target="_blank"}

  删除一个已配置的「联系我」二维码或者「联系我」小程序按钮。
  """
  @spec delete(Work.client(), Work.agent(), config_id) :: WeChat.response()
  def delete(client, agent, config_id) do
    client.post("/cgi-bin/externalcontact/del_contact_way", json_map(config_id: config_id),
      query: [access_token: client.get_access_token(agent)]
    )
  end

  @doc """
  结束临时会话 -
  [官方文档](https://developer.work.weixin.qq.com/document/path/92228#结束临时会话){:target="_blank"}

  删除一个已配置的「联系我」二维码或者「联系我」小程序按钮。
  """
  @spec close_temp_chat(
          Work.client(),
          Work.agent(),
          User.userid(),
          Customer.external_userid()
        ) :: WeChat.response()
  def close_temp_chat(client, agent, userid, external_userid) do
    client.post(
      "/cgi-bin/externalcontact/close_temp_chat",
      json_map(userid: userid, external_userid: external_userid),
      query: [access_token: client.get_access_token(agent)]
    )
  end
end
