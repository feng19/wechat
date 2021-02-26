defmodule WxOfficialAccount do
  @moduledoc "公众号"
  use WeChat, appid: "wx2c2769f8efd9abc2"
end

defmodule WxComponent do
  @moduledoc "公众号 - by第三方"
  use WeChat,
    appid: "wx2c2769f8efd9abc2",
    by_component?: true,
    component_appid: "wx3c2769f8efd9abc3"
end

defmodule WxMini do
  @moduledoc "小程序"
  use WeChat,
    appid: "wx2c2769f8efd9abc2",
    app_type: :mini_program
end

defmodule WxMiniComponent do
  @moduledoc "小程序 - by第三方"
  use WeChat,
    appid: "wx2c2769f8efd9abc2",
    app_type: :mini_program,
    by_component?: true,
    component_appid: "wx3c2769f8efd9abc3"
end

defmodule WxApp do
  @moduledoc "公众号"
  use WeChat,
    appid: "wx2c2769f8efd9abc2",
    appsecret: "appsecret",
    encoding_aes_key: "abcdefghijklmnopqrstuvwxyz0123456789ABCDEFG",
    token: "spamtest",
    gen_sub_module?: false
end

defmodule WxWork do
  use WeChat.Work,
    corp_id: "corp_id",
    agents: [
      contacts_agent(secret: "your_contacts_secret"),
      %WeChat.Work.Agent{name: :agent_name, id: 10000, secret: "your_secret"}
    ]
end
