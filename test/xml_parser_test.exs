defmodule WeChat.XmlParserTest do
  use ExUnit.Case, async: true
  alias WeChat.Utils
  alias WeChat.ServerMessage.{XmlMessage, XmlParser}

  test "xml_parse" do
    timestamp = Utils.now_unix()

    {:ok, map} =
      XmlMessage.reply_text(
        "oia2TjjewbmiOUlr6X-1crbLOvLw",
        "gh_7f083739789a",
        timestamp,
        "hello world"
      )
      |> XmlParser.parse()

    assert map == %{
             "Content" => "hello world",
             "CreateTime" => to_string(timestamp),
             "FromUserName" => "gh_7f083739789a",
             "MsgType" => "text",
             "ToUserName" => "oia2TjjewbmiOUlr6X-1crbLOvLw"
           }
  end

  test "xml_parse - empty content" do
    timestamp = Utils.now_unix()

    {:ok, map} =
      XmlMessage.reply_text(
        "oia2TjjewbmiOUlr6X-1crbLOvLw",
        "gh_7f083739789a",
        timestamp,
        ""
      )
      |> XmlParser.parse()

    assert map == %{
             "Content" => "",
             "CreateTime" => to_string(timestamp),
             "FromUserName" => "gh_7f083739789a",
             "MsgType" => "text",
             "ToUserName" => "oia2TjjewbmiOUlr6X-1crbLOvLw"
           }
  end
end
