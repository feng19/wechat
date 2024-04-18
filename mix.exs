defmodule WeChat.MixProject do
  use Mix.Project
  alias WeChat.{Requester, Refresher, ServerMessage, Storage, MiniProgram, Work, Pay}

  @version "0.14.3"
  @source_url "https://github.com/feng19/wechat"

  def project do
    [
      app: :wechat,
      version: @version,
      elixir: "~> 1.13",
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
      {:finch, "~> 0.9"},
      {:jason, "~> 1.2"},
      {:saxy, "~> 1.2", optional: true},
      {:plug, "~> 1.11", optional: true},
      {:x509, "~> 0.8", optional: true},
      {:ex_doc, ">= 0.0.0", only: [:docs, :dev], runtime: false}
    ]
  end

  defp docs do
    [
      extras: [
        "LICENSE.md": [title: "License"],
        "README.md": [title: "Overview"]
      ],
      main: "readme",
      source_url: @source_url,
      source_ref: "master",
      formatters: ["html"],
      formatter_opts: [gfm: true],
      groups_for_modules: groups_for_modules(),
      groups_for_functions: [Action: &(&1[:doc_group] == :action)],
      nest_modules_by_prefix: [
        Requester,
        Refresher,
        WeChat.Plug,
        ServerMessage,
        Storage,
        MiniProgram,
        MiniProgram.Live,
        Work,
        Work.App,
        Work.Contacts,
        Work.Customer,
        Work.KF,
        Work.OA,
        Work.WeDrive,
        Pay,
        Pay.Middleware
      ]
    ]
  end

  defp groups_for_modules do
    [
      {"用户管理 APIs", [WeChat.User, WeChat.UserTag, WeChat.UserBlacklist]},
      {"素材管理 APIs", [WeChat.Material.Article, WeChat.Material, WeChat.DraftBox, WeChat.Publish]},
      {"消息管理 APIs",
       [
         WeChat.CustomMessage,
         WeChat.CustomService,
         WeChat.SubscribeMessage,
         WeChat.Template,
         WeChat.BatchSends
       ]},
      {"微信卡券 APIs",
       [WeChat.Card, WeChat.CardManaging, WeChat.CardDistributing, WeChat.MemberCard]},
      {"事件推送",
       [
         WeChat.Plug.EventHandler,
         WeChat.Plug.WorkEventHandler,
         ServerMessage.EventHelper,
         ServerMessage.Encryptor,
         ServerMessage.ReplyMessage,
         ServerMessage.XmlParser
       ]},
      {"网页开发", [WeChat.WebPage, WeChat.Plug.OAuth2Checker, WeChat.Plug.HubSpringboard]},
      {"Hub", [WeChat.HubClient, WeChat.HubServer, WeChat.Plug.HubExposer]},
      {"Other APIs",
       [
         # 微信门店
         WeChat.POI,
         # 自定义菜单
         WeChat.Menu,
         # 图文消息留言管理
         WeChat.Comment,
         # 账号管理
         WeChat.Account,
         # 第三方平台
         WeChat.Component
       ]},
      {"小程序 APIs",
       [
         MiniProgram.Auth,
         MiniProgram.Code,
         MiniProgram.UrlScheme,
         MiniProgram.NearbyPOI,
         MiniProgram.Store,
         MiniProgram.Search,
         MiniProgram.OCR,
         MiniProgram.Security,
         MiniProgram.Live.Room,
         MiniProgram.Live.Goods,
         MiniProgram.Live.Role,
         MiniProgram.Live.Subscribe
       ]},
      {"企业微信 APIs",
       [
         Work,
         Work.Agent,
         Work.App,
         Work.App.Chat,
         Work.App.Menu,
         Work.App.Workbench,
         Work.ChatRobot,
         Work.Living,
         Work.Material,
         Work.Meeting,
         Work.Message,
         Work.MiniProgram,
         Work.Contacts.Department,
         Work.Contacts.User,
         Work.Contacts.Tag,
         Work.Customer,
         Work.Customer.ContactWay,
         Work.Customer.GroupChat,
         Work.Customer.GroupMsg,
         Work.Customer.Moment,
         Work.Customer.Strategy,
         Work.Customer.Tag,
         Work.Customer.Transfer,
         Work.Customer.Welcome,
         Work.KF.Account,
         Work.KF.Customer,
         Work.KF.Message,
         Work.LinkedCorp.Message,
         Work.OA.Approval,
         Work.OA.Calendar,
         Work.OA.Checkin,
         Work.OA.Journal,
         Work.OA.MeetingRoom,
         Work.OA.Pstncc,
         Work.OA.Schedule,
         Work.OA.Vacation,
         Work.WeDrive.FileACL,
         Work.WeDrive.FileManagement,
         Work.WeDrive.SpaceACL,
         Work.WeDrive.SpaceManagement
       ]},
      {"微信支付",
       [
         Pay,
         Pay.Crypto,
         Pay.Certificates,
         Pay.Middleware.Authorization,
         Pay.Middleware.VerifySignature,
         Pay.Middleware.XMLBuilder,
         Pay.Middleware.XMLParser,
         Pay.EventHandler,
         Pay.Transactions,
         Pay.Refund,
         Pay.CombineTransactions,
         Pay.Bill,
         Pay.Sandbox
       ]},
      {"Access Token",
       [Refresher.Default, Refresher.DefaultSettings, Refresher.Pay, WeChat.TokenChecker]},
      {"请求客户端", [Requester.OfficialAccount, Requester.Work, Requester.Pay]},
      {"存储器",
       [Storage.Adapter, Storage.Cache, Storage.File, Storage.HttpForHubClient, Storage.PayFile]}
    ]
  end

  defp package do
    [
      name: "wechat_sdk",
      description: "WeChat SDK for Elixir, 支持: 公众号/小程序/第三方应用/企业微信/微信支付",
      files: ["lib", "mix.exs", "README.md", "LICENSE.md"],
      maintainers: ["feng19"],
      licenses: ["Apache-2.0"],
      links: %{"GitHub" => @source_url}
    ]
  end
end
