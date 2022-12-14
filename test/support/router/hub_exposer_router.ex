defmodule WeChat.HubExposerRouter do
  use Plug.Router
  alias WeChat.Test

  plug :match
  plug :dispatch

  get "/hub/expose/:store_id/:store_key",
    to: WeChat.Plug.HubExposer,
    init_opts: [clients: [Test.OfficialAccount, Test.Work]]

  get "/runtime/hub/expose/:store_id/:store_key",
    to: WeChat.Plug.HubExposer,
    init_opts: [clients: [Test.Work3], runtime: true, persistent_id: :hub_exposer]

  match _ do
    send_resp(conn, 404, "oops")
  end
end
