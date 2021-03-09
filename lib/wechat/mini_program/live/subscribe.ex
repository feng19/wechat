defmodule WeChat.MiniProgram.Live.Subscribe do
  @moduledoc """
  小程序 - 直播长期订阅相关接口
  """
  import Jason.Helpers
  import WeChat.Utils, only: [doc_link_prefix: 0]
  alias WeChat.MiniProgram.Live.Room

  @doc_link "#{doc_link_prefix()}/miniprogram/dev/framework/liveplayer/subscribe-api.html"

  @type limit :: 1..2000
  @typedoc "翻页标记，获取第一页时不带，第二页开始需带上上一页返回结果中的page_break"
  @type page_break :: integer

  @doc """
  获取长期订阅用户 -
  [官方文档](#{@doc_link}#_1-获取长期订阅用户){:target="_blank"}

  调用此接口获取长期订阅用户列表
  """
  @spec get_subscribe_list(WeChat.client(), page_break, limit) :: WeChat.response()
  def get_subscribe_list(client, page_break \\ nil, limit \\ 200) do
    body =
      if page_break do
        json_map(page_break: page_break, limit: limit)
      else
        json_map(limit: limit)
      end

    client.post("/wxa/business/get_wxa_followers", body,
      query: [access_token: client.get_access_token()]
    )
  end

  @doc """
  长期订阅群发接口 -
  [官方文档](#{@doc_link}#_2-长期订阅群发接口){:target="_blank"}

  向长期订阅用户群发直播间开始事件
  """
  @spec push_message(WeChat.client(), Room.room_id(), WeChat.openid_list()) :: WeChat.response()
  def push_message(client, room_id, openid_list) do
    client.post(
      "/wxa/business/push_message",
      json_map(room_id: room_id, user_openid: openid_list),
      query: [access_token: client.get_access_token()]
    )
  end
end
