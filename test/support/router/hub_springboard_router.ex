defmodule WeChat.HubSpringboardRouter do
  use Plug.Router
  alias WeChat.Test

  plug :match
  plug :dispatch

  get "/normal/:env/cb/*callback_path",
    to: WeChat.Plug.HubSpringboard,
    init_opts: [client: Test.OfficialAccount]

  get "/work/runtime/:env/:agent/cb/*callback_path",
    to: WeChat.Plug.HubSpringboard,
    init_opts: [client: Test.Work3, agents: :runtime, persistent_id: :hub_springboard]

  get "/work/:env/cb/*callback_path",
    to: WeChat.Plug.HubSpringboard,
    init_opts: [client: Test.Work, agent: :agent_name]

  get "/work/:env/:agent/cb/*callback_path",
    to: WeChat.Plug.HubSpringboard,
    init_opts: [client: Test.Work]

  get "/:env/:app/cb/*callback_path",
    to: WeChat.Plug.HubSpringboard,
    init_opts: [clients: [Test.OfficialAccount]]

  get "/:env/:app/:agent/cb/*callback_path",
    to: WeChat.Plug.HubSpringboard,
    init_opts: [clients: [Test.Work]]

  match _ do
    send_resp(conn, 404, "oops")
  end
end
