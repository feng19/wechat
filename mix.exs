defmodule WeChat.MixProject do
  use Mix.Project
  alias WeChat.{ServerMessage, MiniProgram, Storage}

  def project do
    [
      app: :wechat,
      description: "WeChat SDK for Elixir",
      version: "0.1.0",
      elixir: "~> 1.10",
      start_permanent: Mix.env() == :prod,
      elixirc_paths: elixirc_paths(Mix.env()),
      deps: deps(),
      docs: docs(),
      package: package()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger, :eex],
      mod: {WeChat.Application, []}
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:tesla, "~> 1.4"},
      {:finch, "~> 0.5"},
      {:jason, "~> 1.2"},
      {:saxy, "~> 1.2"},
      {:plug, "~> 1.11", optional: true},
      {:ex_doc, "~> 0.22", only: [:docs, :dev], runtime: false}
    ]
  end

  defp docs do
    [
      main: "readme",
      formatter_opts: [gfm: true],
      extras: ["README.md"],
      groups_for_modules: [
        {"Basic",
         [
           WeChat,
           WeChat.Requester,
           WeChat.RefreshTimer,
           WeChat.RefreshHelper
         ]},
        {"Storage", [Storage.Adapter, Storage.File, Storage.Cache]},
        {"Structure", [WeChat.Material.Article]},
        {
          "用户管理 APIs",
          [
            # 用户管理
            WeChat.User,
            # 用户管理 - 标签管理
            WeChat.UserTag,
            # 用户管理 - 黑名单管理
            WeChat.UserBlacklist
          ]
        },
        {
          "消息管理 APIs",
          [
            # 消息管理 - 客服消息
            WeChat.CustomMessage,
            # 消息管理 - 客服帐号管理
            WeChat.CustomService,
            # 消息管理 - 模板消息
            WeChat.Template,
            # 消息管理 - 群发接口和原创效验
            WeChat.BatchSends
          ]
        },
        {"微信卡券 APIs",
         [
           # 微信卡券(WIP)
           WeChat.Card,
           # 微信卡券 - 管理卡券
           WeChat.CardManaging,
           # 微信卡券 - 投放卡券
           WeChat.CardDistributing
         ]},
        {"事件推送",
         [
           WeChat.Plug.EventHandler,
           ServerMessage.EventHandler,
           ServerMessage.Encryptor,
           ServerMessage.XmlMessage,
           ServerMessage.XmlParser
         ]},
        {"网页开发",
         [
           WeChat.WebPage,
           WeChat.Plug.WebPageOAuth2,
           WeChat.Plug.CheckOauth2
         ]},
        {"Other APIs",
         [
           # 自定义菜单
           WeChat.Menu,
           # 素材管理
           WeChat.Material,
           # 图文消息留言管理
           WeChat.Comment,
           # 账号管理
           WeChat.Account,
           # 第三方平台
           WeChat.Component
         ]},
        {"小程序 APIs", [MiniProgram.Auth]}
      ]
    ]
  end

  defp package do
    [
      files: ["lib", "mix.exs", "README.md", "LICENSE.md"],
      maintainers: ["feng19"],
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/feng19/wechat"}
    ]
  end
end
