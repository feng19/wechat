defmodule WeChat.Plug.HubSpringboardTest do
  use ExUnit.Case, async: true
  use Plug.Test
  alias WeChat.Plug.HubSpringboard
  alias WeChat.HubSpringboardRouter

  test "init - empty clients" do
    msg = "please set clients when using WeChat.Plug.HubSpringboard"
    assert_raise ArgumentError, msg, fn -> HubSpringboard.init([]) end
    assert_raise ArgumentError, msg, fn -> HubSpringboard.init(clients: []) end
  end

  test "init - empty agents" do
    client = WeChat.Test.Work2
    msg = "please set agents for client: #{inspect(client)}"
    assert_raise ArgumentError, msg, fn -> HubSpringboard.init(clients: [{client, []}]) end

    assert_raise ArgumentError, msg, fn ->
      HubSpringboard.init(clients: [{client, [:error_agent]}])
    end
  end

  test "init - ok for official_account" do
    client = WeChat.Test.OfficialAccount
    clients = %{client.appid() => client, client.code_name() => client}
    assert %{clients: ^clients} = HubSpringboard.init(clients: [client])
  end

  test "init - ok for work" do
    client = WeChat.Test.Work2
    agents = [10000, :agent_name, "10000", "agent_name"] |> Enum.sort()
    clients = %{client.appid() => {client, agents}, client.code_name() => {client, agents}}
    assert %{clients: ^clients} = HubSpringboard.init(clients: [client])
    assert %{clients: ^clients} = HubSpringboard.init(clients: [{client, 10000}])
    assert %{clients: ^clients} = HubSpringboard.init(clients: [{client, [10000]}])
    assert %{clients: ^clients} = HubSpringboard.init(clients: [{client, :agent_name}])

    assert %{client: ^client, agent: :agent_name} =
             HubSpringboard.init(client: client, agent: :agent_name)
  end

  @opts HubSpringboardRouter.init([])

  test "call - not_found" do
    client = WeChat.Test.OfficialAccount
    appid = client.appid()

    # not code
    conn1 = conn(:get, "/dev/#{appid}/cb/test/a/b/c")
    # not set client
    conn2 = conn(:get, "/dev/err_app/cb/test/a/b/c", %{code: "test"})
    # not found env url
    conn3 = conn(:get, "/err_env/#{appid}/cb/test/a/b/c", %{code: "test"})

    for conn <- [conn1, conn2, conn3] do
      conn = HubSpringboardRouter.call(conn, @opts)
      assert conn.status == 404
      assert conn.resp_body == "not_found"
    end
  end

  test "call - for official_account" do
    client = WeChat.Test.OfficialAccount
    appid = client.appid()
    env_url = "http://127.0.0.1:4000"
    env = "dev"
    WeChat.HubServer.set_oauth2_env_url(client, env, env_url)
    redirect_url = "#{env_url}/a/b/c?code=test"

    # get "/:env/:app/cb/*callback_path"
    conn =
      conn(:get, "/#{env}/#{appid}/cb/a/b/c", %{code: "test"})
      |> HubSpringboardRouter.call(@opts)

    assert conn.status == 302
    assert get_resp_header(conn, "location") == [redirect_url]

    # get "/normal/:env/cb/*callback_path"
    conn =
      conn(:get, "/normal/#{env}/cb/a/b/c", %{code: "test"})
      |> HubSpringboardRouter.call(@opts)

    assert conn.status == 302
    assert get_resp_header(conn, "location") == [redirect_url]
  end

  test "call - for work" do
    client = WeChat.Test.Work
    appid = client.appid()
    agent_id = 10000
    env_url = "http://127.0.0.1:4000"
    env = "dev"
    WeChat.HubServer.set_oauth2_env_url(client, agent_id, env, env_url)
    agent = WeChat.Work.Agent.fetch_agent!(client, agent_id)
    WeChat.Storage.Cache.put_cache(appid, to_string(agent_id), {client, agent})
    redirect_url = "#{env_url}/a/b/c?code=test"

    # get "/:env/:app/:agent/cb/*callback_path"
    conn =
      conn(:get, "/#{env}/#{appid}/#{agent_id}/cb/a/b/c", %{code: "test"})
      |> HubSpringboardRouter.call(@opts)

    assert conn.status == 302
    assert get_resp_header(conn, "location") == [redirect_url]

    # get "/work/:env/cb/*callback_path"
    conn =
      conn(:get, "/work/#{env}/cb/a/b/c", %{code: "test"})
      |> HubSpringboardRouter.call(@opts)

    assert conn.status == 302
    assert get_resp_header(conn, "location") == [redirect_url]

    # get "/work/:env/:agent/cb/*callback_path"
    conn =
      conn(:get, "/work/#{env}/#{agent_id}/cb/a/b/c", %{code: "test"})
      |> HubSpringboardRouter.call(@opts)

    assert conn.status == 302
    assert get_resp_header(conn, "location") == [redirect_url]

    client = WeChat.Test.Work3
    appid = client.appid()
    WeChat.HubServer.set_oauth2_env_url(client, agent_id, env, env_url)
    agent = WeChat.Work.Agent.fetch_agent!(client, agent_id)
    WeChat.Storage.Cache.put_cache(appid, to_string(agent_id), {client, agent})

    # get "/work/runtime/:env/:agent/cb/*callback_path"
    conn =
      conn(:get, "/work/runtime/#{env}/#{agent_id}/cb/a/b/c", %{code: "test"})
      |> HubSpringboardRouter.call(@opts)

    assert conn.status == 302
    assert get_resp_header(conn, "location") == [redirect_url]
  end
end
