defmodule WeChat.HubSpringboardRouter do
  use Plug.Router

  plug :match
  plug :dispatch

  get "/:env/:app/cb/*callback_path",
    to: WeChat.Plug.HubSpringboard,
    init_opts: [clients: [WeChat.Test.OfficialAccount]]

  get "/:env/:app/:agent/cb/*callback_path",
    to: WeChat.Plug.HubSpringboard,
    init_opts: [clients: [WeChat.Test.Work]]

  match _ do
    send_resp(conn, 404, "oops")
  end
end
