defmodule WeChat.Work.Material do
  @moduledoc "素材管理"

  import Jason.Helpers
  alias WeChat.Work
  alias Tesla.Multipart

  @typedoc """
  素材的类型

    - `image` - 图片
    - `voice` - 语音
    - `video` - 视频
    - `file`  - 文件

  Support Type

    - atom :: [:image, :voice, :video, :file]
    - String.t :: ["image", "voice", "video", "file"]
  """
  @type material_type :: :image | :voice | :video | :file | String.t()
  @typedoc "媒体文件上传后获取的唯一标识"
  @type media_id :: String.t()
  @typep file_path :: Path.t()
  @typep filename :: String.t()
  @typep file_data :: binary

  upload_doc = """
  [官方文档](https://developer.work.weixin.qq.com/document/path/90253){:target="_blank"}

  素材上传得到media_id，该media_id仅三天内有效，
  media_id在同一企业内应用之间可以共享。
  """

  @doc """
  上传临时素材(文件路径) -
  #{upload_doc}
  """
  @spec upload(Work.client(), Work.agent(), material_type, file_path) :: WeChat.response()
  def upload(client, agent, type, file_path) do
    multipart =
      Multipart.new()
      |> Multipart.add_file(file_path, name: "media", detect_content_type: true)

    client.post("/cgi-bin/media/upload", multipart,
      query: [type: to_string(type), access_token: client.get_access_token(agent)]
    )
  end

  @doc """
  上传临时素材(文件内容) -
  #{upload_doc}
  """
  @spec upload(Work.client(), Work.agent(), material_type, filename, file_data) ::
          WeChat.response()
  def upload(client, agent, type, filename, file_data) do
    multipart =
      Multipart.new()
      |> Multipart.add_file_content(file_data, filename, name: "media", detect_content_type: true)

    client.post("/cgi-bin/media/upload", multipart,
      query: [type: to_string(type), access_token: client.get_access_token(agent)]
    )
  end

  upload_image_doc = """
  [官方文档](https://developer.work.weixin.qq.com/document/path/90256){:target="_blank"}

  上传图片得到图片URL，该URL永久有效

  返回的图片URL，仅能用于图文消息正文中的图片展示，或者给客户发送欢迎语等；若用于非企业微信环境下的页面，图片将被屏蔽。

  图片文件大小应在 5B ~ 2MB 之间, 每个企业每天最多可上传100张图片
  """

  @doc """
  上传图片(文件路径) -
  #{upload_image_doc}
  """
  @spec upload_image(Work.client(), Work.agent(), name :: String.t(), file_path) ::
          WeChat.response()
  def upload_image(client, agent, name, file_path) do
    multipart =
      Multipart.new()
      |> Multipart.add_file(file_path, name: name, detect_content_type: true)

    client.post("/cgi-bin/media/uploadimg", multipart,
      query: [access_token: client.get_access_token(agent)]
    )
  end

  @doc """
  上传图片(文件内容) -
  #{upload_image_doc}
  """
  @spec upload_image(Work.client(), Work.agent(), name :: String.t(), filename, file_data) ::
          WeChat.response()
  def upload_image(client, agent, name, filename, file_data) do
    multipart =
      Multipart.new()
      |> Multipart.add_file_content(file_data, filename, name: name, detect_content_type: true)

    client.post("/cgi-bin/media/uploadimg", multipart,
      query: [access_token: client.get_access_token(agent)]
    )
  end

  @doc """
  获取临时素材 -
  [官方文档](https://developer.work.weixin.qq.com/document/path/90254){:target="_blank"}
  """
  @spec get(Work.client(), Work.agent(), media_id) :: WeChat.response()
  def get(client, agent, media_id) do
    client.get("/cgi-bin/media/get",
      query: [access_token: client.get_access_token(agent), media_id: media_id]
    )
  end

  @doc """
  获取高清语音素材 -
  [官方文档](https://developer.work.weixin.qq.com/document/path/90255){:target="_blank"}

  可以使用本接口获取从JSSDK的uploadVoice接口上传的临时语音素材，格式为speex，16K采样率。
  该音频比上文的临时素材获取接口（格式为amr，8K采样率）更加清晰，适合用作语音识别等对音质要求较高的业务。
  """
  @spec get_hd_voice(Work.client(), Work.agent(), media_id) :: WeChat.response()
  def get_hd_voice(client, agent, media_id) do
    client.get("/cgi-bin/media/get/jssdk",
      query: [access_token: client.get_access_token(agent), media_id: media_id]
    )
  end

  @doc """
  生成异步上传任务 -
  [官方文档](https://developer.work.weixin.qq.com/document/path/96219){:target="_blank"}

  为了满足临时素材的大文件诉求（最高支持200M），支持指定文件的CDN链接（必须支持Range分块下载），
  由企微微信后台异步下载和处理，处理完成后回调通知任务完成，再通过接口主动查询任务结果。

  跟普通临时素材一样，media_id仅三天内有效，media_id在同一企业内应用之间可以共享。
  """
  @spec upload_by_url(
          Work.client(),
          Work.agent(),
          type :: :video | :file | String.t(),
          filename,
          url :: String.t(),
          md5 :: String.t()
        ) :: WeChat.response()
  def upload_by_url(client, agent, type, filename, url, md5) do
    client.post(
      "/cgi-bin/media/upload_by_url",
      json_map(scene: 1, type: type, filename: filename, url: url, md5: md5),
      query: [access_token: client.get_access_token(agent)]
    )
  end
end
