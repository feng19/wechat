defmodule WeChat.Work.Message do
  @moduledoc "消息推送"

  import WeChat.Utils, only: [work_doc_link_prefix: 0]
  alias WeChat.Work

  @doc_link "#{work_doc_link_prefix()}/90000/90135"

  @doc """
  发送应用消息 - [官方文档](#{@doc_link}/90236){:target="_blank"}

  应用支持推送文本、图片、视频、文件、图文等类型。

  - 各个消息类型的具体POST格式请阅后续“消息类型”部分。
  - 如果有在管理端对应用设置“在微工作台中始终进入主页”，应用在微信端只能接收到文本消息，并且文本消息的长度限制为20字节，超过20字节会被截断。同时其他消息类型也会转换为文本消息，提示用户到企业微信查看。
  - 支持id转译，将userid/部门id转成对应的用户名/部门名，目前仅文本/文本卡片/图文/图文（mpnews）这四种消息类型的部分字段支持。仅第三方应用需要用到，企业自建应用可以忽略。具体支持的范围和语法，请查看附录id转译说明。
  - 支持重复消息检查，当指定 "enable_duplicate_check": 1开启: 表示在一定时间间隔内，同样内容（请求json）的消息，不会重复收到；时间间隔可通过duplicate_check_interval指定，默认1800秒。
  - 从2021年2月4日开始，企业关联添加的「小程序」应用，也可以发送文本、图片、视频、文件、图文等各种类型的消息了。
  """
  @spec send_message(Work.client(), Work.agent(), body :: map) :: WeChat.response()
  def send_message(client, agent, body) do
    client.post("/cgi-bin/message/send", body,
      query: [access_token: client.get_access_token(agent)]
    )
  end
end
