defmodule WeChat.Work.LinkedCorp.Message do
  @moduledoc """
  互联企业-消息推送

  互联企业是企业微信提供的满足集团与子公司、企业与上下游供应商进行连接的功能，
  企业可以共享通讯录以及应用给互联企业，如需要，你可以前往管理后台-通讯录创建互联企业，
  之后你可以在自建应用的可见范围设置互联企业的通讯录；
  此接口主要满足开发者给互联企业成员推送消息的诉求。
  """

  import WeChat.Utils, only: [work_doc_link_prefix: 0]
  import WeChat.Work.Agent, only: [agent2id: 2]
  alias WeChat.{Work, Work.Material}
  alias WeChat.Work.Message, as: Msg

  @doc_link "#{work_doc_link_prefix()}/90000/90135/90249"

  @type to :: {:user | :party | :tag, list | String.t()} | {:all, integer}
  @type opts :: Enumerable.t()

  @doc """
  发送应用消息 - [官方文档](#{@doc_link}#接口定义){:target="_blank"}
  """
  @spec send_message(Work.client(), Work.agent(), body :: map) :: WeChat.response()
  def send_message(client, agent, body) do
    client.post("/cgi-bin/linkedcorp/message/send", body,
      query: [access_token: client.get_access_token(agent)]
    )
  end

  @spec send(Work.client(), Work.agent(), to, Msg.msg_type(), Msg.msg(), opts) ::
          WeChat.response()
  def send(client, agent, to, msg_type, msg, opts \\ []) when is_tuple(to) do
    {to_key, to_value} =
      case to do
        {:user, list} -> {"touser", List.wrap(list)}
        {:party, list} -> {"toparty", List.wrap(list)}
        {:tag, list} -> {"totag", List.wrap(list)}
        {:all, 1} -> {"toall", 1}
      end

    agent_id = agent2id(client, agent)

    body =
      Map.new(opts)
      |> Map.put("agentid", agent_id)
      |> Map.put("msgtype", msg_type)
      |> Map.put(msg_type, msg)
      |> Map.put(to_key, to_value)

    send_message(client, agent, body)
  end

  @spec to_user(list) :: to
  def to_user(list), do: {:user, list}
  @spec to_party(list) :: to
  def to_party(list), do: {:party, list}
  @spec to_tag(list) :: to
  def to_tag(list), do: {:tag, list}
  @spec to_all :: to
  def to_all, do: {:all, 1}

  @doc """
  发送文本消息 - [官方文档](#{@doc_link}#文本消息){:target="_blank"}
  """
  @spec send_text(Work.client(), Work.agent(), to, Msg.content(), opts) :: WeChat.response()
  def send_text(client, agent, to, content, opts \\ []) do
    send(client, agent, to, "text", %{"content" => content}, opts)
  end

  @doc """
  发送图片消息 - [官方文档](#{@doc_link}#图片消息){:target="_blank"}
  """
  @spec send_image(Work.client(), Work.agent(), to, Material.media_id(), opts) ::
          WeChat.response()
  def send_image(client, agent, to, media_id, opts \\ []) do
    send(client, agent, to, "image", %{"media_id" => media_id}, opts)
  end

  @doc """
  发送语音消息 - [官方文档](#{@doc_link}#语音消息){:target="_blank"}
  """
  @spec send_voice(Work.client(), Work.agent(), to, Material.media_id(), opts) ::
          WeChat.response()
  def send_voice(client, agent, to, media_id, opts \\ []) do
    send(client, agent, to, "voice", %{"media_id" => media_id}, opts)
  end

  @doc """
  发送视频消息 - [官方文档](#{@doc_link}#视频消息){:target="_blank"}
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
  发送文件消息 - [官方文档](#{@doc_link}#文件消息){:target="_blank"}
  """
  @spec send_file(Work.client(), Work.agent(), to, Material.media_id(), opts) :: WeChat.response()
  def send_file(client, agent, to, media_id, opts \\ []) do
    send(client, agent, to, "file", %{"media_id" => media_id}, opts)
  end

  @doc """
  发送文本卡片消息 - [官方文档](#{@doc_link}#文本卡片消息){:target="_blank"}
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
  发送图文消息 - [官方文档](#{@doc_link}#图文消息){:target="_blank"}
  """
  @spec send_news(Work.client(), Work.agent(), to, Msg.msg(), opts) :: WeChat.response()
  def send_news(client, agent, to, msg, opts \\ []) do
    send(client, agent, to, "news", msg, opts)
  end

  @doc """
  发送图文消息（mpnews） - [官方文档](#{@doc_link}#图文消息（mpnews）){:target="_blank"}
  """
  @spec send_mpnews(Work.client(), Work.agent(), to, Msg.msg(), opts) :: WeChat.response()
  def send_mpnews(client, agent, to, msg, opts \\ []) do
    send(client, agent, to, "mpnews", msg, opts)
  end

  @doc """
  发送markdown消息 - [官方文档](#{@doc_link}#markdown消息){:target="_blank"}
  """
  @spec send_markdown(Work.client(), Work.agent(), to, Msg.content(), opts) :: WeChat.response()
  def send_markdown(client, agent, to, content, opts \\ []) do
    send(client, agent, to, "markdown", %{"content" => content}, opts)
  end

  @doc """
  发送小程序通知消息 - [官方文档](#{@doc_link}#小程序通知消息){:target="_blank"}
  """
  @spec send_miniprogram_notice(Work.client(), Work.agent(), to, Msg.msg(), opts) ::
          WeChat.response()
  def send_miniprogram_notice(client, agent, to, msg, opts \\ []) do
    send(client, agent, to, "miniprogram_notice", msg, opts)
  end
end
