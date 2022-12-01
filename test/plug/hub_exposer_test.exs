defmodule WeChat.Plug.HubExposerTest do
  use ExUnit.Case, async: true
  use Plug.Test
  alias WeChat.Plug.HubExposer
  alias WeChat.HubExposerRouter
  alias WeChat.Work.Agent, as: WorkAgent

  test "init - empty clients" do
    msg = "please set clients when using WeChat.Plug.HubExposer"
    assert_raise ArgumentError, msg, fn -> HubExposer.init([]) end
    assert_raise ArgumentError, msg, fn -> HubExposer.init(clients: []) end
  end

  test "init - ok for official_account" do
    client = WeChat.Test.OfficialAccount
    store_id = client.appid()
    opts = %{store_id => :all}
    assert opts == HubExposer.init(clients: [client])
    assert opts == HubExposer.init(clients: [{client, :all}])

    opts = %{store_id => ["access_token"]}
    assert opts == HubExposer.init(clients: [{client, ["access_token"]}])
  end

  test "init - ok for work" do
    client = WeChat.Test.Work2
    store_id = WorkAgent.fetch_agent_cache_id!(client, 10000)
    opts = %{store_id => :all}
    assert opts == HubExposer.init(clients: [client])
    assert opts == HubExposer.init(clients: [{client, :all}])
    assert opts == HubExposer.init(clients: [{client, [{10000, :all}]}])
    opts = %{store_id => ["access_token"]}
    assert opts == HubExposer.init(clients: [{client, [{10000, ["access_token"]}]}])
  end

  @opts HubExposerRouter.init([])

  test "call - not_found" do
    conn =
      conn(:get, "/hub/expose/err_store_id/err_store_key")
      |> HubExposerRouter.call(@opts)

    body = Jason.encode!(%{error: 404, msg: "not found"})
    assert conn.status == 200
    assert conn.resp_body == body
  end

  test "call - in scope" do
    store_id = WeChat.Test.OfficialAccount.appid()
    store_key = :access_token
    store_map = %{"value" => "token", "expired_time" => 7200}
    WeChat.Storage.Cache.put_cache({:store_map, store_id}, store_key, store_map)

    conn =
      conn(:get, "/hub/expose/#{store_id}/#{store_key}")
      |> HubExposerRouter.call(@opts)

    body = Jason.encode!(%{error: 0, msg: "success", store_map: store_map})
    assert conn.status == 200
    assert conn.resp_body == body
  end

  test "call - not in scope" do
    store_id = WeChat.Test.OfficialAccount.appid()
    store_key = :err_access_token
    store_map = %{"value" => "token", "expired_time" => 7200}
    WeChat.Storage.Cache.put_cache({:store_map, store_id}, store_key, store_map)

    conn =
      conn(:get, "/hub/expose/#{store_id}/#{store_key}")
      |> HubExposerRouter.call(@opts)

    body = Jason.encode!(%{error: 404, msg: "not found"})
    assert conn.status == 200
    assert conn.resp_body == body
  end
end
