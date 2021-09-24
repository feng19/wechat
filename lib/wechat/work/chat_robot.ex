defmodule WeChat.Work.ChatRobot do
  @moduledoc """
  群机器人

  在终端某个群组添加机器人之后，创建者可以在机器人详情页看的该机器人特有的webhookurl。
  开发者可以按以下说明a向这个地址发起HTTP POST 请求，即可实现给该群组发送消息。

  当前自定义机器人支持文本（text）、markdown（markdown）、图片（image）、图文（news）四种消息类型。

  机器人的text/markdown类型消息支持在content中使用<@userid>扩展语法来@群成员

  消息发送频率限制: 每个机器人发送的消息不能超过20条/分钟。
  """

  import WeChat.Utils, only: [work_doc_link_prefix: 0, default_adapter: 0]
  alias Tesla.Multipart

  @doc_link "#{work_doc_link_prefix()}/90136/91770"

  @type webhook_url :: String.t()
  @typedoc "调用接口凭证, 机器人webhookurl中的key参数"
  @type key :: String.t()
  @typedoc """
  消息类型

  - `text`: 文本消息
  - `image`: 图片消息
  - `file`: 文件消息
  - `news`: 图文消息
  - `markdown`: markdown消息
  - `template_card`: 模板卡片消息
  """
  @type msg_type :: String.t()
  @type msg :: map
  @type content :: String.t()
  @type opts :: Enumerable.t()
  @typedoc "文件id，通过文件上传接口获取"
  @type media_id :: String.t()
  @typep file_path :: Path.t()
  @typep filename :: String.t()
  @typep file_data :: binary

  @doc """
  发送消息 -
  [官方文档](#{@doc_link}#如何使用群机器人){:target="_blank"}
  """
  @spec send(webhook_url, msg_type, msg) :: Tesla.Env.result()
  def send(webhook_url, msg_type, msg) do
    Tesla.client([Tesla.Middleware.JSON, Tesla.Middleware.Logger], default_adapter())
    |> Tesla.post(webhook_url, %{"msgtype" => msg_type, msg_type => msg})
  end

  @doc """
  发送文本消息 - [官方文档](#{@doc_link}#文本类型){:target="_blank"}
  """
  @spec send_text(webhook_url, content, opts) :: WeChat.response()
  def send_text(webhook_url, content, opts \\ []) do
    send(webhook_url, "text", Map.new(opts) |> Map.put("content", content))
  end

  @doc """
  发送图片消息 - [官方文档](#{@doc_link}#图片类型){:target="_blank"}

  - `base64`: 图片内容的 `base64` 编码
  - `md5`: 图片内容（base64编码前）的 `md5` 值

  **注：图片（base64编码前）最大不能超过2M，支持JPG,PNG格式**
  """
  @spec send_image(webhook_url, base64 :: String.t(), md5 :: String.t()) :: WeChat.response()
  def send_image(webhook_url, base64, md5) do
    send(webhook_url, "image", %{"base64" => base64, "md5" => md5})
  end

  @spec send_image(webhook_url, image_data :: binary) :: WeChat.response()
  def send_image(webhook_url, image_data) do
    base64 = Base.encode64(image_data)
    md5 = :crypto.hash(:md5, image_data)
    send_image(webhook_url, base64, md5)
  end

  @doc """
  发送文件消息 - [官方文档](#{@doc_link}#文件类型){:target="_blank"}
  """
  @spec send_file(webhook_url, Material.media_id()) :: WeChat.response()
  def send_file(webhook_url, media_id) do
    send(webhook_url, "file", %{"media_id" => media_id})
  end

  @doc """
  发送图文消息 - [官方文档](#{@doc_link}#图文类型){:target="_blank"}
  """
  @spec send_news(webhook_url, msg) :: WeChat.response()
  def send_news(webhook_url, msg) do
    send(webhook_url, "news", msg)
  end

  @doc """
  发送markdown消息 - [官方文档](#{@doc_link}#markdown类型){:target="_blank"}
  """
  @spec send_markdown(webhook_url, content) :: WeChat.response()
  def send_markdown(webhook_url, content) do
    send(webhook_url, "markdown", %{"content" => content})
  end

  @doc """
  发送模板卡片消息 - [官方文档](#{@doc_link}#模板卡片类型){:target="_blank"}
  """
  @spec send_template_card(webhook_url, msg) :: WeChat.response()
  def send_template_card(webhook_url, msg) do
    send(webhook_url, "template_card", msg)
  end

  @doc """
  文件上传接口 -
  [官方文档](#{@doc_link}#文件上传接口){:target="_blank"}
  """
  @spec upload_file(key, file_path) :: Tesla.Env.result()
  def upload_file(key, file_path) do
    Multipart.new()
    |> Multipart.add_file(file_path, name: "media", detect_content_type: true)
    |> _upload_file(key)
  end

  @doc """
  文件上传接口 -
  [官方文档](#{@doc_link}#文件上传接口){:target="_blank"}
  """
  @spec upload_file(key, filename, file_data) :: Tesla.Env.result()
  def upload_file(key, filename, file_data) do
    Multipart.new()
    |> Multipart.add_file_content(file_data, filename, name: "media", detect_content_type: true)
    |> _upload_file(key)
  end

  defp _upload_file(multipart, key) do
    Tesla.client([Tesla.Middleware.DecodeJson, Tesla.Middleware.Logger], default_adapter())
    |> Tesla.post("https://qyapi.weixin.qq.com/cgi-bin/webhook/upload_media", multipart,
      query: [key: key, type: "file"]
    )
  end
end
