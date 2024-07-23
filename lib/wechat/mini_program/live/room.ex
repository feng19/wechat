defmodule WeChat.MiniProgram.Live.Room do
  @moduledoc """
  小程序 - 直播间管理
  """
  import Jason.Helpers
  alias WeChat.{User, MiniProgram.Live.Goods}

  @doc_link "https://developers.weixin.qq.com/miniprogram/dev/framework/liveplayer/studio-api.html"

  @type start :: integer
  @type limit :: 1..100
  @type room_id :: integer

  @type user :: %{username: User.username(), nickname: User.nickname()}
  @type users :: [user]

  @typedoc "是否开启官方收录 【1: 开启，0：关闭】"
  @type is_feeds_public :: boolean | 0 | 1
  @typedoc "是否关闭回放 【0：开启，1：关闭】"
  @type is_close_replay :: boolean | 0 | 1
  @typedoc "是否关闭客服 【0：开启，1：关闭】"
  @type is_close_kf :: boolean | 0 | 1
  @typedoc "是否开启禁言 【0：开启，1：关闭】"
  @type is_ban_comment :: boolean | 0 | 1
  @typedoc "上下架 【0：下架，1：上架】"
  @type is_on_sale :: boolean | 0 | 1

  @doc """
  创建直播间 -
  [官方文档](#{@doc_link}#1){:target="_blank"}

  该接口可直接创建直播间，创建成功后直播间将在直播间列表展示
  """
  @spec create_room(WeChat.client(), data :: map) :: WeChat.response()
  def create_room(client, data) do
    client.post(
      "/wxaapi/broadcast/room/create",
      data,
      query: [access_token: client.get_access_token()]
    )
  end

  @doc """
  获取直播房间列表 -
  [官方文档](#{@doc_link}#2){:target="_blank"}

  该接口可获取直播房间列表
  """
  @spec get_live_info(WeChat.client(), start, limit) :: WeChat.response()
  def get_live_info(client, start \\ 0, limit \\ 10) do
    client.post(
      "/wxa/business/getliveinfo",
      json_map(start: start, limit: limit),
      query: [access_token: client.get_access_token()]
    )
  end

  @doc """
  获取直播间回放 -
  [官方文档](#{@doc_link}#3){:target="_blank"}

  该接口可在直播结束后拿到回放源视频
  """
  @spec get_replay(WeChat.client(), room_id, start, limit) :: WeChat.response()
  def get_replay(client, room_id, start \\ 0, limit \\ 10) do
    client.post(
      "/wxa/business/getliveinfo",
      json_map(action: "get_replay", room_id: room_id, start: start, limit: limit),
      query: [access_token: client.get_access_token()]
    )
  end

  @doc """
  直播间导入商品 -
  [官方文档](#{@doc_link}#4){:target="_blank"}

  调用此接口往指定直播间导入已入库的商品
  """
  @spec add_goods(WeChat.client(), room_id, Goods.goods_ids()) :: WeChat.response()
  def add_goods(client, room_id, goods_ids) do
    client.post(
      "/wxaapi/broadcast/room/addgoods",
      json_map(roomId: room_id, ids: goods_ids),
      query: [access_token: client.get_access_token()]
    )
  end

  @doc """
  删除直播间 -
  [官方文档](#{@doc_link}#5){:target="_blank"}
  """
  @spec delete_room(WeChat.client(), room_id) :: WeChat.response()
  def delete_room(client, room_id) do
    client.post(
      "/wxaapi/broadcast/room/deleteroom",
      json_map(id: room_id),
      query: [access_token: client.get_access_token()]
    )
  end

  @doc """
  编辑直播间 -
  [官方文档](#{@doc_link}#6){:target="_blank"}
  """
  @spec edit_room(WeChat.client(), data :: map) :: WeChat.response()
  def edit_room(client, data) do
    client.post(
      "/wxaapi/broadcast/room/editroom",
      data,
      query: [access_token: client.get_access_token()]
    )
  end

  @doc """
  获取直播间推流地址 -
  [官方文档](#{@doc_link}#7){:target="_blank"}
  """
  @spec get_push_url(WeChat.client(), room_id) :: WeChat.response()
  def get_push_url(client, room_id) do
    client.get("/wxaapi/broadcast/room/getpushurl",
      query: [roomId: room_id, access_token: client.get_access_token()]
    )
  end

  @doc """
  获取直播间分享二维码 -
  [官方文档](#{@doc_link}#8){:target="_blank"}
  """
  @spec get_shared_code(WeChat.client(), room_id, params :: map) :: WeChat.response()
  def get_shared_code(client, room_id, params \\ %{}) do
    query = [
      roomId: room_id,
      access_token: client.get_access_token()
    ]

    query =
      if Enum.empty?(params) do
        query
      else
        [{:params, Jason.encode!(params)} | query]
      end

    client.get("/wxaapi/broadcast/room/getsharedcode", query: query)
  end

  @doc """
  添加管理直播间小助手 -
  [官方文档](#{@doc_link}#9){:target="_blank"}
  """
  @spec add_assistant(WeChat.client(), room_id, users) :: WeChat.response()
  def add_assistant(client, room_id, users) do
    client.post(
      "/wxaapi/broadcast/room/addassistant",
      json_map(roomId: room_id, users: users),
      query: [access_token: client.get_access_token()]
    )
  end

  @doc """
  修改管理直播间小助手 -
  [官方文档](#{@doc_link}#10){:target="_blank"}
  """
  @spec modify_assistant(WeChat.client(), room_id, User.username(), User.nickname()) ::
          WeChat.response()
  def modify_assistant(client, room_id, username, nickname) do
    client.post(
      "/wxaapi/broadcast/room/modifyassistant",
      json_map(roomId: room_id, username: username, nickname: nickname),
      query: [access_token: client.get_access_token()]
    )
  end

  @doc """
  删除管理直播间小助手 -
  [官方文档](#{@doc_link}#11){:target="_blank"}
  """
  @spec remove_assistant(WeChat.client(), room_id, User.username()) :: WeChat.response()
  def remove_assistant(client, room_id, username) do
    client.post(
      "/wxaapi/broadcast/room/removeassistant",
      json_map(roomId: room_id, username: username),
      query: [access_token: client.get_access_token()]
    )
  end

  @doc """
  查询管理直播间小助手 -
  [官方文档](#{@doc_link}#12){:target="_blank"}
  """
  @spec get_assistant_list(WeChat.client(), room_id) :: WeChat.response()
  def get_assistant_list(client, room_id) do
    client.get("/wxaapi/broadcast/room/getassistantlist",
      query: [roomId: room_id, access_token: client.get_access_token()]
    )
  end

  @doc """
  添加主播副号 -
  [官方文档](#{@doc_link}#13){:target="_blank"}
  """
  @spec add_subanchor(WeChat.client(), room_id, User.username()) :: WeChat.response()
  def add_subanchor(client, room_id, username) do
    client.post(
      "/wxaapi/broadcast/room/addsubanchor",
      json_map(roomId: room_id, username: username),
      query: [access_token: client.get_access_token()]
    )
  end

  @doc """
  修改主播副号 -
  [官方文档](#{@doc_link}#14){:target="_blank"}
  """
  @spec modify_subanchor(WeChat.client(), room_id, User.username()) :: WeChat.response()
  def modify_subanchor(client, room_id, username) do
    client.post(
      "/wxaapi/broadcast/room/modifysubanchor",
      json_map(roomId: room_id, username: username),
      query: [access_token: client.get_access_token()]
    )
  end

  @doc """
  删除主播副号 -
  [官方文档](#{@doc_link}#15){:target="_blank"}
  """
  @spec delete_subanchor(WeChat.client(), room_id) :: WeChat.response()
  def delete_subanchor(client, room_id) do
    client.post(
      "/wxaapi/broadcast/room/deletesubanchor",
      json_map(roomId: room_id),
      query: [access_token: client.get_access_token()]
    )
  end

  @doc """
  获取主播副号 -
  [官方文档](#{@doc_link}#16){:target="_blank"}
  """
  @spec get_subanchor(WeChat.client(), room_id) :: WeChat.response()
  def get_subanchor(client, room_id) do
    client.get("/wxaapi/broadcast/room/getsubanchor",
      query: [roomId: room_id, access_token: client.get_access_token()]
    )
  end

  @doc """
  开启/关闭直播间官方收录 -
  [官方文档](#{@doc_link}#17){:target="_blank"}
  """
  @spec update_feed_public(WeChat.client(), room_id, is_feeds_public) :: WeChat.response()
  def update_feed_public(client, room_id, is_feeds_public) do
    is_feeds_public =
      if is_integer(is_feeds_public) do
        is_feeds_public
      else
        (is_feeds_public && 1) || 0
      end

    client.post(
      "/wxaapi/broadcast/room/updatefeedpublic",
      json_map(roomId: room_id, isFeedsPublic: is_feeds_public),
      query: [access_token: client.get_access_token()]
    )
  end

  @doc """
  开启/关闭回放功能 -
  [官方文档](#{@doc_link}#18){:target="_blank"}
  """
  @spec update_replay(WeChat.client(), room_id, is_close_replay) :: WeChat.response()
  def update_replay(client, room_id, is_close_replay) do
    is_close_replay =
      if is_integer(is_close_replay) do
        is_close_replay
      else
        (is_close_replay && 1) || 0
      end

    client.post(
      "/wxaapi/broadcast/room/updatereplay",
      json_map(roomId: room_id, closeReplay: is_close_replay),
      query: [access_token: client.get_access_token()]
    )
  end

  @doc """
  开启/关闭客服功能 -
  [官方文档](#{@doc_link}#19){:target="_blank"}
  """
  @spec update_kf(WeChat.client(), room_id, is_close_kf) :: WeChat.response()
  def update_kf(client, room_id, is_close_kf) do
    is_close_kf =
      if is_integer(is_close_kf) do
        is_close_kf
      else
        (is_close_kf && 1) || 0
      end

    client.post(
      "/wxaapi/broadcast/room/updatekf",
      json_map(roomId: room_id, closeKf: is_close_kf),
      query: [access_token: client.get_access_token()]
    )
  end

  @doc """
  开启/关闭直播间全局禁言 -
  [官方文档](#{@doc_link}#20){:target="_blank"}
  """
  @spec update_comment(WeChat.client(), room_id, is_ban_comment) :: WeChat.response()
  def update_comment(client, room_id, is_ban_comment) do
    is_ban_comment =
      if is_integer(is_ban_comment) do
        is_ban_comment
      else
        (is_ban_comment && 1) || 0
      end

    client.post(
      "/wxaapi/broadcast/room/updatecomment",
      json_map(roomId: room_id, banComment: is_ban_comment),
      query: [access_token: client.get_access_token()]
    )
  end

  @doc """
  上下架直播间商品 -
  [官方文档](#{@doc_link}#21){:target="_blank"}
  """
  @spec goods_onsale(WeChat.client(), room_id, Goods.goods_id(), is_on_sale) :: WeChat.response()
  def goods_onsale(client, room_id, goods_id, is_on_sale) do
    is_on_sale =
      if is_integer(is_on_sale) do
        is_on_sale
      else
        (is_on_sale && 1) || 0
      end

    client.post(
      "/wxaapi/broadcast/goods/onsale",
      json_map(roomId: room_id, goodsId: goods_id, onSale: is_on_sale),
      query: [access_token: client.get_access_token()]
    )
  end

  @doc """
  删除直播间商品 -
  [官方文档](#{@doc_link}#22){:target="_blank"}
  """
  @spec goods_delete(WeChat.client(), room_id, Goods.goods_id()) :: WeChat.response()
  def goods_delete(client, room_id, goods_id) do
    client.post(
      "/wxaapi/broadcast/goods/deleteInRoom",
      json_map(roomId: room_id, goodsId: goods_id),
      query: [access_token: client.get_access_token()]
    )
  end

  @doc """
  推送商品 -
  [官方文档](#{@doc_link}#23){:target="_blank"}
  """
  @spec goods_push(WeChat.client(), room_id, Goods.goods_id()) :: WeChat.response()
  def goods_push(client, room_id, goods_id) do
    client.post(
      "/wxaapi/broadcast/goods/push",
      json_map(roomId: room_id, goodsId: goods_id),
      query: [access_token: client.get_access_token()]
    )
  end

  @doc """
  直播间商品排序 -
  [官方文档](#{@doc_link}#24){:target="_blank"}
  """
  @spec goods_sort(WeChat.client(), room_id, Goods.goods_ids()) :: WeChat.response()
  def goods_sort(client, room_id, goods_ids) do
    goods = Enum.map(goods_ids, &json_map(goodsId: &1))

    client.post(
      "/wxaapi/broadcast/goods/sort",
      json_map(roomId: room_id, goods: goods),
      query: [access_token: client.get_access_token()]
    )
  end

  @doc """
  下载商品讲解视频 -
  [官方文档](#{@doc_link}#25){:target="_blank"}
  """
  @spec goods_get_video(WeChat.client(), room_id, Goods.goods_id()) :: WeChat.response()
  def goods_get_video(client, room_id, goods_id) do
    client.post(
      "/wxaapi/broadcast/goods/getVideo",
      json_map(roomId: room_id, goodsId: goods_id),
      query: [access_token: client.get_access_token()]
    )
  end
end
