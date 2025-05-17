defmodule WeChat.Refresher.DefaultTest do
  use ExUnit.Case
  alias WeChat.Refresher.Default
  alias WeChat.Storage.Cache
  alias WeChat.Test.{OfficialAccount, Component, MiniComponent}

  @moduletag :capture_log

  setup_all do
    WeChat.Test.Mock.mock()
  end

  test "add client" do
    Application.put_env(:wechat, :check_token_for_clients, [
      MiniComponent,
      Component,
      OfficialAccount
    ])

    assert :ok = Default.add(OfficialAccount)
    assert :ok = Default.add(Component)
    assert :ok = Default.add(MiniComponent)

    assert [MiniComponent, Component, OfficialAccount] = Default.clients()

    assert %{
             "wx3c2769f8efd9abc3" => %{
               keys: [:component_access_token],
               clients: [Component, MiniComponent]
             }
           } = Default.components()

    assert ["wx2c2769f8efd9abc2", "wx3c2769f8efd9abc3"] = WeChat.TokenChecker.ids()
  end

  test "refresh_client" do
    assert :ok = Default.refresh(OfficialAccount)
    assert :ok = Default.refresh(OfficialAccount, OfficialAccount.appid(), :access_token)
  end

  test "refresh_component" do
    assert :ok = Default.refresh_component(Component.component_appid(), :component_access_token)
  end

  test "remove client" do
    %{refresh_options: refresh_options} = Default.client_options(OfficialAccount)

    for {{store_id, store_key}, _fun, _timer} <- refresh_options do
      assert false == is_nil(Cache.get_cache({store_id, store_key}))
      assert false == is_nil(Cache.get_cache({:store_map, store_id}, store_key))
    end

    assert :ok = Default.remove(OfficialAccount)
    assert [MiniComponent, Component] = Default.clients()
    assert nil == Default.client_options(OfficialAccount)

    for {{store_id, store_key}, _fun, _timer} <- refresh_options do
      assert nil == Cache.get_cache({store_id, store_key})
      assert nil == Cache.get_cache({:store_map, store_id}, store_key)
    end
  end
end
