defmodule WeChat.Material.Article do
  @moduledoc "文章"

  @typedoc """
  是否显示封面

  - `0`: 不显示
  - `1`: 显示
  """
  @type show_cover_pic :: 0 | 1
  @typedoc """
  是否打开评论

  - `0`: 不打开
  - `1`: 打开
  """
  @type need_open_comment :: 0 | 1
  @typedoc """
  是否粉丝才可评论

  - `0`: 所有人可评论
  - `1`: 粉丝才可评论
  """
  @type only_fans_can_comment :: 0 | 1
  @typedoc "作者"
  @type author :: String.t()
  @typedoc "图文消息的标题"
  @type title :: String.t()
  @typedoc "图文消息的摘要"
  @type digest :: String.t()
  @typedoc "图文消息的具体内容"
  @type content :: String.t()
  @typedoc "图文消息的原文地址，即点击“阅读原文”后的URL"
  @type content_source_url :: String.t()
  @typedoc """
  图文消息的封面图片素材id

  请通过接口 新增临时素材(`WeChat.Material.upload_media/3`) 获取
  """
  @type thumb_media_id :: String.t()
  @typedoc """
  | argument            | 是否必须 | 说明 |
  | ------------------- | ------ | --- |
  | title               | 是 | 标题 |
  | thumb_media_id      | 是 | 图文消息的封面图片素材id |
  | author              | 否 | 作者 |
  | digest              | 否 | 图文消息的摘要，仅有单图文消息才有摘要，多图文此处为空。如果本字段为没有填写，则默认抓取正文前64个字。 |
  | content             | 是 | 图文消息的具体内容，支持HTML标签，必须少于2万字符，小于1M，且此处会去除JS,涉及图片url必须来源 "上传图文消息内的图片获取URL"接口获取。外部图片url将被过滤。 |
  | content_source_url  | 否 | 图文消息的原文地址，即点击“阅读原文”后的URL |
  | show_cover_pic      | 否 | 是否显示封面，1为显示，0为不显示 |
  | need_open_comment   | 否 | Uint32 是否打开评论，0不打开，1打开 |
  | only_fans_can_comment | 否 | Uint32 是否粉丝才可评论，0所有人可评论，1粉丝才可评论 |
  """
  @type t :: %__MODULE__{
          title: title,
          thumb_media_id: thumb_media_id,
          digest: digest,
          author: author,
          content: content,
          content_source_url: content_source_url,
          show_cover_pic: show_cover_pic,
          need_open_comment: need_open_comment,
          only_fans_can_comment: only_fans_can_comment
        }

  @derive Jason.Encoder
  defstruct [
    :title,
    :thumb_media_id,
    :author,
    :digest,
    :content,
    {:content_source_url, ""},
    {:show_cover_pic, 1},
    {:need_open_comment, 1},
    {:only_fans_can_comment, 1}
  ]
end
