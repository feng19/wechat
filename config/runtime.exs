import Config

if Mix.env() == :test do
  config :wechat, WeChat.Test.Work3,
    agents: [WeChat.Work.Agent.agent(10000, name: :agent_name, secret: "your_secret")]
end
