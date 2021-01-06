defmodule WeChatTest do
  use ExUnit.Case
  alias WeChat.Utils
  alias WeChat.ServerMessage.{EventHandler, XmlMessage}
  doctest WeChat

  test "Auto generate functions" do
    assert WxApp.role() == :official_account
    assert WxApp.storage() == WeChat.Storage.File
    assert WxApp.appid() == "wx2c2769f8efd9abc2"
    assert WxApp.appsecret() == "appsecret"
    assert WxApp.encoding_aes_key() == "abcdefghijklmnopqrstuvwxyz0123456789ABCDEFG"
    assert WxApp.token() == "spamtest"
    assert is_list(WxApp.default_opts()) == true
  end

  test "build client" do
    opts = [
      appid: "wx2c2769f8efd9abc2",
      appsecret: "appsecret",
      encoding_aes_key: "abcdefghijklmnopqrstuvwxyz0123456789ABCDEFG",
      token: "spamtest"
    ]

    assert {:ok, WxApp3} = WeChat.build_client(WxApp3, opts)
    assert WxApp.appid() == "wx2c2769f8efd9abc2"
  end

  test "Encrypt Msg" do
    timestamp = Utils.now_unix()

    xml_string =
      XmlMessage.reply_text(
        "oia2TjjewbmiOUlr6X-1crbLOvLw",
        "gh_7f083739789a",
        timestamp,
        "hello world"
      )
      |> EventHandler.encode_xml_msg(timestamp, WxApp)

    assert is_binary(xml_string) == true
  end
end
