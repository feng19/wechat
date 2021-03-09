defmodule WeChat.BatchSends do
  @moduledoc """
  消息管理 - 群发接口和原创效验

  [官方文档](https://developers.weixin.qq.com/doc/offiaccount/Message_Management/Batch_Sends_and_Originality_Checks.html){:target="_blank"}

  在公众平台网站上，为订阅号提供了每天一条的群发权限，为服务号提供每月（自然月）`4` 条的群发权限。
  而对于某些具备开发能力的公众号运营者，可以通过高级群发接口，实现更灵活的群发能力。

  请注意：

  1. 对于认证订阅号，群发接口每天可成功调用 `1` 次，此次群发可选择发送给全部用户或某个标签；
  2. 对于认证服务号虽然开发者使用高级群发接口的每日调用限制为 `100` 次，但是用户每月只能接收 `4` 条，无论在公众平台网站上，还是使用接口群发，
  用户每月只能接收 `4` 条群发消息，多于 `4` 条的群发将对该用户发送失败；
  3. 开发者可以使用预览接口校对消息样式和排版，通过预览接口可发送编辑好的消息给指定用户校验效果；
  4. 群发过程中，微信后台会自动进行图文消息原创校验，请提前设置好相关参数(`send_ignore` 等)；
  5. 开发者可以主动设置 `clientmsgid` 来避免重复推送。
  6. 群发接口每分钟限制请求 `60` 次，超过限制的请求会被拒绝。
  7. 图文消息正文中插入自己帐号和其他公众号已群发文章链接的能力。
  8. 对于已开启API群发保护的账号，群发全部用户时需要等待管理员进行确认，如管理员拒绝或30分钟内没有确认，该次群发失败。
  用户可通过“设置-安全中心-风险操作保护”中关闭API群发保护功能。

  群发图文消息的过程如下：

  1. 首先，预先将图文消息中需要用到的图片，使用上传图文消息内图片接口，上传成功并获得图片 URL；
  2. 上传图文消息素材，需要用到图片时，请使用上一步获取的图片 URL；
  3. 使用对用户标签的群发，或对 `OpenID` 列表的群发，将图文消息群发出去，群发时微信会进行原创校验，并返回群发操作结果；
  4. 在上述过程中，如果需要，还可以预览图文消息、查询群发状态，或删除已群发的消息等。

  群发图片、文本等其他消息类型的过程如下：

  1. 如果是群发文本消息，则直接根据下面的接口说明进行群发即可；
  2. 如果是群发图片、视频等消息，则需要预先通过素材管理接口准备好 `mediaID`。

  关于群发时使用 `is_to_all` 为 `true` 使其进入公众号在微信客户端的历史消息列表：

  1. 使用 `is_to_all` 为 `true` 且成功群发，会使得此次群发进入历史消息列表。
  2. 为防止异常，认证订阅号在一天内，只能使用 `is_to_all` 为true进行群发一次，或者在公众平台官网群发（不管本次群发是对全体还是对某个分组）一次。
  以避免一天内有2条群发进入历史消息列表。
  3. 类似地，服务号在一个月内，使用 `is_to_all` 为 `true` 群发的次数，加上公众平台官网群发（不管本次群发是对全体还是对某个分组）的次数，最多只能是 `4` 次。
  4. 设置 `is_to_all` 为 `false` 时是可以多次群发的，但每个用户只会收到最多4条，且这些群发不会进入历史消息列表。
  另外，请开发者注意，本接口中所有使用到 `media_id` 的地方，现在都可以使用素材管理中的永久素材 `media_id` 了。
  请但注意，使用同一个素材群发出去的链接是一样的，这意味着，删除某一次群发，会导致整个链接失效。

  ## 群发前的原创校验

  群发接口新增原创校验流程

  开发者调用群发接口进行图文消息的群发时，微信会将开发者准备群发的文章，与公众平台原创库中的文章进行比较，校验结果分为以下几种：

    - 当前准备群发的文章，未命中原创库中的文章，则可以群发。
    - 当前准备群发的文章，已命中原创库中的文章，则：

      - 若原创作者允许转载该文章，则可以进行群发。群发时，会自动替换成原文的样式，且会自动将文章注明为转载并显示来源。

        若希望修改原文内容或样式，或群发时不显示转载来源，可自行与原创公众号作者联系并获得授权之后再进行群发。

      - 若原创作者禁止转载该文章，则不能进行群发。

        若希望转载该篇文章，可自行与原创公众号作者联系并获得授权之后再进行群发。

  群发操作的相关返回码，可以参考全局返回码说明文档。
  """
  import Jason.Helpers
  import WeChat.Utils, only: [doc_link_prefix: 0]

  @doc_link "#{doc_link_prefix()}/doc/offiaccount/Message_Management/Batch_Sends_and_Originality_Checks.html"

  @typedoc """
  图文消息的接收者，

  一串OpenID列表，OpenID最少2个，最多10000个
  """
  @type openid_list :: WeChat.openid_list()
  @typedoc "消息发送任务的ID"
  @type msg_id :: String.t()
  @typedoc """
  要删除的文章在图文消息中的位置

  第一篇编号为1，该字段不填或填0会删除全部文章
  """
  @type article_idx :: non_neg_integer
  @typedoc """
  群发的消息类型

  - 图文消息: `mpnews`
  - 文本消息: `text`
  - 语音: `voice`
  - 音乐: `music`
  - 图片: `image`
  - 视频: `video`
  - 卡券: `wxcard`
  """
  @type msg_type :: :mpnews | :text | :voice | :image | :mpvideo | :wxcard | String.t()
  @typedoc """
  图文消息 - `mpnews`

  `media_id` 请从 上传图文消息素材（`WeChat.Material.upload_news/2`） 接口中获取
  """
  @type news_object :: %{media_id: WeChat.Material.media_id()}
  @typedoc "文本 - `text`"
  @type text_object :: %{content: String.t()}
  @typedoc """
  语音/音频 - `voice`

  `media_id` 请从 素材管理 -> 新增素材（`WeChat.Material.add_material/3`） 接口中获取
  """
  @type voice_object :: %{media_id: WeChat.Material.media_id()}
  @typedoc "推荐语，不填则默认为“分享图片”"
  @type recommend :: String.t()
  @typedoc """
  图片 - `image`

  `media_id` 请从 素材管理 -> 新增素材（`WeChat.Material.add_material/3`） 接口中获取
  """
  @type image_object :: %{
          media_ids: [WeChat.Material.media_id()],
          recommend: recommend,
          need_open_comment: WeChat.Article.need_open_comment(),
          only_fans_can_comment: WeChat.Article.only_fans_can_comment()
        }
  @typedoc """
  视频 - `mpvideo`

  `media_id` 请从 `WeChat.Material.upload_video/4` 接口中获取
  """
  @type video_object :: %{
          required(:media_id) => WeChat.Material.media_id(),
          optional(:title) => String.t(),
          optional(:description) => String.t()
        }
  @typedoc "卡券消息 - `wxcard`"
  @type card_object :: %{
          required(:card_id) => WeChat.Card.card_id(),
          optional(:card_ext) => WeChat.WebPage.card_ext()
        }
  @type object ::
          news_object | text_object | video_object | image_object | video_object | card_object
  @typedoc """
  用于设定是否向全部用户发送

  值为true或false，选择true该消息群发给所有用户
  选择false可根据tag_id发送给指定群组的用户
  """
  @type is_to_all :: boolean
  @typedoc """
  群发到的标签的tag_id

  参见用户管理中用户分组接口，若is_to_all值为true，可不填写tag_id
  """
  @type tag_id :: non_neg_integer
  @typedoc "用于设定图文消息的接收者"
  @type filter :: %{required(:is_to_all) => is_to_all, optional(:tag_id) => tag_id}
  @typedoc """
  图文消息被判定为转载时，是否继续群发

  - 当 `send_ignore_reprint` 参数设置为1时，文章被判定为转载时，且原创文允许转载时，将继续进行群发操作。
  - 当 `send_ignore_reprint` 参数设置为0时，文章被判定为转载时，将停止群发操作。

  默认为: `0`
  """
  @type send_ignore_reprint :: 0 | 1
  @type batch_send_by_tag_body :: %{
          required(:filter) => filter,
          required(:msgtype) => msg_type,
          optional(:mpnews) => news_object,
          optional(:text) => text_object,
          optional(:voice) => voice_object,
          optional(:images) => image_object,
          optional(:mpvideo) => video_object,
          optional(:wxcard) => card_object,
          optional(:send_ignore_reprint) => send_ignore_reprint
        }
  @type batch_send_by_list_body :: %{
          required(:touser) => openid_list,
          required(:msgtype) => msg_type,
          optional(:mpnews) => news_object,
          optional(:text) => text_object,
          optional(:voice) => voice_object,
          optional(:images) => image_object,
          optional(:mpvideo) => video_object,
          optional(:wxcard) => card_object,
          optional(:send_ignore_reprint) => send_ignore_reprint
        }
  @type preview_body :: %{
          required(:touser) => WeChat.openid(),
          required(:msgtype) => msg_type,
          optional(:mpnews) => news_object,
          optional(:text) => text_object,
          optional(:voice) => voice_object,
          optional(:images) => image_object,
          optional(:mpvideo) => video_object,
          optional(:wxcard) => card_object
        }

  @doc """
  根据标签进行群发【订阅号与服务号认证后均可用】 -
  [官方文档](#{@doc_link}#2){:target="_blank"}
  """
  @spec batch_send_by_tag(WeChat.client(), batch_send_by_tag_body) :: WeChat.response()
  def batch_send_by_tag(client, batch_send_by_tag_body) do
    client.post("/cgi-bin/message/mass/sendall", batch_send_by_tag_body,
      query: [access_token: client.get_access_token()]
    )
  end

  @doc """
  根据OpenID列表群发【订阅号不可用，服务号认证后可用】 -
  [官方文档](#{@doc_link}#3){:target="_blank"}
  """
  @spec batch_send_by_list(WeChat.client(), batch_send_by_list_body) :: WeChat.response()
  def batch_send_by_list(client, batch_send_by_list_body) do
    client.post("/cgi-bin/message/mass/send", batch_send_by_list_body,
      query: [access_token: client.get_access_token()]
    )
  end

  @doc """
  删除群发【订阅号与服务号认证后均可用】 -
  [官方文档](#{@doc_link}#4){:target="_blank"}

  群发之后，随时可以通过该接口删除群发。

  ## 请注意

  1. 只有已经发送成功的消息才能删除
  2. 删除消息是将消息的图文详情页失效，已经收到的用户，还是能在其本地看到消息卡片。
  3. 删除群发消息只能删除图文消息和视频消息，其他类型的消息一经发送，无法删除。
  4. 如果多次群发发送的是一个图文消息，那么删除其中一次群发，就会删除掉这个图文消息也，导致所有群发都失效
  """
  @spec delete(WeChat.client(), msg_id, article_idx) :: WeChat.response()
  def delete(client, msg_id, article_idx \\ 0) do
    client.post(
      "/cgi-bin/message/mass/delete",
      json_map(msg_id: msg_id, article_idx: article_idx),
      query: [access_token: client.get_access_token()]
    )
  end

  @doc """
  预览接口【订阅号与服务号认证后均可用】 -
  [官方文档](#{@doc_link}#5){:target="_blank"}

  开发者可通过该接口发送消息给指定用户，在手机端查看消息的样式和排版。

  为了满足第三方平台开发者的需求，在保留对openID预览能力的同时，增加了对指定微信号发送预览的能力，但该能力每日调用次数有限制（100次），请勿滥用。
  """
  @spec preview(WeChat.client(), preview_body) :: WeChat.response()
  def preview(client, preview_body) do
    client.post("/cgi-bin/message/mass/preview", preview_body,
      query: [access_token: client.get_access_token()]
    )
  end

  @doc """
  查询群发消息发送状态【订阅号与服务号认证后均可用】 -
  [官方文档](#{@doc_link}#5){:target="_blank"}

  开发者可通过该接口发送消息给指定用户，在手机端查看消息的样式和排版。

  为了满足第三方平台开发者的需求，在保留对openID预览能力的同时，增加了对指定微信号发送预览的能力，但该能力每日调用次数有限制（100次），请勿滥用。
  """
  @spec get(WeChat.client(), msg_id) :: WeChat.response()
  def get(client, msg_id) do
    client.post("/cgi-bin/message/mass/get", json_map(msg_id: msg_id),
      query: [access_token: client.get_access_token()]
    )
  end

  @doc """
  群发速度 - 获取 -
  [官方文档](#{@doc_link}#9){:target="_blank"}
  """
  @spec get_speed(WeChat.client()) :: WeChat.response()
  def get_speed(client) do
    client.get("/cgi-bin/message/mass/speed/get",
      query: [access_token: client.get_access_token()]
    )
  end

  @doc """
  群发速度 - 设置 -
  [官方文档](#{@doc_link}#9){:target="_blank"}

  群发速度的级别，是一个0到4的整数，数字越大表示群发速度越慢。

  speed 与 realspeed 的关系如下：

  | speed | realspeed |
  | ----- | --------- |
  | 0 | 80w/分钟 |
  | 1 | 60w/分钟 |
  | 2 | 45w/分钟 |
  | 3 | 30w/分钟 |
  | 4 | 10w/分钟 |
  """
  @spec set_speed(WeChat.client(), speed :: integer) :: WeChat.response()
  def set_speed(client, speed) do
    client.post("/cgi-bin/message/mass/speed/set", json_map(speed: speed),
      query: [access_token: client.get_access_token()]
    )
  end
end
