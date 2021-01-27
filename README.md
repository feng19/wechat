# WeChat

**WeChat SDK for Elixir**

目前 `Elixir` 中支持最完善的微信SDK。

## Installation

You can use wechat in your projects by adding it to your `mix.exs` dependencies:

```elixir
def deps do
  [
    {:wechat, "~> 0.1.0", hex: :wechat_sdk}
  ]
end
```

[在线文档](http://hexdocs.pm/wechat_sdk/).

## Usage

### 定义 `Client` 模块

```elixir

# 公众号(`default`):

defmodule YourApp.WeChatAppCodeName do
  @moduledoc "CodeName"
  use WeChat,
    appid: "wx-appid",
    appsecret: "appsecret"
end

# or

# 第三方应用:

defmodule YourApp.WeChatAppCodeName do
  @moduledoc "CodeName"
  use WeChat,
    by_component?: true,
    appid: "wx-appid",
    component_appid: "wx-third-appid", # 第三方 appid
end
```

### 调用接口

同时支持两种方式调用

```elixir
YourApp.WeChatAppCodeName.Material.batch_get_material(:image, 2)

# or

WeChat.Material.batch_get_material(YourApp.WeChatAppCodeName, :image, 2)
```

更多详情请见：[WeChat模块](https://hexdocs.pm/wechat_sdk/WeChat.html)

### 支持接口列表

[微信官方文档](https://developers.weixin.qq.com/doc/offiaccount/Getting_Started/Overview.html)

* 消息管理
* 素材管理
* 图文消息留言管理
* 自定义菜单
* 用户管理
* 账号管理
* 微信卡券(WIP)
* 第三方平台
* 小程序(WIP)

更多接口正在开发中……

## Contributing

如果有接口未覆盖到，欢迎提交 `PR`，感谢。

## License

wechat source code is released under Apache 2 License. Check the [LICENSE](./LICENSE) file for more information.