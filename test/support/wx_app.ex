defmodule WeChat.Test.OfficialAccount do
  @moduledoc "公众号"
  use WeChat,
    appid: "wx2c2769f8efd9abc2",
    appsecret: "appsecret",
    encoding_aes_key: "abcdefghijklmnopqrstuvwxyz0123456789ABCDEFG",
    token: "spamtest",
    gen_sub_module?: false
end

defmodule WeChat.Test.Component do
  @moduledoc "公众号 - by第三方"
  use WeChat,
    appid: "wx2c2769f8efd9abc2",
    by_component?: true,
    component_appid: "wx3c2769f8efd9abc3"
end

defmodule WeChat.Test.Mini do
  @moduledoc "小程序"
  use WeChat,
    appid: "wx2c2769f8efd9abc2",
    app_type: :mini_program
end

defmodule WeChat.Test.MiniComponent do
  @moduledoc "小程序 - by第三方"
  use WeChat,
    appid: "wx2c2769f8efd9abc2",
    app_type: :mini_program,
    by_component?: true,
    component_appid: "wx3c2769f8efd9abc3"
end

defmodule WeChat.Test.Work do
  @moduledoc "企业微信 - 多个应用"
  use WeChat.Work,
    corp_id: "corp_id",
    agents: [
      contacts_agent(secret: "your_contacts_secret"),
      customer_agent(secret: "your_customer_secret"),
      kf_agent(secret: "your_customer_secret"),
      we_drive_agent(secret: "your_customer_secret"),
      agent(10000, name: :agent_name, secret: "your_secret")
    ]
end

defmodule WeChat.Test.Work2 do
  @moduledoc "企业微信"
  use WeChat.Work,
    corp_id: "corp_id",
    agents: [
      agent(10000, name: :agent_name, secret: "your_secret")
    ]
end
