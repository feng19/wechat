import Config

config :wechat, WeChat.Test.DynamicSecretA,
  appsecret: "dynamic_app_secret",
  aes_key: "dynamic_aes_key",
  encoding_aes_key: "dynamic_encoding_aes_key",
  token: "dynamic_token"

config :wechat, WeChat.Test.DynamicSecretB, component_appsecret: "component_app_secret"

config :wechat, WeChat.Test.Pay3,
  api_secret_key: "dynamic_api_secret_key",
  api_secret_v2_key: "dynamic_api_secret_v2_key",
  v2_ssl: [
    certfile: {:file, "test/support/cert/apiclient_cert.pem"},
    keyfile: {:file, "test/support/cert/apiclient_key.pem"}
  ]
