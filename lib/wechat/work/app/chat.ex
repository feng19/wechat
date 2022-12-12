defmodule WeChat.Work.App.Chat do
  @moduledoc "群聊会话"

  import WeChat.Utils, only: [new_work_doc_link_prefix: 0]
  alias WeChat.{Work, Work.Message, Work.Material}
  alias Work.Contacts.User

  @doc_link new_work_doc_link_prefix()

  @type chat_id :: String.t()
  @type opts :: Enumerable.t()

  @doc """
  创建群聊会话 -
  [官方文档](#{@doc_link}/90245){:target="_blank"}
  """
  @spec create(Work.client(), Work.agent(), User.userid_list(), opts) :: WeChat.response()
  def create(client, agent, user_list, opts \\ []) do
    client.post(
      "/cgi-bin/appchat/create",
      Map.new(opts) |> Map.put("userlist", user_list),
      query: [access_token: client.get_access_token(agent)]
    )
  end

  @doc """
  修改群聊会话 -
  [官方文档](#{@doc_link}/90246){:target="_blank"}
  """
  @spec update(Work.client(), Work.agent(), chat_id, opts) :: WeChat.response()
  def update(client, agent, chat_id, opts \\ []) do
    client.post(
      "/cgi-bin/appchat/update",
      Map.new(opts) |> Map.put("chatid", chat_id),
      query: [access_token: client.get_access_token(agent)]
    )
  end

  @doc """
  获取群聊会话 -
  [官方文档](#{@doc_link}/90247){:target="_blank"}
  """
  @spec get(Work.client(), Work.agent(), chat_id) :: WeChat.response()
  def get(client, agent, chat_id) do
    client.get("/cgi-bin/appchat/get",
      query: [
        chatid: chat_id,
        access_token: client.get_access_token(agent)
      ]
    )
  end

  @doc """
  推送群聊消息 -
  [官方文档](#{@doc_link}/90248){:target="_blank"}
  """
  @spec send(Work.client(), Work.agent(), chat_id, opts) :: WeChat.response()
  def send(client, agent, chat_id, opts \\ []) do
    client.post(
      "/cgi-bin/appchat/send",
      Map.new(opts) |> Map.put("chatid", chat_id),
      query: [access_token: client.get_access_token(agent)]
    )
  end

  @spec send(Work.client(), Work.agent(), chat_id, Message.msg(), opts) :: WeChat.response()
  def send(client, agent, chat_id, msg_type, msg, opts \\ []) do
    send(client, agent, chat_id, [
      {"chatid", chat_id},
      {"msgtype", msg_type},
      {msg_type, msg} | opts
    ])
  end

  @doc """
  发送文本消息 - [官方文档](#{@doc_link}/90248#文本消息){:target="_blank"}
  """
  @spec send_text(Work.client(), Work.agent(), chat_id, Message.content(), opts) ::
          WeChat.response()
  def send_text(client, agent, chat_id, content, opts \\ []) do
    send(client, agent, chat_id, "text", %{"content" => content}, opts)
  end

  @doc """
  发送图片消息 - [官方文档](#{@doc_link}/90248#图片消息){:target="_blank"}
  """
  @spec send_image(Work.client(), Work.agent(), chat_id, Material.media_id(), opts) ::
          WeChat.response()
  def send_image(client, agent, chat_id, media_id, opts \\ []) do
    send(client, agent, chat_id, "image", %{"media_id" => media_id}, opts)
  end

  @doc """
  发送语音消息 - [官方文档](#{@doc_link}/90248#语音消息){:target="_blank"}
  """
  @spec send_voice(Work.client(), Work.agent(), chat_id, Material.media_id(), opts) ::
          WeChat.response()
  def send_voice(client, agent, chat_id, media_id, opts \\ []) do
    send(client, agent, chat_id, "voice", %{"media_id" => media_id}, opts)
  end

  @doc """
  发送视频消息 - [官方文档](#{@doc_link}/90248#视频消息){:target="_blank"}
  """
  @spec send_video(
          Work.client(),
          Work.agent(),
          chat_id,
          Material.media_id(),
          title :: String.t(),
          description :: String.t(),
          opts
        ) :: WeChat.response()
  def send_video(client, agent, chat_id, media_id, title, description, opts \\ []) do
    msg = %{
      "media_id" => media_id,
      "title" => title,
      "description" => description
    }

    send(client, agent, chat_id, "video", msg, opts)
  end

  @doc """
  发送文件消息 - [官方文档](#{@doc_link}/90248#文件消息){:target="_blank"}
  """
  @spec send_file(Work.client(), Work.agent(), chat_id, Material.media_id(), opts) ::
          WeChat.response()
  def send_file(client, agent, chat_id, media_id, opts \\ []) do
    send(client, agent, chat_id, "file", %{"media_id" => media_id}, opts)
  end

  @doc """
  发送文本卡片消息 - [官方文档](#{@doc_link}/90248#文本卡片消息){:target="_blank"}
  """
  @spec send_text_card(
          Work.client(),
          Work.agent(),
          chat_id,
          title :: String.t(),
          description :: String.t(),
          url :: String.t(),
          btn_txt :: String.t(),
          opts
        ) :: WeChat.response()
  def send_text_card(client, agent, chat_id, title, description, url, btn_txt, opts \\ []) do
    msg = %{
      "title" => title,
      "description" => description,
      "url" => url,
      "btntxt" => btn_txt
    }

    send(client, agent, chat_id, "textcard", msg, opts)
  end

  @doc """
  发送图文消息 - [官方文档](#{@doc_link}/90248#图文消息){:target="_blank"}
  """
  @spec send_news(Work.client(), Work.agent(), chat_id, Message.msg(), opts) :: WeChat.response()
  def send_news(client, agent, chat_id, msg, opts \\ []) do
    send(client, agent, chat_id, "news", msg, opts)
  end

  @doc """
  发送图文消息（mpnews） - [官方文档](#{@doc_link}/90248#图文消息（mpnews）){:target="_blank"}
  """
  @spec send_mpnews(Work.client(), Work.agent(), chat_id, Message.msg(), opts) ::
          WeChat.response()
  def send_mpnews(client, agent, chat_id, msg, opts \\ []) do
    send(client, agent, chat_id, "mpnews", msg, opts)
  end

  @doc """
  发送markdown消息 - [官方文档](#{@doc_link}/90248#markdown消息){:target="_blank"}
  """
  @spec send_markdown(Work.client(), Work.agent(), chat_id, Message.content(), opts) ::
          WeChat.response()
  def send_markdown(client, agent, chat_id, content, opts \\ []) do
    send(client, agent, chat_id, "markdown", %{"content" => content}, opts)
  end
end
