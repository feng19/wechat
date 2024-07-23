defmodule WeChat.MiniProgram.NearbyPOI do
  @moduledoc """
  附件的小程序
  """

  import Jason.Helpers

  @typedoc """
  门店图片

  最多9张，最少1张，上传门店图片如门店外景、环境设施、商品服务等，图片将展示在微信客户端的门店页。
  图片链接通过[文档](https://mp.weixin.qq.com/wiki?t=resource/res_main&id=mp1444738729)中的《上传图文消息内的图片获取URL》接口获取。
  文件格式为bmp、png、jpeg、jpg或gif，大小不超过5M `pic_list` 是字符串，内容是一个json
  """
  @type pic_list :: String.t()
  @typedoc """
  服务标签列表

  需要填写

  - 服务标签ID
  - 服务类型tpye
  - 服务名称name
  - APPID
  - 对应服务落地页的path路径：path路径页面要与对应的服务标签一致，例如选取外卖服务，path路径应该是小程序的外卖对应的那个页面，path路径获取咨询开发或者到小程序管理后台-工具-生成小程序码页面获取
  - 新增服务描述desc：描述服务内容，例如满减、折扣等优惠信息或新品、爆品等商品信息，仅标准服务都可添加，10个字符以内。

  《服务标签id编号、类型与服务名称表》

  | ID   | type | name(服务名称)                           |
  | ---- | ---- | ---------------------------------------- |
  | 0    | 2    | 自定义服务，可自定义名称（10个字符以内） |
  | 1    | 1    | 外送                                     |
  | 2    | 1    | 快递                                     |
  | 3    | 1    | 充电                                     |
  | 4    | 1    | 预约                                     |
  | 5    | 1    | 挂号                                     |
  | 6    | 1    | 点餐                                     |
  | 7    | 1    | 优惠                                     |
  | 8    | 1    | 乘车                                     |
  | 9    | 1    | 会员                                     |
  | 10   | 1    | 买单                                     |
  | 11   | 1    | 排队                                     |
  | 12   | 1    | 缴费                                     |
  | 13   | 1    | 购票                                     |
  | 14   | 1    | 到店自提                                 |
  | 15   | 1    | 预订                                     |

  service_infos是字符串，内容是一个json
  """
  @type service_infos :: String.t()
  @typedoc """
  客服信息

  可自定义服务头像与昵称，具体填写字段见下方示例kf_info kf_info是字符串，内容是一个json
  """
  @type kf_info :: String.t()
  @typedoc """
  门店名字

  门店名称需按照所选地理位置自动拉取腾讯地图门店名称，不可修改，如需修改请重现选择地图地点或重新创建地点。
  """
  @type store_name :: String.t()
  @typedoc """
  营业时间

  格式`11:11-12:12`
  """
  @type hour :: String.t()
  @typedoc "地址"
  @type address :: String.t()
  @typedoc "如果创建新的门店，poi_id字段为空 如果更新门店，poi_id参数则填对应门店的poi_id"
  @type poi_id :: String.t()
  @typedoc "主体名字"
  @type company_name :: String.t()
  @typedoc "门店电话"
  @type contract_phone :: String.t()
  @typedoc """
  资质号

  15位营业执照注册号或9位组织机构代码
  """
  @type credential :: String.t()
  @typedoc """
  证明材料

  如果company_name和该小程序主体不一致，需要填qualification_list，
  详细规则见: [附近的小程序使用指南-如何证明门店的经营主体跟公众号或小程序帐号主体相关](http://kf.qq.com/faq/170401MbUnim17040122m2qY.html)
  """
  @type qualification_list :: String.t()
  @typedoc """
  腾讯地图对于poi的唯一标识

  对应《在腾讯地图中搜索门店》中的sosomap_poi_uid字段

  腾讯地图那边有些数据不一致，如果不填map_poi_id的话，小概率会提交失败！

  注：
  `poi_id` 与 `map_poi_id` 关系：
  `map_poi_id` 是腾讯地图对于poi的唯一标识
  `poi_id` 是门店进驻附近后的门店唯一标识
  """
  @type map_poi_id :: String.t()
  @type add_options :: %{
          required(:pic_list) => pic_list,
          required(:service_infos) => service_infos,
          required(:store_name) => store_name,
          required(:hour) => hour,
          required(:address) => address,
          required(:company_name) => company_name,
          required(:contract_phone) => contract_phone,
          required(:credential) => credential,
          optional(:kf_info) => kf_info,
          optional(:poi_id) => poi_id
        }
  @typedoc """
  是否展示

  - 0: 不展示
  - 1: 展示
  """
  @type status :: 0 | 1

  @doc """
  添加地点 -
  [官方文档](https://developers.weixin.qq.com/miniprogram/dev/OpenApiDoc/nearby-poi/addNearbyPoi.html){:target="_blank"}
  """
  @spec add(WeChat.client(), add_options) :: WeChat.response()
  def add(client, options) do
    client.post(
      "/wxa/addnearbypoi",
      Map.put(options, :is_comm_nearby, "1"),
      query: [access_token: client.get_access_token()]
    )
  end

  @doc """
  删除地点 -
  [官方文档](https://developers.weixin.qq.com/miniprogram/dev/OpenApiDoc/nearby-poi/deleteNearbyPoi.html){:target="_blank"}
  """
  @spec delete(WeChat.client(), poi_id) :: WeChat.response()
  def delete(client, poi_id) do
    client.post(
      "/wxa/delnearbypoi",
      json_map(poi_id: poi_id),
      query: [access_token: client.get_access_token()]
    )
  end

  @doc """
  查看地点列表 -
  [官方文档](https://developers.weixin.qq.com/miniprogram/dev/OpenApiDoc/nearby-poi/getNearbyPoiList.html){:target="_blank"}
  """
  @spec get_list(WeChat.client(), start :: non_neg_integer, limit :: 1..1000) :: WeChat.response()
  def get_list(client, start \\ 1, limit \\ 10) do
    client.get(
      "/wxa/getnearbypoilist",
      query: [page: start, page_rows: limit, access_token: client.get_access_token()]
    )
  end

  @doc """
  展示/取消展示附近小程序 -
  [官方文档](https://developers.weixin.qq.com/miniprogram/dev/OpenApiDoc/nearby-poi/setShowStatus.html){:target="_blank"}
  """
  @spec set_show_status(WeChat.client(), poi_id, status) :: WeChat.response()
  def set_show_status(client, poi_id, status) do
    client.post(
      "/wxa/setnearbypoishowstatus",
      json_map(poi_id: poi_id, status: status),
      query: [access_token: client.get_access_token()]
    )
  end
end
