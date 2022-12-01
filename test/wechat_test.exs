defmodule WeChatTest do
  use ExUnit.Case, async: true
  alias WeChat.Work.Agent, as: WorkAgent
  alias WeChat.Test.{OfficialAccount, Work, Work2, Work3, DynamicSecretA, DynamicSecretB}
  doctest WeChat

  test "Auto generate functions(OfficialAccount)" do
    assert OfficialAccount.app_type() == :official_account
    assert OfficialAccount.by_component?() == false
    assert OfficialAccount.server_role() == :client
    assert OfficialAccount.code_name() == "officialaccount"
    assert OfficialAccount.storage() == WeChat.Storage.File
    assert OfficialAccount.appid() == "wx2c2769f8efd9abc2"
    assert OfficialAccount.appsecret() == "appsecret"
    assert OfficialAccount.encoding_aes_key() == "abcdefghijklmnopqrstuvwxyz0123456789ABCDEFG"

    aes_key =
      WeChat.ServerMessage.Encryptor.aes_key("abcdefghijklmnopqrstuvwxyz0123456789ABCDEFG")

    assert OfficialAccount.aes_key() == aes_key
    assert OfficialAccount.token() == "spamtest"
    assert true = Enum.all?(1..3, &function_exported?(OfficialAccount, :get, &1))
    assert true = Enum.all?(2..4, &function_exported?(OfficialAccount, :post, &1))
  end

  test "Auto generate functions(Work) - include Contacts" do
    assert Work.code_name() == "work"
    assert Work.app_type() == :work
    assert Work.by_component?() == false
    assert Work.server_role() == :client
    assert Work.storage() == WeChat.Storage.File
    assert Work.appid() == "corp_id"
    assert is_list(Work.agents())
    assert is_list(Work2.agents())
    assert WorkAgent.fetch_agent_cache_id!(Work, 10000) == "corp_id_10000"
    assert WorkAgent.fetch_agent_cache_id!(Work, :agent_name) == "corp_id_10000"

    assert true = Enum.all?(1..3, &function_exported?(Work, :get, &1))
    assert true = Enum.all?(2..4, &function_exported?(Work, :post, &1))
  end

  test "build official_account client" do
    opts = [
      appid: "wx2c2769f8efd9abc2",
      appsecret: "appsecret",
      encoding_aes_key: "abcdefghijklmnopqrstuvwxyz0123456789ABCDEFG",
      token: "spamtest"
    ]

    assert {:ok, WxApp3} = WeChat.build_client(WxApp3, opts)
    assert apply(WxApp3, :appid, []) == "wx2c2769f8efd9abc2"
    assert function_exported?(WxApp3.WebPage, :code2access_token, 1)
    assert false == function_exported?(WxApp3.MiniProgram.Auth, :code2session, 1)
  end

  test "build component client" do
    opts = [
      appid: "wx2c2769f8efd9abc2",
      by_component?: true,
      component_appid: "wx3c2769f8efd9abc3",
      appsecret: "appsecret",
      encoding_aes_key: "abcdefghijklmnopqrstuvwxyz0123456789ABCDEFG",
      token: "spamtest"
    ]

    assert {:ok, WxApp4} = WeChat.build_client(WxApp4, opts)
    assert apply(WxApp4, :appid, []) == "wx2c2769f8efd9abc2"
    assert function_exported?(WxApp4.Component, :get_authorizer_info, 0)
    assert function_exported?(WxApp4.WebPage, :code2access_token, 1)
    assert false == function_exported?(WxApp4.MiniProgram.Auth, :code2session, 1)
  end

  test "build mini_program client" do
    opts = [
      app_type: :mini_program,
      appid: "wx2c2769f8efd9abc2",
      appsecret: "appsecret",
      encoding_aes_key: "abcdefghijklmnopqrstuvwxyz0123456789ABCDEFG",
      token: "spamtest"
    ]

    assert {:ok, WxApp5} = WeChat.build_client(WxApp5, opts)
    assert apply(WxApp5, :appid, []) == "wx2c2769f8efd9abc2"
    assert false == function_exported?(WxApp5.WebPage, :code2access_token, 1)
    assert function_exported?(WxApp5.MiniProgram.Auth, :code2session, 1)
  end

  test "dynamic_secret" do
    assert "dynamic_app_secret" = DynamicSecretA.appsecret()
    assert "dynamic_aes_key" = DynamicSecretA.aes_key()
    assert "dynamic_encoding_aes_key" = DynamicSecretA.encoding_aes_key()
    assert "component_app_secret" = DynamicSecretB.component_appsecret()
  end

  test "dynamic_agents" do
    WorkAgent.maybe_init_work_agents(Work3)
    assert is_list(Work3.agents())
    assert 1 = length(Work3.agents())
    assert WorkAgent.fetch_agent_cache_id!(Work2, 10000) == "corp_id_10000"
    assert WorkAgent.fetch_agent_cache_id!(Work2, :agent_name) == "corp_id_10000"
  end
end
