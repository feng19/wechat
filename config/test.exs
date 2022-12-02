import Config

config :wechat, WeChat.Test.DynamicSecretA,
  appsecret: "dynamic_app_secret",
  aes_key: "dynamic_aes_key",
  encoding_aes_key: "dynamic_encoding_aes_key",
  token: "dynamic_token"

config :wechat, WeChat.Test.DynamicSecretB, component_appsecret: "component_app_secret"
