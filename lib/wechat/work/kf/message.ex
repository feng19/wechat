defmodule WeChat.Work.KF.Message do
  @moduledoc "客服消息"

  import Jason.Helpers
  alias WeChat.Work
  alias WeChat.Work.Message, as: Msg
  alias Work.KF.Account

  @typedoc """
  消息类型

  - `text`: 文本消息
  - `image`: 图片消息
  - `voice`: 语音消息
  - `video`: 视频消息
  - `file`: 文件消息
  - `link`: 图文链接消息
  - `miniprogram`: 小程序消息
  - `msgmenu`: 菜单消息
  - `location`: 地理位置消息
  """
  @type msg_type :: String.t()
  @typedoc """
  事件响应消息类型

  目前支持文本与菜单消息

  - `text`: 文本消息
  - `msgmenu`: 菜单消息
  """
  @type on_event_msg_type :: String.t()
  @typedoc """
  事件响应消息对应的code。

  通过事件回调下发，仅可使用一次。
  """
  @type code :: String.t()
  @type content :: String.t()
  @type msg :: map
  @type opts :: Enumerable.t()
  @typedoc """
  消息ID。如果请求参数指定了msgid，则原样返回，否则系统自动生成并返回。
  不多于32字节
  字符串取值范围(正则表达式)：[0-9a-zA-Z_-]*
  """
  @type msg_id :: String.t()

  @doc """
  获取消息 -
  [官方文档](https://developer.work.weixin.qq.com/document/path/94670#读取消息){:target="_blank"}

  客户主动发给微信客服的消息、发送消息接口发送失败事件（如被用户拒收）、客户点击菜单消息的回复消息，可以通过该接口获取具体的消息内容和事件。不支持获取通过接口发送的消息。

  **支持的消息类型**：文本、图片、语音、视频、文件、位置、事件。
  """
  @spec sync_msg(Work.client(), Work.agent(), opts :: Enumerable.t()) :: WeChat.response()
  def sync_msg(client, agent, opts) do
    client.post("/cgi-bin/kf/sync_msg", Map.new(opts),
      query: [access_token: client.get_access_token(agent)]
    )
  end

  @doc """
  发送消息 -
  [官方文档](https://developer.work.weixin.qq.com/document/path/94677){:target="_blank"}

  当用户在主动发送消息给微信客服时，企业可在48小时内调用该接口发送消息给用户，最多可发送5条消息给客户；若用户继续发送消息，企业可再次下发消息。
  支持发送消息类型：文本、图片、语音、视频、文件、图文、小程序、菜单消息、地理位置。
  目前该接口允许下发消息条数和下发时限如下：

  | 用户动作     | 允许下发条数限制 | 下发时限 |
  | ------------ | ---------------- | -------- |
  | 用户发送消息 | 5条              | 48 小时  |
  """
  @spec send_message(Work.client(), Work.agent(), body :: map) :: WeChat.response()
  def send_message(client, agent, body) do
    client.post("/cgi-bin/kf/send_msg", body,
      query: [access_token: client.get_access_token(agent)]
    )
  end

  @spec send_message(
          Work.client(),
          Work.agent(),
          WeChat.openid(),
          Account.open_kfid(),
          Msg.msg_type(),
          Msg.msg(),
          opts
        ) :: WeChat.response()
  def send_message(client, agent, to_openid, open_kfid, msg_type, msg, opts \\ []) do
    body =
      Map.new(opts)
      |> Map.merge(%{
        "touser" => to_openid,
        "open_kfid" => open_kfid,
        "msgtype" => msg_type,
        msg_type => msg
      })

    send_message(client, agent, body)
  end

  @doc """
  发送文本消息 -
  [官方文档](https://developer.work.weixin.qq.com/document/path/94677#文本消息){:target="_blank"}
  """
  @spec send_text(
          Work.client(),
          Work.agent(),
          WeChat.openid(),
          Account.open_kfid(),
          content,
          opts
        ) :: WeChat.response()
  def send_text(client, agent, to_openid, open_kfid, content, opts \\ []) do
    send_message(client, agent, to_openid, open_kfid, "text", %{"content" => content}, opts)
  end

  @doc """
  发送图片消息 -
  [官方文档](https://developer.work.weixin.qq.com/document/path/94677#图片消息){:target="_blank"}
  """
  @spec send_image(
          Work.client(),
          Work.agent(),
          WeChat.openid(),
          Account.open_kfid(),
          Material.media_id(),
          opts
        ) :: WeChat.response()
  def send_image(client, agent, to_openid, open_kfid, media_id, opts \\ []) do
    send_message(client, agent, to_openid, open_kfid, "image", %{"media_id" => media_id}, opts)
  end

  @doc """
  发送语音消息 -
  [官方文档](https://developer.work.weixin.qq.com/document/path/94677#语音消息){:target="_blank"}
  """
  @spec send_voice(
          Work.client(),
          Work.agent(),
          WeChat.openid(),
          Account.open_kfid(),
          Material.media_id(),
          opts
        ) :: WeChat.response()
  def send_voice(client, agent, to_openid, open_kfid, media_id, opts \\ []) do
    send_message(client, agent, to_openid, open_kfid, "voice", %{"media_id" => media_id}, opts)
  end

  @doc """
  发送视频消息 -
  [官方文档](https://developer.work.weixin.qq.com/document/path/94677#视频消息){:target="_blank"}
  """
  @spec send_video(
          Work.client(),
          Work.agent(),
          WeChat.openid(),
          Account.open_kfid(),
          Material.media_id(),
          title :: String.t(),
          description :: String.t(),
          opts
        ) :: WeChat.response()
  def send_video(client, agent, to_openid, open_kfid, media_id, title, description, opts \\ []) do
    msg = %{
      "media_id" => media_id,
      "title" => title,
      "description" => description
    }

    send_message(client, agent, to_openid, open_kfid, "video", msg, opts)
  end

  @doc """
  发送文件消息 -
  [官方文档](https://developer.work.weixin.qq.com/document/path/94677#文件消息){:target="_blank"}
  """
  @spec send_file(
          Work.client(),
          Work.agent(),
          WeChat.openid(),
          Account.open_kfid(),
          Material.media_id(),
          opts
        ) :: WeChat.response()
  def send_file(client, agent, to_openid, open_kfid, media_id, opts \\ []) do
    send_message(client, agent, to_openid, open_kfid, "file", %{"media_id" => media_id}, opts)
  end

  @doc """
  图文链接消息 -
  [官方文档](https://developer.work.weixin.qq.com/document/path/94677#图文链接消息){:target="_blank"}
  """
  @spec send_link(Work.client(), Work.agent(), WeChat.openid(), Account.open_kfid(), msg, opts) ::
          WeChat.response()
  def send_link(client, agent, to_openid, open_kfid, msg, opts \\ []) do
    send_message(client, agent, to_openid, open_kfid, "link", msg, opts)
  end

  @doc """
  小程序消息 -
  [官方文档](https://developer.work.weixin.qq.com/document/path/94677#小程序消息){:target="_blank"}
  """
  @spec send_mini_program(
          Work.client(),
          Work.agent(),
          WeChat.openid(),
          Account.open_kfid(),
          msg,
          opts
        ) :: WeChat.response()
  def send_mini_program(client, agent, to_openid, open_kfid, msg, opts \\ []) do
    send_message(client, agent, to_openid, open_kfid, "miniprogram", msg, opts)
  end

  @doc """
  菜单消息 -
  [官方文档](https://developer.work.weixin.qq.com/document/path/94677#菜单消息){:target="_blank"}
  """
  @spec send_menu(Work.client(), Work.agent(), WeChat.openid(), Account.open_kfid(), msg, opts) ::
          WeChat.response()
  def send_menu(client, agent, to_openid, open_kfid, msg, opts \\ []) do
    send_message(client, agent, to_openid, open_kfid, "msgmenu", msg, opts)
  end

  @doc """
  地理位置消息 -
  [官方文档](https://developer.work.weixin.qq.com/document/path/94677#地理位置消息){:target="_blank"}
  """
  @spec send_location(
          Work.client(),
          Work.agent(),
          WeChat.openid(),
          Account.open_kfid(),
          msg,
          opts
        ) :: WeChat.response()
  def send_location(client, agent, to_openid, open_kfid, msg, opts \\ []) do
    send_message(client, agent, to_openid, open_kfid, "location", msg, opts)
  end

  @doc """
  发送事件响应消息 -
  [官方文档](https://developer.work.weixin.qq.com/document/path/95122){:target="_blank"}

  当特定的事件回调消息包含code字段，可以此code为凭证，调用该接口给用户发送相应事件场景下的消息，如客服欢迎语。

  **支持发送消息类型**：文本、菜单消息。
  """
  @spec send_msg_on_event(Work.client(), Work.agent(), code, on_event_msg_type, msg, msg_id) ::
          WeChat.response()
  def send_msg_on_event(client, agent, code, on_event_msg_type, msg, msg_id \\ nil) do
    json =
      if msg_id do
        json_map(code: code, on_event_msg_type: on_event_msg_type, msg: msg, msg_id: msg_id)
      else
        json_map(code: code, on_event_msg_type: on_event_msg_type, msg: msg)
      end

    client.post("/cgi-bin/kf/send_msg_on_event", json,
      query: [access_token: client.get_access_token(agent)]
    )
  end

  @doc """
  发送事件响应消息[文本消息] -
  [官方文档](https://developer.work.weixin.qq.com/document/path/95122#文本消息){:target="_blank"}
  """
  @spec send_text_on_event(Work.client(), Work.agent(), code, content, msg_id) ::
          WeChat.response()
  def send_text_on_event(client, agent, code, content, msg_id \\ nil) do
    send_msg_on_event(client, agent, code, "text", %{"content" => content}, msg_id)
  end

  @doc """
  发送事件响应消息[菜单消息] -
  [官方文档](https://developer.work.weixin.qq.com/document/path/95122#菜单消息){:target="_blank"}
  """
  @spec send_menu_on_event(Work.client(), Work.agent(), code, msg, msg_id) :: WeChat.response()
  def send_menu_on_event(client, agent, code, msg, msg_id \\ nil) do
    send_msg_on_event(client, agent, code, "msgmenu", msg, msg_id)
  end
end
