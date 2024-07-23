defmodule WeChat.MiniProgram.Security do
  @moduledoc """
  小程序 - 内容安全接口
  """
  import Jason.Helpers
  alias Tesla.Multipart

  @typedoc "媒体类型 1 => 音频; 2 => 图片"
  @type media_type_audio :: 1
  @type media_type_image :: 2
  @type media_type :: media_type_audio | media_type_image
  @typep url :: String.t()
  @typep file_path :: Path.t()

  @doc """
  图片检测
  - [官方文档](https://developers.weixin.qq.com/miniprogram/dev/framework/security.imgSecCheck.html){:target="_blank"}

  校验一张图片是否含有违法违规内容。详见: [内容安全解决方案](https://developers.weixin.qq.com/miniprogram/dev/framework/operation.html)

  应用场景举例

  - 图片智能鉴黄：涉及拍照的工具类应用(如美拍，识图类应用)用户拍照上传检测；电商类商品上架图片检测；媒体类用户文章里的图片检测等；
  - 敏感人脸识别：用户头像；媒体类用户文章里的图片检测；社交类用户上传的图片检测等。

  ** 频率限制：单个 appId 调用上限为 2000 次/分钟，200,000 次/天 （ 图片大小限制：1M **）
  """
  @spec img_check(WeChat.client(), file_path) :: WeChat.response()
  def img_check(client, file_path) do
    multipart =
      Multipart.new()
      |> Multipart.add_file(file_path, name: "media", detect_content_type: true)

    client.post("/wxa/img_sec_check", multipart, query: [access_token: client.get_access_token()])
  end

  @doc """
  图片/音频异步检测
  - [官方文档](https://developers.weixin.qq.com/miniprogram/dev/OpenApiDoc/sec-center/sec-check/mediaCheckAsync.html){:target="_blank"}

  异步校验图片/音频是否含有违法违规内容。

  应用场景举例

  - 语音风险识别：社交类用户发表的语音内容检测；
  - 图片智能鉴黄：涉及拍照的工具类应用(如美拍，识图类应用)用户拍照上传检测；电商类商品上架图片检测；媒体类用户文章里的图片检测等；
  - 敏感人脸识别：用户头像；媒体类用户文章里的图片检测；社交类用户上传的图片检测等。

  ** 频率限制：单个 appId 调用上限为 2000 次/分钟，200,000 次/天；文件大小限制：单个文件大小不超过10M **
  """
  @spec media_check_async(WeChat.client(), url, media_type) :: WeChat.response()
  def media_check_async(client, media_url, media_type \\ 2) do
    client.post(
      "/wxa/media_check_async",
      json_map(media_url: media_url, media_type: media_type),
      query: [access_token: client.get_access_token()]
    )
  end

  @doc """
  文本检测
  - [官方文档](https://developers.weixin.qq.com/miniprogram/dev/OpenApiDoc/sec-center/sec-check/msgSecCheck.html){:target="_blank"}

  检查一段文本是否含有违法违规内容。

  应用场景举例

  - 用户个人资料违规文字检测；
  - 媒体新闻类用户发表文章，评论内容检测；
  - 游戏类用户编辑上传的素材(如答题类小游戏用户上传的问题及答案)检测等。

  ** 频率限制：单个 appId 调用上限为 4000 次/分钟，2,000,000 次/天 **
  """
  @spec msg_check(WeChat.client(), content :: String.t()) :: WeChat.response()
  def msg_check(client, content) do
    client.post(
      "/wxa/msg_sec_check",
      json_map(content: content),
      query: [access_token: client.get_access_token()]
    )
  end
end
