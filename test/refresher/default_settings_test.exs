defmodule WeChat.Refresher.DefaultSettingsTest do
  use ExUnit.Case
  alias WeChat.Refresher.DefaultSettings
  alias WeChat.Test.{OfficialAccount, Component}

  @moduletag :capture_log

  setup_all do
    WeChat.Test.Mock.mock()
  end

  test "refresh_access_token" do
    assert {:ok, "ACCESS_TOKEN", 7200} = DefaultSettings.refresh_access_token(OfficialAccount)

    assert {:ok, "COMPONENT_ACCESS_TOKEN", 7200} =
             DefaultSettings.refresh_component_access_token(Component)
  end

  test "refresh_ticket" do
    assert {:ok, "jsapi-ticket", 7200} = DefaultSettings.refresh_ticket("jsapi", OfficialAccount)

    assert {:ok, "wx_card-ticket", 7200} =
             DefaultSettings.refresh_ticket("wx_card", OfficialAccount)
  end
end
