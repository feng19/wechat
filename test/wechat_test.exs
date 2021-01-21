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

    aes_key =
      WeChat.ServerMessage.Encryptor.aes_key("abcdefghijklmnopqrstuvwxyz0123456789ABCDEFG")

    assert WxApp.aes_key() == aes_key
    assert WxApp.token() == "spamtest"
    assert is_list(WxApp.default_opts()) == true
    assert true = Enum.all?(1..3, &function_exported?(WxApp, :get, &1))
    assert true = Enum.all?(2..4, &function_exported?(WxApp, :post, &1))
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
    assert function_exported?(WxApp3.WebApp, :code2access_token, 1)
    assert false == function_exported?(WxApp3.MiniProgram.Auth, :code2session, 1)
  end

  test "build component client" do
    opts = [
      role: :component,
      appid: "wx2c2769f8efd9abc2",
      appsecret: "appsecret",
      encoding_aes_key: "abcdefghijklmnopqrstuvwxyz0123456789ABCDEFG",
      token: "spamtest"
    ]

    assert {:ok, WxApp4} = WeChat.build_client(WxApp4, opts)
    assert apply(WxApp4, :appid, []) == "wx2c2769f8efd9abc2"
    assert function_exported?(WxApp4.Component, :get_authorizer_info, 0)
    assert function_exported?(WxApp4.WebApp, :code2access_token, 1)
    assert false == function_exported?(WxApp4.MiniProgram.Auth, :code2session, 1)
  end

  test "build mini_program client" do
    opts = [
      role: :mini_program,
      appid: "wx2c2769f8efd9abc2",
      appsecret: "appsecret",
      encoding_aes_key: "abcdefghijklmnopqrstuvwxyz0123456789ABCDEFG",
      token: "spamtest"
    ]

    assert {:ok, WxApp5} = WeChat.build_client(WxApp5, opts)
    assert apply(WxApp5, :appid, []) == "wx2c2769f8efd9abc2"
    assert false == function_exported?(WxApp5.WebApp, :code2access_token, 1)
    assert function_exported?(WxApp5.MiniProgram.Auth, :code2session, 1)
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
