defmodule WeChat.Work.Message do
  @moduledoc "消息推送"

  import WeChat.Work.Agent, only: [agent2id: 2]
  alias WeChat.{Work, Work.Material}

  @doc_link WeChat.Utils.new_work_doc_link_prefix()

  @typedoc """
  消息类型

  - `text`: 文本消息
  - `image`: 图片消息
  - `voice`: 语音消息
  - `video`: 视频消息
  - `file`: 文件消息
  - `textcard`: 文本卡片消息
  - `news`: 图文消息
  - `mpnews`: 图文消息（mpnews）
  - `markdown`: markdown消息
  - `miniprogram_notice`: 小程序通知消息
  - `template_card`: 模板卡片消息
  """
  @type msg_type :: String.t()
  @typedoc "消息ID"
  @type msg_id :: String.t()

  @type to :: {:user | :party | :tag, list | String.t()}
  @type msg :: map
  @type opts :: Enumerable.t()
  @type content :: String.t()

  @doc """
  发送应用消息 -
  [官方文档](#{@doc_link}/90236){:target="_blank"}

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

  @spec send(Work.client(), Work.agent(), to, msg_type, msg, opts) :: WeChat.response()
  def send(client, agent, to, msg_type, msg, opts \\ []) when is_tuple(to) do
    {to_key, to_value} =
      case to do
        {:user, list} -> {"touser", list}
        {:party, list} -> {"toparty", list}
        {:tag, list} -> {"totag", list}
      end

    to = to_value |> List.wrap() |> Enum.join("|")
    agent_id = agent2id(client, agent)

    body =
      Map.new(opts)
      |> Map.put("agentid", agent_id)
      |> Map.put("msgtype", msg_type)
      |> Map.put(msg_type, msg)
      |> Map.put(to_key, to)

    send_message(client, agent, body)
  end

  @spec to_user(list | String.t()) :: to
  def to_user(list), do: {:user, list}
  @spec to_party(list) :: to
  def to_party(list), do: {:party, list}
  @spec to_tag(list) :: to
  def to_tag(list), do: {:tag, list}

  @doc """
  发送文本消息 -
  [官方文档](#{@doc_link}/90236#文本消息){:target="_blank"}
  """
  @spec send_text(Work.client(), Work.agent(), to, content, opts) :: WeChat.response()
  def send_text(client, agent, to, content, opts \\ []) do
    send(client, agent, to, "text", %{"content" => content}, opts)
  end

  @doc """
  发送图片消息 -
  [官方文档](#{@doc_link}/90236#图片消息){:target="_blank"}
  """
  @spec send_image(Work.client(), Work.agent(), to, Material.media_id(), opts) ::
          WeChat.response()
  def send_image(client, agent, to, media_id, opts \\ []) do
    send(client, agent, to, "image", %{"media_id" => media_id}, opts)
  end

  @doc """
  发送语音消息 -
  [官方文档](#{@doc_link}/90236#语音消息){:target="_blank"}
  """
  @spec send_voice(Work.client(), Work.agent(), to, Material.media_id(), opts) ::
          WeChat.response()
  def send_voice(client, agent, to, media_id, opts \\ []) do
    send(client, agent, to, "voice", %{"media_id" => media_id}, opts)
  end

  @doc """
  发送视频消息 -
  [官方文档](#{@doc_link}/90236#视频消息){:target="_blank"}
  """
  @spec send_video(
          Work.client(),
          Work.agent(),
          to,
          Material.media_id(),
          title :: String.t(),
          description :: String.t(),
          opts
        ) :: WeChat.response()
  def send_video(client, agent, to, media_id, title, description, opts \\ []) do
    msg = %{
      "media_id" => media_id,
      "title" => title,
      "description" => description
    }

    send(client, agent, to, "video", msg, opts)
  end

  @doc """
  发送文件消息 -
  [官方文档](#{@doc_link}/90236#文件消息){:target="_blank"}
  """
  @spec send_file(Work.client(), Work.agent(), to, Material.media_id(), opts) :: WeChat.response()
  def send_file(client, agent, to, media_id, opts \\ []) do
    send(client, agent, to, "file", %{"media_id" => media_id}, opts)
  end

  @doc """
  发送文本卡片消息 -
  [官方文档](#{@doc_link}/90236#文本卡片消息){:target="_blank"}
  """
  @spec send_text_card(
          Work.client(),
          Work.agent(),
          to,
          title :: String.t(),
          description :: String.t(),
          url :: String.t(),
          btn_txt :: String.t(),
          opts
        ) :: WeChat.response()
  def send_text_card(client, agent, to, title, description, url, btn_txt, opts \\ []) do
    msg = %{
      "title" => title,
      "description" => description,
      "url" => url,
      "btntxt" => btn_txt
    }

    send(client, agent, to, "textcard", msg, opts)
  end

  @doc """
  发送图文消息 -
  [官方文档](#{@doc_link}/90236#图文消息){:target="_blank"}
  """
  @spec send_news(Work.client(), Work.agent(), to, msg, opts) :: WeChat.response()
  def send_news(client, agent, to, msg, opts \\ []) do
    send(client, agent, to, "news", msg, opts)
  end

  @doc """
  发送图文消息（mpnews） -
  [官方文档](#{@doc_link}/90236#图文消息（mpnews）){:target="_blank"}
  """
  @spec send_mpnews(Work.client(), Work.agent(), to, msg, opts) :: WeChat.response()
  def send_mpnews(client, agent, to, msg, opts \\ []) do
    send(client, agent, to, "mpnews", msg, opts)
  end

  @doc """
  发送markdown消息 -
  [官方文档](#{@doc_link}/90236#markdown消息){:target="_blank"}
  """
  @spec send_markdown(Work.client(), Work.agent(), to, content, opts) :: WeChat.response()
  def send_markdown(client, agent, to, content, opts \\ []) do
    send(client, agent, to, "markdown", %{"content" => content}, opts)
  end

  @doc """
  发送小程序通知消息 -
  [官方文档](#{@doc_link}/90236#小程序通知消息){:target="_blank"}
  """
  @spec send_miniprogram_notice(Work.client(), Work.agent(), to, msg, opts) :: WeChat.response()
  def send_miniprogram_notice(client, agent, to, msg, opts \\ []) do
    send(client, agent, to, "miniprogram_notice", msg, opts)
  end

  @doc """
  发送模板卡片消息 -
  [官方文档](#{@doc_link}/90236#模板卡片消息){:target="_blank"}
  """
  @spec send_template_card(Work.client(), Work.agent(), to, msg, opts) :: WeChat.response()
  def send_template_card(client, agent, to, msg, opts \\ []) do
    send(client, agent, to, "template_card", msg, opts)
  end

  @doc """
  更新模版卡片消息 -
  [官方文档](#{@doc_link}/94888){:target="_blank"}

  应用可以发送模板卡片消息，发送之后可再通过接口更新可回调的用户任务卡片消息的替换文案信息
  （仅原卡片为 按钮交互型、投票选择型、多项选择型的卡片可以调用本接口更新）。

  请注意，当应用调用发送模版卡片消息后，接口会返回一个 `response_code`，通过 `response_code` 用户可以调用本接口一次。
  后续如果有用户点击任务卡片，回调接口也会带上 `response_code`，开发者通过该 `code` 也可以调用本接口一次，
  注意 `response_code` 的有效期是24小时，超过24小时后将无法使用。
  """
  @spec update_template_card(Work.client(), Work.agent(), body :: map) :: WeChat.response()
  def update_template_card(client, agent, body) do
    client.post("/cgi-bin/message/update_template_card", body,
      query: [access_token: client.get_access_token(agent)]
    )
  end

  @doc """
  撤回应用消息 -
  [官方文档](#{@doc_link}/94867){:target="_blank"}
  """
  @spec recall(Work.client(), Work.agent(), msg_id) :: WeChat.response()
  def recall(client, agent, msg_id) do
    client.post("/cgi-bin/message/recall", %{"msgid" => msg_id},
      query: [access_token: client.get_access_token(agent)]
    )
  end
end
