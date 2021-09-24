defmodule WeChat.HubExposerRouter do
  use Plug.Router

  plug :match
  plug :dispatch

  forward "/hub/expose/:store_id/:store_key",
    to: WeChat.Plug.HubExposer,
    init_opts: [clients: [WeChat.Test.OfficialAccount, WeChat.Test.Work]]

  match _ do
    send_resp(conn, 404, "oops")
  end
end
