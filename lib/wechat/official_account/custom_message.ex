defmodule WeChat.CustomMessage do
  @moduledoc """
  消息管理 - 客服消息

  [API Docs Link](https://developers.weixin.qq.com/doc/offiaccount/Message_Management/Service_Center_messages.html){:target="_blank"}
  """
  import Jason.Helpers
  import WeChat.Utils, only: [doc_link_prefix: 0]
  alias WeChat.{Card, Material}

  @doc_link "#{doc_link_prefix()}/doc/offiaccount/Message_Management/Service_Center_messages.html"

  @type template_id :: String.t()
  @type title :: String.t()
  @type description :: String.t()
  @type url :: String.t()
  @type pic_url :: String.t()
  @type content :: String.t()

  @doc """
  客服消息接口 - 发送文本消息 -
  [Official API Docs Link](#{@doc_link}#7){:target="_blank"}
  """
  @spec send_text(WeChat.client(), WeChat.openid(), content) :: WeChat.response()
  def send_text(client, openid, content) do
    send_msg(
      client,
      json_map(touser: openid, msgtype: "text", text: %{content: content})
    )
  end

  @doc """
  客服消息接口 - 发送文本消息 - by某个客服帐号 -
  [Official API Docs Link](#{@doc_link}#7){:target="_blank"}
  """
  @spec send_text(WeChat.client(), WeChat.openid(), content, WeChat.CustomService.kf_account()) ::
          WeChat.response()
  def send_text(client, openid, content, kf_account) do
    send_msg(
      client,
      json_map(
        touser: openid,
        msgtype: "text",
        text: %{content: content},
        customservice: %{kf_account: kf_account}
      )
    )
  end

  @doc """
  客服消息接口 - 发送图片消息 -
  [Official API Docs Link](#{@doc_link}#7){:target="_blank"}
  """
  @spec send_image(WeChat.client(), WeChat.openid(), WeChat.Material.media_id()) ::
          WeChat.response()
  def send_image(client, openid, media_id) do
    send_msg(
      client,
      json_map(touser: openid, msgtype: "image", image: %{media_id: media_id})
    )
  end

  @doc """
  客服消息接口 - 发送语音消息 -
  [Official API Docs Link](#{@doc_link}#7){:target="_blank"}
  """
  @spec send_voice(WeChat.client(), WeChat.openid(), WeChat.Material.media_id()) ::
          WeChat.response()
  def send_voice(client, openid, media_id) do
    send_msg(
      client,
      json_map(touser: openid, msgtype: "voice", voice: %{media_id: media_id})
    )
  end

  @doc """
  客服消息接口 - 发送视频消息 -
  [Official API Docs Link](#{@doc_link}#7){:target="_blank"}

  ## Example

  ```elixir
  #{__MODULE__}.send_video(client, openid, {
    media_id:         "MEDIA_ID",
    thumb_media_id:   "MEDIA_ID",
    title:            "TITLE",
    description:      "DESCRIPTION"
  })
  ```
  """
  @spec send_video(WeChat.client(), WeChat.openid(), map) :: WeChat.response()
  def send_video(client, openid, map) do
    send_msg(
      client,
      json_map(touser: openid, msgtype: "video", video: map)
    )
  end

  @doc """
  客服消息接口 - 发送音乐消息 -
  [Official API Docs Link](#{@doc_link}#7){:target="_blank"}

  ## Example

  ```elixir
  #{__MODULE__}.send_music(client, openid, {
    title:          "MUSIC_TITLE",
    description:    "MUSIC_DESCRIPTION",
    musicurl:       "MUSIC_URL",
    hqmusicurl:     "HQ_MUSIC_URL",
    thumb_media_id: "THUMB_MEDIA_ID"
  })
  ```
  """
  @spec send_music(WeChat.client(), WeChat.openid(), map) :: WeChat.response()
  def send_music(client, openid, map) do
    send_msg(
      client,
      json_map(touser: openid, msgtype: "music", music: map)
    )
  end

  @doc """
  客服消息接口 - 发送图文消息(点击跳转到外链) -
  [Official API Docs Link](#{@doc_link}#7){:target="_blank"}

  ## Example

  ```elixir
  #{__MODULE__}.send_news(client, openid, {
    title:        "Happy Day",
    description:  "Is Really A Happy Day",
    url:          "URL",
    picurl:       "PIC_URL"
  })
  ```
  """
  @spec send_news(WeChat.client(), WeChat.openid(), title, description, url, pic_url) ::
          WeChat.response()
  def send_news(client, openid, title, description, url, pic_url) do
    send_msg(
      client,
      json_map(
        touser: openid,
        msgtype: "news",
        news: %{articles: [%{title: title, description: description, url: url, picurl: pic_url}]}
      )
    )
  end

  @doc """
  客服消息接口 - 发送图文消息(点击跳转到外链) -
  [Official API Docs Link](#{@doc_link}#7){:target="_blank"}
  """
  @spec send_news(WeChat.client(), WeChat.openid(), article :: map) :: WeChat.response()
  def send_news(client, openid, article) do
    send_msg(
      client,
      json_map(touser: openid, msgtype: "news", news: %{articles: [article]})
    )
  end

  @doc """
  客服消息接口 - 发送图文消息(点击跳转到图文消息页面) -
  [Official API Docs Link](#{@doc_link}#7){:target="_blank"}
  """
  @spec send_mp_news(WeChat.client(), WeChat.openid(), Material.media_id()) :: WeChat.response()
  def send_mp_news(client, openid, media_id) do
    send_msg(
      client,
      json_map(touser: openid, msgtype: "mpnews", mpnews: %{media_id: media_id})
    )
  end

  @doc """
  客服消息接口 - 发送菜单消息 -
  [Official API Docs Link](#{@doc_link}#7){:target="_blank"}

  ## Example

  ```elixir
  #{__MODULE__}.send_menu(client, openid, {
    head_content: "您对本次服务是否满意呢?",
    list: [
      {
        id: "101",
        content: "满意"
      },
      {
        id: "102",
        content: "不满意"
      }
    ],
    tail_content: "欢迎再次光临"
  })
  ```
  """
  @spec send_menu(WeChat.client(), WeChat.openid(), map) :: WeChat.response()
  def send_menu(client, openid, map) do
    send_msg(
      client,
      json_map(touser: openid, msgtype: "msgmenu", msgmenu: map)
    )
  end

  @doc """
  客服消息接口 - 发送卡券 -
  [Official API Docs Link](#{@doc_link}#7){:target="_blank"}
  """
  @spec send_card(WeChat.client(), WeChat.openid(), Card.card_id()) :: WeChat.response()
  def send_card(client, openid, card_id) do
    send_msg(
      client,
      json_map(touser: openid, msgtype: "wxcard", wxcard: %{card_id: card_id})
    )
  end

  @doc """
  客服消息接口 - 发送小程序卡片(要求小程序与公众号已关联) -
  [Official API Docs Link](#{@doc_link}#7){:target="_blank"}

  ## Example
  ```elixir
  #{__MODULE__}.send_mini_program_page(client, openid, {
    title:    "title",
    appid:    "appid",
    pagepath: "pagepath",
    thumb_media_id: "thumb_media_id"
  })
  ```
  """
  @spec send_mini_program_page(WeChat.client(), WeChat.openid(), map) :: WeChat.response()
  def send_mini_program_page(client, openid, map) do
    send_msg(
      client,
      json_map(touser: openid, msgtype: "miniprogrampage", miniprogrampage: map)
    )
  end

  @doc """
  客服消息接口 -
  [Official API Docs Link](#{@doc_link}#7){:target="_blank"}
  """
  def send_msg(client, body) do
    client.post("/cgi-bin/message/custom/send", body,
      query: [access_token: client.get_access_token()]
    )
  end

  @doc """
  客服输入状态 -
  [Official API Docs Link](#{@doc_link}#8){:target="_blank"}

  开发者可通过调用“客服输入状态”接口，返回客服当前输入状态给用户.
  """
  @spec typing(WeChat.client(), WeChat.openid(), is_typing :: boolean) :: WeChat.response()
  def typing(client, openid, is_typing \\ true) do
    command = if(is_typing, do: "Typing", else: "CancelTyping")

    client.post(
      "/cgi-bin/message/custom/typing",
      json_map(touser: openid, command: command),
      query: [access_token: client.get_access_token()]
    )
  end
end
