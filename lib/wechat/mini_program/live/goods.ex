defmodule WeChat.MiniProgram.Live.Goods do
  @moduledoc """
  小程序 - 直播商品管理
  """
  import Jason.Helpers
  import WeChat.Utils, only: [doc_link_prefix: 0]

  @doc_link "#{doc_link_prefix()}/miniprogram/dev/framework/liveplayer/commodity-api.html"

  @typedoc "审核单ID"
  @type audit_id :: integer
  @typedoc "商品ID"
  @type goods_id :: integer
  @typedoc "商品ID - 列表"
  @type goods_ids :: [goods_id]
  @typedoc "商品状态，0：未审核。1：审核中，2：审核通过，3：审核驳回"
  @type status :: 0..3
  @type offset :: integer
  @type limit :: 1..100

  @doc """
  商品添加并提审 -
  [官方文档](#{@doc_link}#1){:target="_blank"}

  调用此接口上传并提审需要直播的商品信息，审核通过后商品录入【小程序直播】商品库
  """
  @spec add_goods(WeChat.client(), goods_info :: map) :: WeChat.response()
  def add_goods(client, goods_info) do
    client.post(
      "/wxaapi/broadcast/goods/add",
      json_map(goodsInfo: goods_info),
      query: [access_token: client.get_access_token()]
    )
  end

  @doc """
  撤回商品审核 -
  [官方文档](#{@doc_link}#2){:target="_blank"}

  调用此接口，可撤回直播商品的提审申请，消耗的提审次数不返还
  """
  @spec reset_audit(WeChat.client(), goods_id, audit_id) :: WeChat.response()
  def reset_audit(client, goods_id, audit_id) do
    client.post(
      "/wxaapi/broadcast/goods/resetaudit",
      json_map(auditId: audit_id, goodsId: goods_id),
      query: [access_token: client.get_access_token()]
    )
  end

  @doc """
  重新提交商品审核 -
  [官方文档](#{@doc_link}#3){:target="_blank"}

  调用此接口可以对已撤回提审的商品再次发起提审申请
  """
  @spec audit(WeChat.client(), goods_id) :: WeChat.response()
  def audit(client, goods_id) do
    client.post(
      "/wxaapi/broadcast/goods/audit",
      json_map(goodsId: goods_id),
      query: [access_token: client.get_access_token()]
    )
  end

  @doc """
  删除商品 -
  [官方文档](#{@doc_link}#4){:target="_blank"}

  调用此接口，可删除【小程序直播】商品库中的商品，删除后直播间上架的该商品也将被同步删除，不可恢复
  """
  @spec delete_goods(WeChat.client(), goods_id) :: WeChat.response()
  def delete_goods(client, goods_id) do
    client.post(
      "/wxaapi/broadcast/goods/delete",
      json_map(goodsId: goods_id),
      query: [access_token: client.get_access_token()]
    )
  end

  @doc """
  更新商品 -
  [官方文档](#{@doc_link}#5){:target="_blank"}

  调用此接口可以更新商品信息，审核通过的商品仅允许更新价格类型与价格，审核中的商品不允许更新，未审核的商品允许更新所有字段，只传入需要更新的字段
  """
  @spec update_goods(WeChat.client(), goods_info :: map) :: WeChat.response()
  def update_goods(client, goods_info) do
    client.post(
      "/wxaapi/broadcast/goods/update",
      json_map(goodsInfo: goods_info),
      query: [access_token: client.get_access_token()]
    )
  end

  @doc """
  获取商品状态 -
  [官方文档](#{@doc_link}#6){:target="_blank"}

  调用此接口可获取商品的信息与审核状态
  """
  @spec get_goods_status(WeChat.client(), goods_ids) :: WeChat.response()
  def get_goods_status(client, goods_ids) do
    client.post(
      "/wxa/business/getgoodswarehouse",
      json_map(goods_ids: goods_ids),
      query: [access_token: client.get_access_token()]
    )
  end

  @doc """
  获取商品列表 -
  [官方文档](#{@doc_link}#7){:target="_blank"}

  调用此接口可获取商品列表
  """
  @spec get_goods_list(WeChat.client(), status, offset, limit) :: WeChat.response()
  def get_goods_list(client, status, offset, limit \\ 30) do
    client.get("/wxaapi/broadcast/goods/getapproved",
      query: [
        status: status,
        offset: offset,
        limit: limit,
        access_token: client.get_access_token()
      ]
    )
  end
end
