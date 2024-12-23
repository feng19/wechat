defmodule WeChat.MiniProgram.SubscribeMessage do
  @moduledoc """
  订阅信息

  - [官方文档](https://developers.weixin.qq.com/miniprogram/dev/framework/open-ability/subscribe-message.html)
  """
  import Jason.Helpers

  @type notify_type :: String.t()
  @type notify_code :: String.t()
  @type send_data :: WeChat.SubscribeMessage.send_data()

  defdelegate add_template(client, tid, kid_list, scene_desc \\ ""), to: WeChat.SubscribeMessage
  defdelegate delete_template(client, pri_tmpl_id), to: WeChat.SubscribeMessage
  defdelegate get_category(client), to: WeChat.SubscribeMessage
  defdelegate get_pub_template_key_words_by_id(client, tid), to: WeChat.SubscribeMessage

  defdelegate get_pub_template_titles(client, ids, start \\ 0, limit \\ 30),
    to: WeChat.SubscribeMessage

  defdelegate get_templates(client), to: WeChat.SubscribeMessage
  defdelegate send(client, openid, template_id, data, options \\ %{}), to: WeChat.SubscribeMessage

  @doc """
  激活与更新服务卡片 -
  [官方文档](https://developers.weixin.qq.com/miniprogram/dev/OpenApiDoc/mp-message-management/subscribe-message/setUserNotify.html){:target="_blank"}

  服务卡片详细介绍: [新版一次性订阅消息开发指南](https://developers.weixin.qq.com/miniprogram/dev/framework/open-ability/subscribe-message-2.html)
  """
  @spec set_user_notify(
          WeChat.client(),
          WeChat.openid(),
          notify_type,
          notify_code,
          send_data,
          pay_check :: map
        ) :: WeChat.response()
  def set_user_notify(client, openid, notify_type, notify_code, send_data, pay_check \\ nil) do
    content_json = Jason.encode!(send_data)

    body =
      if pay_check do
        check_json = Jason.encode!(pay_check)

        json_map(
          openid: openid,
          notify_type: notify_type,
          notify_code: notify_code,
          content_json: content_json,
          check_json: check_json
        )
      else
        json_map(
          openid: openid,
          notify_type: notify_type,
          notify_code: notify_code,
          content_json: content_json
        )
      end

    client.post("/wxa/set_user_notify", body, query: [access_token: client.get_access_token()])
  end

  @doc """
  查询服务卡片状态 -
  [官方文档](https://developers.weixin.qq.com/miniprogram/dev/OpenApiDoc/mp-message-management/subscribe-message/getUserNotify.html){:target="_blank"}

  服务卡片详细介绍: [新版一次性订阅消息开发指南](https://developers.weixin.qq.com/miniprogram/dev/framework/open-ability/subscribe-message-2.html)
  """
  @spec get_user_notify(WeChat.client(), WeChat.openid(), notify_type, notify_code) ::
          WeChat.response()
  def get_user_notify(client, openid, notify_type, notify_code) do
    client.post(
      "/wxa/get_user_notify",
      json_map(openid: openid, notify_type: notify_type, notify_code: notify_code),
      query: [access_token: client.get_access_token()]
    )
  end

  @doc """
  更新服务卡片扩展信息 -
  [官方文档](https://developers.weixin.qq.com/miniprogram/dev/OpenApiDoc/mp-message-management/subscribe-message/setUserNotifyExt.html){:target="_blank"}

  服务卡片详细介绍: [新版一次性订阅消息开发指南](https://developers.weixin.qq.com/miniprogram/dev/framework/open-ability/subscribe-message-2.html)
  """
  @spec set_user_notify_ext(
          WeChat.client(),
          WeChat.openid(),
          notify_type,
          notify_code,
          data :: map
        ) :: WeChat.response()
  def set_user_notify_ext(client, openid, notify_type, notify_code, data) do
    ext_json = Jason.encode!(data)

    client.post(
      "/wxa/set_user_notifyext",
      json_map(
        openid: openid,
        notify_type: notify_type,
        notify_code: notify_code,
        ext_json: ext_json
      ),
      query: [access_token: client.get_access_token()]
    )
  end
end
