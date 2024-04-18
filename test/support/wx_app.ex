defmodule WeChat.Test.OfficialAccount do
  @moduledoc "公众号"
  use WeChat,
    appid: "wx2c2769f8efd9abc2",
    appsecret: "appsecret",
    encoding_aes_key: "abcdefghijklmnopqrstuvwxyz0123456789ABCDEFG",
    token: "spamtest",
    gen_sub_module?: false
end

defmodule WeChat.Test.DynamicSecretA do
  @moduledoc "公众号"
  use WeChat,
    appid: "wx2c2769f8efd9abc2",
    appsecret: :runtime_env,
    encoding_aes_key: :compile_env,
    token: {:compile_env, :wechat},
    gen_sub_module?: false
end

defmodule WeChat.Test.Component do
  @moduledoc "公众号 - by第三方"
  use WeChat,
    appid: "wx2c2769f8efd9abc2",
    by_component?: true,
    component_appid: "wx3c2769f8efd9abc3",
    component_appsecret: "component_appsecret"
end

defmodule WeChat.Test.DynamicSecretB do
  @moduledoc "公众号 - by第三方"
  use WeChat,
    appid: "wx2c2769f8efd9abc2",
    by_component?: true,
    component_appid: "wx3c2769f8efd9abc3",
    component_appsecret: :runtime_env
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
    component_appid: "wx3c2769f8efd9abc3",
    component_appsecret: "component_appsecret"
end

defmodule WeChat.Test.Work do
  @moduledoc "企业微信 - 多个应用"
  use WeChat.Work,
    corp_id: "corp_id",
    agents: [
      contacts_agent(secret: "your_contacts_secret"),
      customer_agent(secret: "your_customer_secret"),
      kf_agent(secret: "your_customer_secret"),
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

defmodule WeChat.Test.Work3 do
  @moduledoc "企业微信"
  use WeChat.Work,
    corp_id: "corp_id",
    agents: :runtime_env
end

defmodule WeChat.Test.Pay3 do
  use WeChat.Pay,
    mch_id: "1555555888",
    api_secret_key: :runtime_env,
    api_secret_v2_key: :runtime_env,
    client_serial_no: "client_serial_no",
    client_key: {:file, "test/support/cert/apiclient_key.pem"}
end
