# WeChat

[![Module Version](https://img.shields.io/hexpm/v/wechat_sdk.svg)](https://hex.pm/packages/wechat_sdk)
[![Hex Docs](https://img.shields.io/badge/hex-docs-lightgreen.svg)](https://hexdocs.pm/wechat_sdk/)
[![Total Download](https://img.shields.io/hexpm/dt/wechat_sdk.svg)](https://hex.pm/packages/wechat_sdk)
[![License](https://img.shields.io/hexpm/l/wechat.svg)](https://github.com/feng19/wechat/blob/master/LICENSE)
[![Last Updated](https://img.shields.io/github/last-commit/feng19/wechat.svg)](https://github.com/feng19/wechat/commits/master)

**WeChat SDK for Elixir**

- 目前 `Elixir` 中支持最完善的微信SDK
- 已支持: 
  - [公众号](https://developers.weixin.qq.com/doc/offiaccount/Getting_Started/Overview.html)
  - [小程序](https://developers.weixin.qq.com/miniprogram/dev/framework/)
  - [第三方应用](https://developers.weixin.qq.com/doc/oplatform/Third-party_Platforms/2.0/getting_started/how_to_read.html)
  - [企业微信](https://developer.work.weixin.qq.com/document/path/90556)
  - [微信支付](https://pay.weixin.qq.com/wiki/doc/apiv3/index.shtml)
- WIP: 企业微信服务商

### Links

- [开发前必读](https://developers.weixin.qq.com/doc/offiaccount/Getting_Started/Getting_Started_Guide.html)
- [在线文档](https://hex.pm/packages/wechat_sdk)
- [WeChat SDK 使用指南](https://feng19.com/2022/07/08/wechat_for_elixir_usage/)
- [示例项目](https://github.com/feng19/wechat_demo)

## Installation

You can use `wechat` in your projects by adding it to your `mix.exs` dependencies:

```elixir
def deps do
  [
    {:wechat, "~> 0.10", hex: :wechat_sdk}
  ]
end
```

## Usage

### 定义公众号 `Client` 模块

```elixir
defmodule YourApp.WeChatAppCodeName do
  @moduledoc "CodeName"
  use WeChat,
    appid: "wx-appid",
    appsecret: "appsecret"
end
```

其他类型定义请看 [WeChat](https://hexdocs.pm/wechat_sdk/WeChat.html#module-定义-client-模块)

详细参数说明请看 [options](https://hexdocs.pm/wechat_sdk/WeChat.html#t:options/0)

### 自动刷新 `AccessToken`

在调用接口之前，必须先获取 [`AccessToken`](https://developers.weixin.qq.com/doc/offiaccount/Basic_Information/Get_access_token.html) 才能 调用接口，
[官方说明](https://developers.weixin.qq.com/doc/offiaccount/Getting_Started/Getting_Started_Guide.html#_1-5-%E9%87%8D%E8%A6%81%E4%BA%8B%E6%83%85%E6%8F%90%E5%89%8D%E4%BA%A4%E4%BB%A3)

通过下面的方式激活 `AccessToken` 自动刷新器:

在 `config.exs` 中设置:

```elixir
config :wechat, :refresh_settings, [YourApp.WeChatAppCodeName, ...]
```

动态添加:

```elixir
WeChat.add_to_refresher(YourApp.WeChatAppCodeName)
```

### 调用接口

定义的 `client`，支持以下两种调用形式:

- 调用 `client` 方法:

  `YourApp.WeChatAppCodeName.Material.batch_get_material(:image, 2)`

- 原生调用方法

  `WeChat.Material.batch_get_material(YourApp.WeChatAppCodeName, :image, 2)`

更多详情请见：[WeChat模块](https://hexdocs.pm/wechat_sdk/WeChat.html)

## 网页授权

[官方文档](https://developers.weixin.qq.com/doc/offiaccount/OA_Web_Apps/Wechat_webpage_authorization.html)

把下面的代码放入到 `router`:

```elixir
pipeline :oauth2_checker do
  plug WeChat.Plug.OAuth2Checker, clients: [YourApp.WeChatAppCodeName, ...]
end

scope "/wx/:app" do
  pipe_through :oauth2_checker
  get "/path", YourController, :your_action
end
```

访问 `/wx/:app/path` 会自动完成网页授权

其中 `:app` 可以是 `code_name` 或者 `appid`

## JS-SDK setup

[设置指南](https://developers.weixin.qq.com/doc/offiaccount/OA_Web_Apps/JS-SDK.html#4)

如果网页内用到了 JS-SDK，如：

```javescript
wx.config({
  debug: true, // 开启调试模式,调用的所有 api 的返回值会在客户端 alert 出来，若要查看传入的参数，可以在 pc 端打开，参数信息会通过 log 打出，仅在 pc 端时才会打印。
  appId: '', // 必填，公众号的唯一标识
  timestamp: , // 必填，生成签名的时间戳
  nonceStr: '', // 必填，生成签名的随机串
  signature: '',// 必填，签名
  jsApiList: [] // 必填，需要使用的 JS 接口列表
});
```

Setup 参数有 5 个必填项，其中，`jsApiList` 根据业务需要填写即可，
其余 4 个参数可以通过接口 [WeChat.WebPage.js_sdk_config/2](https://hexdocs.pm/wechat_sdk/WeChat.WebPage.html#js_sdk_config/2) 生成

## 微信推送消息

[接入指南](https://developers.weixin.qq.com/doc/offiaccount/Basic_Information/Access_Overview.html)

- 填写服务器配置, 填入 `https://host/wx/event`
- 定义 `client` 时必须设置: `encoding_aes_key` & `token`

```elixir
forward "/wx/event", WeChat.Plug.EventHandler,
  client: YourApp.WeChatAppCodeName,
  event_handler: &HandleModule.handle_event/3
```

`event_handler` 的值为 3 参数的函数，详细请看: [函数定义](https://hexdocs.pm/wechat_sdk/WeChat.Plug.EventHandler.html#t:event_handler/0)

## 快速测试

微信提供申请测试号，用于快速测试

- [申请公众号测试号](https://developers.weixin.qq.com/doc/offiaccount/Basic_Information/Requesting_an_API_Test_Account.html)
- [申请小程序测试号](https://developers.weixin.qq.com/miniprogram/dev/devtools/sandbox.html)

## Contributing

如果有接口未覆盖到，欢迎提交 `PR`，感谢。

## Copyright and License

Copyright (c) 2022 feng19

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at [http://www.apache.org/licenses/LICENSE-2.0](http://www.apache.org/licenses/LICENSE-2.0)

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
