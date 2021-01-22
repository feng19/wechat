defmodule WeChat.Menu do
  @moduledoc "自定义菜单"
  import Jason.Helpers
  import WeChat.Utils, only: [doc_link_prefix: 0]

  @typedoc "菜单id，可以通过自定义菜单查询接口获取"
  @type menu_id :: String.t()
  @typedoc "粉丝的OpenID / 粉丝的微信号"
  @type user_id :: String.t()

  @doc_link "#{doc_link_prefix()}/doc/offiaccount/Custom_Menus"

  @doc """
  创建接口 -
  [Official API Docs Link](#{@doc_link}/Creating_Custom-Defined_Menu.html){:target="_blank"}

  自定义菜单能够帮助公众号丰富界面，让用户更好更快地理解公众号的功能。

  请注意：

  - 自定义菜单最多包括3个一级菜单，每个一级菜单最多包含5个二级菜单。
  - 一级菜单最多4个汉字，二级菜单最多7个汉字，多出来的部分将会以“...”代替。
  - 创建自定义菜单后，菜单的刷新策略是，在用户进入公众号会话页或公众号 `profile` 页时，如果发现上一次拉取菜单的请求在5分钟以前，
  就会拉取一下菜单，如果菜单有更新，就会刷新客户端的菜单。测试时可以尝试取消关注公众账号后再次关注，则可以看到创建后的效果。

  自定义菜单接口可实现多种类型按钮，如下：

  1. `click`：点击推事件用户点击 `click` 类型按钮后，微信服务器会通过消息接口推送消息类型为 `event` 的结构给开发者（参考消息接口指南），
  并且带上按钮中开发者填写的key值，开发者可以通过自定义的key值与用户进行交互；
  2. `view`：跳转URL用户点击 `view` 类型按钮后，微信客户端将会打开开发者在按钮中填写的网页URL，可与网页授权获取用户基本信息接口结合，获得用户基本信息。
  3. `scancode_push`：扫码推事件用户点击按钮后，微信客户端将调起扫一扫工具，完成扫码操作后显示扫描结果（如果是URL，将进入URL），
  且会将扫码的结果传给开发者，开发者可以下发消息。
  4. `scancode_waitmsg`：扫码推事件且弹出“消息接收中”提示框用户点击按钮后，微信客户端将调起扫一扫工具，完成扫码操作后，将扫码的结果传给开发者，
  同时收起扫一扫工具，然后弹出“消息接收中”提示框，随后可能会收到开发者下发的消息。
  5. `pic_sysphoto`：弹出系统拍照发图用户点击按钮后，微信客户端将调起系统相机，完成拍照操作后，会将拍摄的相片发送给开发者，并推送事件给开发者，
  同时收起系统相机，随后可能会收到开发者下发的消息。
  6. `pic_photo_or_album`：弹出拍照或者相册发图用户点击按钮后，微信客户端将弹出选择器供用户选择“拍照”或者“从手机相册选择”。用户选择后即走其他两种流程。
  7. `pic_weixin`：弹出微信相册发图器用户点击按钮后，微信客户端将调起微信相册，完成选择操作后，将选择的相片发送给开发者的服务器，并推送事件给开发者，
  同时收起相册，随后可能会收到开发者下发的消息。
  8. `location_select`：弹出地理位置选择器用户点击按钮后，微信客户端将调起地理位置选择工具，完成选择操作后，将选择的地理位置发送给开发者的服务器，
  同时收起位置选择工具，随后可能会收到开发者下发的消息。
  9. `media_id`：下发消息（除文本消息）用户点击 `media_id` 类型按钮后，微信服务器会将开发者填写的永久素材id对应的素材下发给用户，
  永久素材类型可以是图片、音频、视频、图文消息。请注意：永久素材id必须是在“素材管理/新增永久素材”接口上传后获得的合法id。
  10. `view_limited`：跳转图文消息URL用户点击 `view_limited` 类型按钮后，微信客户端将打开开发者在按钮中填写的永久素材id对应的图文消息URL，
  永久素材类型只支持图文消息。请注意：永久素材id必须是在“素材管理/新增永久素材”接口上传后获得的合法id。

  请注意，`3` 到 `8` 的所有事件，仅支持微信 `iPhone5.4.1` 以上版本，和 `Android5.4` 以上版本的微信用户，旧版本微信用户点击后将没有回应，
  开发者也不能正常接收到事件推送。`9` 和 `10`，是专门给第三方平台旗下未微信认证（具体而言，是资质认证未通过）的订阅号准备的事件类型，
  它们是没有事件推送的，能力相对受限，其他类型的公众号不必使用。
  """
  @spec create_menu(WeChat.client(), body :: map) :: WeChat.response()
  def create_menu(client, body) do
    client.post("/cgi-bin/menu/create", body, query: [access_token: client.get_access_token()])
  end

  @doc """
  查询接口 -
  [Official API Docs Link](#{@doc_link}/Querying_Custom_Menus.html){:target="_blank"}

  本接口将会提供公众号当前使用的自定义菜单的配置，如果公众号是通过API调用设置的菜单，则返回菜单的开发配置，
  而如果公众号是在公众平台官网通过网站功能发布菜单，则本接口返回运营者设置的菜单配置。

  请注意：

  - 第三方平台开发者可以通过本接口，在旗下公众号将业务授权给你后，立即通过本接口检测公众号的自定义菜单配置，
  并通过接口再次给公众号设置好自动回复规则，以提升公众号运营者的业务体验。
  - 本接口与自定义菜单查询接口的不同之处在于，本接口无论公众号的接口是如何设置的，都能查询到接口，而自定义菜单查询接口则仅能查询到使用API设置的菜单配置。
  - 认证/未认证的服务号/订阅号，以及接口测试号，均拥有该接口权限。
  - 从第三方平台的公众号登录授权机制上来说，该接口从属于消息与菜单权限集。
  - 本接口中返回的图片/语音/视频为临时素材（临时素材每次获取都不同，3天内有效，通过素材管理-获取临时素材接口来获取这些素材），
  本接口返回的图文消息为永久素材素材（通过素材管理-获取永久素材接口来获取这些素材）。
  """
  @spec get_menu(WeChat.client()) :: WeChat.response()
  def get_menu(client) do
    client.get("/cgi-bin/menu/get_current_selfmenu_info",
      query: [access_token: client.get_access_token()]
    )
  end

  @doc """
  删除接口 -
  [Official API Docs Link](#{@doc_link}/Deleting_Custom-Defined_Menu.html){:target="_blank"}

  使用接口创建自定义菜单后，开发者还可使用接口删除当前使用的自定义菜单。另请注意，在个性化菜单时，调用此接口会删除默认菜单及全部个性化菜单。
  """
  @spec delete_menu(WeChat.client()) :: WeChat.response()
  def delete_menu(client) do
    client.get("/cgi-bin/menu/delete", query: [access_token: client.get_access_token()])
  end

  @doc """
  创建个性化菜单 -
  [Official API Docs Link](#{@doc_link}/Personalized_menu_interface.html#0){:target="_blank"}
  """
  @spec add_conditional_menu(WeChat.client(), body :: map) :: WeChat.response()
  def add_conditional_menu(client, body) do
    client.post("/cgi-bin/menu/addconditional", body,
      query: [access_token: client.get_access_token()]
    )
  end

  @doc """
  删除个性化菜单 -
  [Official API Docs Link](#{@doc_link}/Personalized_menu_interface.html#1){:target="_blank"}
  """
  @spec del_conditional_menu(WeChat.client(), menu_id) :: WeChat.response()
  def del_conditional_menu(client, menu_id) do
    client.post("/cgi-bin/menu/delconditional", json_map(menuid: menu_id),
      query: [access_token: client.get_access_token()]
    )
  end

  @doc """
  测试个性化菜单匹配结果 -
  [Official API Docs Link](#{@doc_link}/Personalized_menu_interface.html#2){:target="_blank"}
  """
  @spec try_match_menu(WeChat.client(), user_id) :: WeChat.response()
  def try_match_menu(client, user_id) do
    client.post("/cgi-bin/menu/trymatch", json_map(user_id: user_id),
      query: [access_token: client.get_access_token()]
    )
  end
end
