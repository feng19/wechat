defmodule WeChat.MiniProgram.Store do
  @moduledoc """
  小程序 - 门店接口

  [官方文档](https://developers.weixin.qq.com/doc/offiaccount/WeChat_Stores/WeChat_Shop_Miniprogram_Interface.html){:target="_blank"}
  """
  import Jason.Helpers
  import WeChat.Utils, only: [doc_link_prefix: 0]

  @doc_link "#{doc_link_prefix()}/doc/offiaccount/WeChat_Stores/WeChat_Shop_Miniprogram_Interface.html"

  @type poi_id :: String.t()
  @typedoc "对应 拉取省市区信息接口 中的id字段"
  @type district_id :: String.t()
  @typep body :: map

  @doc """
  申请门店 -
  [官方文档](#{@doc_link}#_2-创建门店小程序){:target="_blank"}

  创建门店小程序提交后需要公众号管理员确认通过后才可进行审核。如果主管理员24小时超时未确认，才能再次提交。
  """
  @spec apply(WeChat.client(), body) :: WeChat.response()
  def apply(client, body) do
    client.post("/wxa/apply_merchant", body, query: [access_token: client.get_access_token()])
  end

  @doc """
  查询门店小程序审核结果 -
  [官方文档](#{@doc_link}#_3-查询门店小程序审核结果){:target="_blank"}

  创建门店小程序提交后需要公众号管理员确认通过后才可进行审核。如果主管理员24小时超时未确认，才能再次提交。
  """
  @spec query_audit_info(WeChat.client()) :: WeChat.response()
  def query_audit_info(client) do
    client.get("/wxa/get_merchant_audit_info", query: [access_token: client.get_access_token()])
  end

  @doc """
  修改门店小程序信息 -
  [官方文档](#{@doc_link}#_4-修改门店小程序信息){:target="_blank"}
  """
  @spec modify(WeChat.client(), body) :: WeChat.response()
  def modify(client, body) do
    client.post("/wxa/modify_merchant", body, query: [access_token: client.get_access_token()])
  end

  @doc """
  从腾讯地图拉取省市区信息 -
  [官方文档](#{@doc_link}#_5-从腾讯地图拉取省市区信息){:target="_blank"}
  """
  @spec get_district(WeChat.client()) :: WeChat.response()
  def get_district(client) do
    client.get("/wxa/get_district", query: [access_token: client.get_access_token()])
  end

  @doc """
  在腾讯地图中搜索门店 -
  [官方文档](#{@doc_link}#_6-在腾讯地图中搜索门店){:target="_blank"}
  """
  @spec map_search(WeChat.client(), district_id, keyword :: String.t()) :: WeChat.response()
  def map_search(client, district_id, keyword) do
    client.post("/wxa/search_map_poi", json_map(district_id: district_id, keyword: keyword),
      query: [access_token: client.get_access_token()]
    )
  end

  @doc """
  在腾讯地图中创建门店 -
  [官方文档](#{@doc_link}#_7-在腾讯地图中创建门店){:target="_blank"}
  """
  @spec create_map_poi(WeChat.client(), body) :: WeChat.response()
  def create_map_poi(client, body) do
    client.post("/wxa/create_map_poi", body, query: [access_token: client.get_access_token()])
  end

  @doc """
  添加门店 -
  [官方文档](#{@doc_link}#_8-添加门店){:target="_blank"}
  """
  @spec add(WeChat.client(), body) :: WeChat.response()
  def add(client, body) do
    client.post("/wxa/add_store", body, query: [access_token: client.get_access_token()])
  end

  @doc """
  更新门店信息 -
  [官方文档](#{@doc_link}#_9-更新门店信息){:target="_blank"}
  """
  @spec update(WeChat.client(), body) :: WeChat.response()
  def update(client, body) do
    client.post("/wxa/update_store", body, query: [access_token: client.get_access_token()])
  end

  @doc """
  获取单个门店信息 -
  [官方文档](#{@doc_link}#_10-获取单个门店信息){:target="_blank"}
  """
  @spec get(WeChat.client(), poi_id) :: WeChat.response()
  def get(client, poi_id) do
    client.post("/wxa/get_store_info", json_map(poi_id: poi_id),
      query: [access_token: client.get_access_token()]
    )
  end

  @doc """
  获取门店信息列表 -
  [官方文档](#{@doc_link}#_11-获取门店信息列表){:target="_blank"}
  """
  @spec list(WeChat.client(), offset :: integer, limit :: integer) :: WeChat.response()
  def list(client, offset \\ 0, limit \\ 20) when limit <= 50 do
    client.post("/wxa/get_store_list", json_map(offset: offset, limit: limit),
      query: [access_token: client.get_access_token()]
    )
  end

  @doc """
  删除门店 -
  [官方文档](#{@doc_link}#_12-删除门店){:target="_blank"}
  """
  @spec delete(WeChat.client(), poi_id) :: WeChat.response()
  def delete(client, poi_id) do
    client.post("/wxa/del_store", json_map(poi_id: poi_id),
      query: [access_token: client.get_access_token()]
    )
  end

  @doc """
  门店小程序卡券 -
  [官方文档](#{@doc_link}#_14-业务接口-门店小程序卡券){:target="_blank"}
  """
  @spec get_card(WeChat.client(), poi_id) :: WeChat.response()
  def get_card(client, poi_id) do
    client.post("/card/storewxa/get", json_map(poi_id: poi_id),
      query: [access_token: client.get_access_token()]
    )
  end

  @doc """
  拉取类目 -
  [官方文档](#{@doc_link}#_1-拉取门店小程序类目){:target="_blank"}
  """
  @spec list_category(WeChat.client()) :: WeChat.response()
  def list_category(client) do
    client.get("/wxa/get_merchant_category", query: [access_token: client.get_access_token()])
  end
end
