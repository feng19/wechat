defmodule WeChat.Material.Article do
  @moduledoc "文章"

  @typedoc """
  | argument            | 是否必须 | 说明 |
  | ------------------- | ------ | --- |
  | title               | 是 | 标题 |
  | thumb_media_id      | 是 | 图文消息的封面图片素材id（必须是永久mediaID）|
  | author              | 否 | 作者 |
  | digest              | 否 | 图文消息的摘要，仅有单图文消息才有摘要，多图文此处为空。如果本字段为没有填写，则默认抓取正文前64个字。 |
  | show_cover_pic      | 是 | 是否显示封面，0为false，即不显示，1为true，即显示 |
  | content             | 是 | 图文消息的具体内容，支持HTML标签，必须少于2万字符，小于1M，且此处会去除JS,涉及图片url必须来源 "上传图文消息内的图片获取URL"接口获取。外部图片url将被过滤。 |
  | content_source_url  | 是 | 图文消息的原文地址，即点击“阅读原文”后的URL |
  | need_open_comment   | 否 | Uint32 是否打开评论，0不打开，1打开 |
  | only_fans_can_comment | 否 | Uint32 是否粉丝才可评论，0所有人可评论，1粉丝才可评论 |
  """
  @type t :: %__MODULE__{
          title: String.t(),
          thumb_media_id: WeChat.Material.media_id(),
          author: String.t(),
          digest: String.t(),
          show_cover_pic: integer,
          content: String.t(),
          content_source_url: String.t(),
          need_open_comment: integer(),
          only_fans_can_comment: integer()
        }

  defstruct [
    :title,
    :thumb_media_id,
    :author,
    :digest,
    {:show_cover_pic, 1},
    :content,
    {:content_source_url, ""},
    {:need_open_comment, 1},
    {:only_fans_can_comment, 1}
  ]
end
