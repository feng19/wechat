# WeChat

**WeChat SDK for Elixir(WIP)**

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `wechat_sdk` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:wechat, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/wechat_sdk](https://hexdocs.pm/wechat_sdk).

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
### 支持接口列表

[微信官方文档](https://developers.weixin.qq.com/doc/offiaccount/Getting_Started/Overview.html)

* 消息管理
* 素材管理
* 图文消息留言管理
* 用户管理
* 账号管理
* 微信卡券(WIP)
* 第三方平台
* 小程序(WIP)

更多接口目前还在开发中……

如果有接口未覆盖到，欢迎提交`PR`
