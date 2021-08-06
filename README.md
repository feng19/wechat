# WeChat

**WeChat SDK for Elixir**

[![Module Version](https://img.shields.io/hexpm/v/wechat_sdk.svg)](https://hex.pm/packages/wechat_sdk)
[![Hex Docs](https://img.shields.io/badge/hex-docs-lightgreen.svg)](https://hexdocs.pm/wechat_sdk/)
[![Total Download](https://img.shields.io/hexpm/dt/wechat_sdk.svg)](https://hex.pm/packages/wechat_sdk)
[![License](https://img.shields.io/hexpm/l/wechat.svg)](https://github.com/feng19/wechat/blob/master/LICENSE)
[![Last Updated](https://img.shields.io/github/last-commit/feng19/wechat.svg)](https://github.com/feng19/wechat/commits/master)

- 目前 `Elixir` 中支持最完善的微信SDK
- 已支持: 公众号/小程序/第三方应用/企业微信/微信支付
- WIP: 企业微信服务商

[在线文档](http://hexdocs.pm/wechat_sdk/)

## Installation

You can use wechat in your projects by adding it to your `mix.exs` dependencies:

```elixir
def deps do
  [
    {:wechat, "~> 0.7", hex: :wechat_sdk}
  ]
end
```

## Usage

### 定义 `Client` 模块

#### 公众号(默认)

  ```elixir
  defmodule YourApp.WeChatAppCodeName do
    @moduledoc "CodeName"
    use WeChat,
      appid: "wx-appid",
      appsecret: "appsecret"
  end
  ```

#### 小程序

  ```elixir
  defmodule YourApp.WeChatAppCodeName do
    @moduledoc "CodeName"
    use WeChat,
      app_type: :mini_program,
      appid: "wx-appid",
      appsecret: "appsecret"
  end
  ```

#### 第三方应用

  ```elixir
  defmodule YourApp.WeChatAppCodeName do
    @moduledoc "CodeName"
    use WeChat,
      by_component?: true,
      app_type: :official_account | :mini_program, # 默认为 :official_account
      appid: "wx-appid",
      component_appid: "wx-third-appid", # 第三方 appid
  end
  ```

#### 企业微信

  ```elixir
  defmodule YourApp.WeChatAppCodeName do
    @moduledoc "CodeName"
    use WeChat.Work,
      corp_id: "corp_id",
      agents: [%Work.Agent{name: :agent_name, id: 10000, secret: "your_secret"}, ...]
  end
  ```

### 调用接口

所有类型的 `client`，都同时支持两种方式调用：

```elixir
YourApp.WeChatAppCodeName.Material.batch_get_material(:image, 2)

# or

WeChat.Material.batch_get_material(YourApp.WeChatAppCodeName, :image, 2)
```

更多详情请见：[WeChat模块](https://hexdocs.pm/wechat_sdk/WeChat.html)

## 快速测试

微信提供申请测试号，用于快速测试

- [申请公众号测试号](https://developers.weixin.qq.com/doc/offiaccount/Basic_Information/Requesting_an_API_Test_Account.html)
- [申请小程序测试号](https://developers.weixin.qq.com/miniprogram/dev/devtools/sandbox.html)

## Contributing

如果有接口未覆盖到，欢迎提交 `PR`，感谢。

## Copyright and License

Copyright (c) 2021 feng19

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at [http://www.apache.org/licenses/LICENSE-2.0](http://www.apache.org/licenses/LICENSE-2.0)

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
