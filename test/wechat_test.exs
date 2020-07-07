defmodule WeChatTest do
  use ExUnit.Case
  alias WeChat.Utils
  alias WeChat.ServerMessage.{EventHandler, XmlMessage}
  doctest WeChat

  test "Encrypt Msg" do
    timestamp = Utils.now_unix()

    xml =
      XmlMessage.reply_text(
        "oia2TjjewbmiOUlr6X-1crbLOvLw",
        "gh_7f083739789a",
        timestamp,
        "hello world"
      )
      |> EventHandler.encode_msg(timestamp, WxApp)
      |> IO.inspect()

    assert is_binary(xml) == true
  end
end
