defmodule WeChat.Refresher.DefaultTest do
  use ExUnit.Case
  alias WeChat.Refresher.Default
  alias WeChat.Test.OfficialAccount

  setup_all do
    WeChat.Test.Mock.mock()
  end

  test "add client" do
    assert :ok = Default.add(OfficialAccount)
  end
end
