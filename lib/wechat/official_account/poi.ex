defmodule WeChat.POI do
  @moduledoc """
  微信门店接口

  [官方文档](https://developers.weixin.qq.com/doc/offiaccount/WeChat_Stores/WeChat_Store_Interface.html){:target="_blank"}
  """
  import Jason.Helpers
  import WeChat.Utils, only: [doc_link_prefix: 0]

  @doc_link "#{doc_link_prefix()}/doc/offiaccount/WeChat_Stores/WeChat_Store_Interface.html"

  @type poi_id :: String.t()
  @typep body :: map

  @doc """
  创建门店 -
  [官方文档](#{@doc_link}#_3-2创建门店){:target="_blank"}

  创建门店接口是为商户提供创建自己门店数据的接口，门店数据字段越完整，商户页面展示越丰富，越能够吸引更多用户，并提高曝光度。

  创建门店接口调用成功后会返回errcode 0、errmsg ok，会实时返回唯一的poiid。
  """
  @spec create(WeChat.client(), body) :: WeChat.response()
  def create(client, body) do
    client.post("/cgi-bin/poi/addpoi", body, query: [access_token: client.get_access_token()])
  end

  @doc """
  查询门店 -
  [官方文档](#{@doc_link}#_3-4查询门店信息){:target="_blank"}

  创建门店后获取poi_id 后，商户可以利用poi_id，查询具体某条门店的信息。 若在查询时，
  update_status 字段为1，表明在5 个工作日内曾用update 接口修改过门店扩展字段，该扩展字段为最新的修改字段，尚未经过审核采纳，因此不是最终结果。
  最终结果会在5 个工作日内，最终确认是否采纳，并前端生效（但该扩展字段的采纳过程不影响门店的可用性，即available_state仍为审核通过状态）

  注：修改扩展字段将会推送审核，但不会影响该门店的生效可用状态。
  """
  @spec get(WeChat.client(), poi_id) :: WeChat.response()
  def get(client, poi_id) do
    client.post("/cgi-bin/poi/getpoi", json_map(poi_id: poi_id),
      query: [access_token: client.get_access_token()]
    )
  end

  @doc """
  查询门店列表 -
  [官方文档](#{@doc_link}#_3-5查询门店列表){:target="_blank"}

  商户可以通过该接口，批量查询自己名下的门店list，并获取已审核通过的poiid、商户自身sid 用于对应、商户名、分店名、地址字段。
  """
  @spec list(WeChat.client(), begin :: integer, limit :: integer) :: WeChat.response()
  def list(client, begin \\ 0, limit \\ 20) when limit <= 50 do
    client.post("/cgi-bin/poi/getpoilist", json_map(begin: begin, limit: limit),
      query: [access_token: client.get_access_token()]
    )
  end

  @doc """
  修改门店服务信息 -
  [官方文档](#{@doc_link}#_3-6修改门店服务信息){:target="_blank"}

  商户可以通过该接口，修改门店的服务信息，包括：sid、图片列表、营业时间、推荐、特色服务、简介、人均价格、电话8个字段（名称、坐标、地址等不可修改）修改后需要人工审核。
  """
  @spec update(WeChat.client(), body) :: WeChat.response()
  def update(client, body) do
    client.post("/cgi-bin/poi/updatepoi", body, query: [access_token: client.get_access_token()])
  end

  @doc """
  修改门店服务信息 -
  [官方文档](#{@doc_link}#_3-7删除门店){:target="_blank"}

  商户可以通过该接口，删除已经成功创建的门店。请商户慎重调用该接口。
  """
  @spec delete(WeChat.client(), poi_id) :: WeChat.response()
  def delete(client, poi_id) do
    client.post("/cgi-bin/poi/delpoi", json_map(poi_id: poi_id),
      query: [access_token: client.get_access_token()]
    )
  end

  @doc """
  门店类目表 -
  [官方文档](#{@doc_link}#_4-门店类目表){:target="_blank"}

  类目名称接口是为商户提供自己门店类型信息的接口。门店类目定位的越规范，能够精准的吸引更多用户，提高曝光率。
  """
  @spec list_category(WeChat.client()) :: WeChat.response()
  def list_category(client) do
    client.get("/cgi-bin/poi/getwxcategory", query: [access_token: client.get_access_token()])
  end
end
