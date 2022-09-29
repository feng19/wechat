defmodule WeChat.MixProject do
  use Mix.Project
  alias WeChat.{Requester, Refresher, ServerMessage, Storage, MiniProgram, Work}

  @version "0.10.3"
  @source_url "https://github.com/feng19/wechat"

  def project do
    [
      app: :wechat,
      version: @version,
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
      {:saxy, "~> 1.2", optional: true},
      {:plug, "~> 1.11", optional: true},
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
        Work.LinkedCorp,
        Work.OA,
        Work.WeDrive
      ]
    ]
  end

  defp groups_for_modules do
    [
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
        "素材管理 APIs",
        [
          WeChat.Material.Article,
          WeChat.Material,
          WeChat.DraftBox,
          WeChat.Publish
        ]
      },
      {
        "消息管理 APIs",
        [
          # 消息管理 - 客服消息
          WeChat.CustomMessage,
          # 消息管理 - 客服帐号管理
          WeChat.CustomService,
          # 订阅信息
          WeChat.SubscribeMessage,
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
         WeChat.CardDistributing,
         # 微信卡券 - 会员卡
         WeChat.MemberCard
       ]},
      {"事件推送",
       [
         WeChat.Plug.EventHandler,
         WeChat.Plug.WorkEventHandler,
         ServerMessage.EventHelper,
         ServerMessage.Encryptor,
         ServerMessage.XmlMessage,
         ServerMessage.XmlParser
       ]},
      {"网页开发",
       [
         WeChat.WebPage,
         WeChat.Plug.OAuth2Checker,
         WeChat.Plug.HubSpringboard
       ]},
      {"Other APIs",
       [
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
       ]}
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
