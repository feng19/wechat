defmodule WeChat.EventHandlerTest do
  use ExUnit.Case, async: true
  alias WeChat.ServerMessage.{EventHelper, ReplyMessage, XmlParser}
  alias WeChat.{Utils, Test.OfficialAccount}

  test "Encrypt Msg" do
    client = OfficialAccount
    timestamp = Utils.now_unix()
    to_openid = "oia2TjjewbmiOUlr6X-1crbLOvLw"
    from_wx_no = "gh_7f083739789a"
    content = "hello world"
    xml_text = ReplyMessage.reply_text(to_openid, from_wx_no, timestamp, content)

    xml_string = EventHelper.encrypt_xml_msg(xml_text, timestamp, client)
    {:ok, xml} = XmlParser.parse(xml_string)
    encrypt_content = xml["Encrypt"]

    params = %{
      "msg_signature" => xml["MsgSignature"],
      "nonce" => xml["Nonce"],
      "timestamp" => timestamp
    }

    {:ok, :encrypted_xml, xml_text} = EventHelper.decrypt_xml_msg(encrypt_content, params, client)

    assert xml_text["ToUserName"] == to_openid
    assert xml_text["FromUserName"] == from_wx_no
    assert xml_text["Content"] == content
  end
end
