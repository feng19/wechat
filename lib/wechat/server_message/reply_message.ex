defmodule WeChat.ServerMessage.ReplyMessage do
  @moduledoc """
  被动回复消息

  [官方文档](https://developers.weixin.qq.com/doc/offiaccount/Message_Management/Passive_user_reply_message.html){:target="_blank"}
  """
  import WeChat.Utils, only: [doc_link_prefix: 0, work_doc_link_prefix: 0, def_eex: 2]

  @doc_link "#{doc_link_prefix()}/doc/offiaccount/Message_Management/Passive_user_reply_message.html"

  @doc """
  回包加密 -
  [官方文档](#{doc_link_prefix()}/doc/oplatform/Third-party_Platforms/Message_Encryption/Message_encryption_and_decryption.html)

  ```xml
  <xml>
    <Encrypt><![CDATA[encrypt_content]]></Encrypt>
    <MsgSignature><![CDATA[signature]]></MsgSignature>
    <TimeStamp>timestamp</TimeStamp>
    <Nonce><![CDATA[nonce]]></Nonce>
  </xml>
  ```
  """
  def_eex reply_msg(signature, nonce, timestamp, encrypt_content) do
    """
    <xml>
      <Encrypt><![CDATA[<%= encrypt_content %>]]></Encrypt>
      <MsgSignature><![CDATA[<%= signature %>]]></MsgSignature>
      <TimeStamp><%= timestamp %></TimeStamp>
      <Nonce><![CDATA[<%= nonce %>]]></Nonce>
    </xml>
    """
  end

  @doc """
  回复文本消息 -
  [官方文档](#{@doc_link}#0){:target="_blank"}

  ```xml
  <xml>
    <ToUserName><![CDATA[toUser]]></ToUserName>
    <FromUserName><![CDATA[fromUser]]></FromUserName>
    <CreateTime>12345678</CreateTime>
    <MsgType>text></MsgType>
    <Content><![CDATA[你好]]></Content>
  </xml>
  ```
  """
  def_eex reply_text(to_openid, from_wx_no, timestamp, content) do
    """
    <xml>
      <ToUserName><![CDATA[<%= to_openid %>]]></ToUserName>
      <FromUserName><![CDATA[<%= from_wx_no %>]]></FromUserName>
      <CreateTime><%= timestamp %></CreateTime>
      <MsgType>text</MsgType>
      <Content><![CDATA[<%= content %>]]></Content>
    </xml>
    """
  end

  @doc """
  回复图片消息 -
  [官方文档](#{@doc_link}#1){:target="_blank"}

  ```xml
  <xml>
    <ToUserName><![CDATA[toUser]]></ToUserName>
    <FromUserName><![CDATA[fromUser]]></FromUserName>
    <CreateTime>12345678</CreateTime>
    <MsgType>image</MsgType>
    <Image>
      <MediaId><![CDATA[media_id]]></MediaId>
    </Image>
  </xml>
  ```
  """
  def_eex reply_image(to_openid, from_wx_no, timestamp, media_id) do
    """
    <xml>
      <ToUserName><![CDATA[<%= to_openid %>]]></ToUserName>
      <FromUserName><![CDATA[<%= from_wx_no %>]]></FromUserName>
      <CreateTime><%= timestamp %></CreateTime>
      <MsgType>image</MsgType>
      <Image>
        <MediaId><![CDATA[<%= media_id %>]]></MediaId>
      </Image>
    </xml>
    """
  end

  @doc """
  回复语音消息 -
  [官方文档](#{@doc_link}#2){:target="_blank"}

  ```xml
  <xml>
    <ToUserName><![CDATA[toUser]]></ToUserName>
    <FromUserName><![CDATA[fromUser]]></FromUserName>
    <CreateTime>12345678</CreateTime>
    <MsgType>voice</MsgType>
    <Voice>
      <MediaId><![CDATA[media_id]]></MediaId>
    </Voice>
  </xml>
  ```
  """
  def_eex reply_voice(to_openid, from_wx_no, timestamp, media_id) do
    """
    <xml>
      <ToUserName><![CDATA[<%= to_openid %>]]></ToUserName>
      <FromUserName><![CDATA[<%= from_wx_no %>]]></FromUserName>
      <CreateTime><%= timestamp %></CreateTime>
      <MsgType>voice</MsgType>
      <Voice>
        <MediaId><![CDATA[<%= media_id %>]]></MediaId>
      </Voice>
    </xml>
    """
  end

  @doc """
  回复视频消息 -
  [官方文档](#{@doc_link}#3){:target="_blank"}

  ```xml
  <xml>
    <ToUserName><![CDATA[toUser]]></ToUserName>
    <FromUserName><![CDATA[fromUser]]></FromUserName>
    <CreateTime>12345678</CreateTime>
    <MsgType>video</MsgType>
    <Video>
      <MediaId><![CDATA[media_id]]></MediaId>
      <Title><![CDATA[title]]></Title>
      <Description><![CDATA[description]]></Description>
    </Video>
  </xml>
  ```
  """
  def_eex reply_video(to_openid, from_wx_no, timestamp, media_id, title, desc) do
    """
    <xml>
      <ToUserName><![CDATA[<%= to_openid %>]]></ToUserName>
      <FromUserName><![CDATA[<%= from_wx_no %>]]></FromUserName>
      <CreateTime><%= timestamp %></CreateTime>
      <MsgType>video</MsgType>
      <Video>
        <MediaId><![CDATA[<%= media_id %>]]></MediaId>
        <Title><![CDATA[<%= title %>]]></Title>
        <Description><![CDATA[<%= desc %>]]></Description>
      </Video>
    </xml>
    """
  end

  @doc """
  回复音乐消息 -
  [官方文档](#{@doc_link}#4){:target="_blank"}

  ```xml
  <xml>
    <ToUserName><![CDATA[toUser]]></ToUserName>
    <FromUserName><![CDATA[fromUser]]></FromUserName>
    <CreateTime>12345678</CreateTime>
    <MsgType>music</MsgType>
    <Music>
      <Title><![CDATA[title]]></Title>
      <Description><![CDATA[description]]></Description>
      <MusicUrl><![CDATA[MUSIC_Url]]></MusicUrl>
      <HQMusicUrl><![CDATA[HQ_MUSIC_Url]]></HQMusicUrl>
      <ThumbMediaId><![CDATA[media_id]]></ThumbMediaId>
    </Music>
  </xml>
  ```
  """
  def_eex reply_music(
            to_openid,
            from_wx_no,
            timestamp,
            title,
            desc,
            music_url,
            hq_music_url,
            thumb_media_id
          ) do
    """
    <xml>
      <ToUserName><![CDATA[<%= to_openid %>]]></ToUserName>
      <FromUserName><![CDATA[<%= from_wx_no %>]]></FromUserName>
      <CreateTime><%= timestamp %></CreateTime>
      <MsgType>music</MsgType>
      <Music>
        <Title><![CDATA[<%= title %>]]></Title>
        <Description><![CDATA[<%= desc %>]]></Description>
        <MusicUrl><![CDATA[<%= music_url %>]]></MusicUrl>
        <HQMusicUrl><![CDATA[<%= hq_music_url %>]]></HQMusicUrl>
        <ThumbMediaId><![CDATA[<%= thumb_media_id %>]]></ThumbMediaId>
      </Music>
    </xml>
    """
  end

  @doc """
  回复图文消息 -
  [官方文档](#{@doc_link}#5){:target="_blank"}

  ```xml
  <xml>
    <ToUserName><![CDATA[toUser]]></ToUserName>
    <FromUserName><![CDATA[fromUser]]></FromUserName>
    <CreateTime>12345678</CreateTime>
    <MsgType>news</MsgType>
    <ArticleCount>1</ArticleCount>
    <Articles>
      <item>
        <Title><![CDATA[title1]]></Title>
        <Description><![CDATA[description1]]></Description>
        <PicUrl><![CDATA[picurl]]></PicUrl>
        <Url><![CDATA[url]]></Url>
      </item>
    </Articles>
  </xml>
  ```
  """
  def_eex reply_news(to_openid, from_wx_no, timestamp, article_items) do
    """
    <xml>
      <ToUserName><![CDATA[<%= to_openid %>]]></ToUserName>
      <FromUserName><![CDATA[<%= from_wx_no %>]]></FromUserName>
      <CreateTime><%= timestamp %></CreateTime>
      <MsgType>news</MsgType>
      <ArticleCount><%= length(article_items) %></ArticleCount>
      <Articles>
        <%= for article_item <- article_items do %>
        <item>
          <Title><![CDATA[<%= article_item.title %>]]></Title>
          <Description><![CDATA[<%= article_item.desc %>]]></Description>
          <PicUrl><![CDATA[<%= article_item.pic_url %>]]></PicUrl>
          <Url><![CDATA[<%= article_item.url %>]]></Url>
        </item>
        <% end %>
      </Articles>
    </xml>
    """
  end

  @doc """
  消息转发客服消息 -
  [官方文档](#{doc_link_prefix()}/doc/offiaccount/Customer_Service/Forwarding_of_messages_to_service_center.html){:target="_blank"}

  ```xml
  <xml>
    <ToUserName><![CDATA[touser]]></ToUserName>
    <FromUserName><![CDATA[fromuser]]></FromUserName>
    <CreateTime>1399197672</CreateTime>
    <MsgType>transfer_customer_service</MsgType>
  </xml>
  ```
  """
  def_eex transfer_customer_service(to_openid, from_wx_no, timestamp) do
    """
    <xml>
      <ToUserName><![CDATA[<%= to_openid %>]]></ToUserName>
      <FromUserName><![CDATA[<%= from_wx_no %>]]></FromUserName>
      <CreateTime><%= timestamp %></CreateTime>
      <MsgType>transfer_customer_service</MsgType>
    </xml>
    """
  end

  @doc """
  消息转发到指定客服 -
  [官方文档](#{doc_link_prefix()}/doc/offiaccount/Customer_Service/Forwarding_of_messages_to_service_center.html){:target="_blank"}

  ```xml
  <xml>
    <ToUserName><![CDATA[touser]]></ToUserName>
    <FromUserName><![CDATA[fromuser]]></FromUserName>
    <CreateTime>1399197672</CreateTime>
    <MsgType>transfer_customer_service</MsgType>
    <TransInfo>
      <KfAccount><![CDATA[test1@test]]></KfAccount>
    </TransInfo>
  </xml>
  ```
  """
  def_eex transfer_customer_service(to_openid, from_wx_no, timestamp, kf_account) do
    """
    <xml>
      <ToUserName><![CDATA[<%= to_openid %>]]></ToUserName>
      <FromUserName><![CDATA[<%= from_wx_no %>]]></FromUserName>
      <CreateTime><%= timestamp %></CreateTime>
      <MsgType>transfer_customer_service</MsgType>
      <TransInfo>
        <KfAccount><![CDATA[<%= kf_account %>]]></KfAccount>
      </TransInfo>
    </xml>
    """
  end

  @doc """
  模板卡片更新消息(更新点击用户的按钮点击文案) -
  [官方文档](#{work_doc_link_prefix()}/90135/90241#模板卡片更新消息){:target="_blank"}

  ```xml
  <xml>
    <ToUserName><![CDATA[toUser]]></ToUserName>
    <FromUserName><![CDATA[fromUser]]></FromUserName>
    <CreateTime>1357290913</CreateTime>
    <MsgType>update_button</MsgType>
    <Button>
        <ReplaceName><![CDATA[ReplaceName]]></ReplaceName>
    </Button>
  </xml>
  ```
  """
  def_eex update_template_card_button(to_user, from_user, timestamp, replace_name) do
    """
    <xml>
    <ToUserName><![CDATA[<%= to_user %>]]></ToUserName>
    <FromUserName><![CDATA[<%= from_user %>]]></FromUserName>
    <CreateTime><%= timestamp %></CreateTime>
    <MsgType>update_button</MsgType>
    <Button>
        <ReplaceName><![CDATA[<%= replace_name %>]]></ReplaceName>
    </Button>
    </xml>
    """
  end

  @doc """
  模板卡片更新消息(更新点击用户的整张卡片) -
  [官方文档](#{work_doc_link_prefix()}/90135/90241#更新点击用户的整张卡片){:target="_blank"}

  ```xml
  <xml>
    <ToUserName><![CDATA[toUser]]></ToUserName>
    <FromUserName><![CDATA[fromUser]]></FromUserName>
    <CreateTime>1357290913</CreateTime>
    <MsgType>update_button</MsgType>
    template_card_xml
  </xml>
  ```
  """
  def_eex update_template_card(to_user, from_user, timestamp, template_card_xml) do
    """
    <xml>
    <ToUserName><![CDATA[<%= to_user %>]]></ToUserName>
    <FromUserName><![CDATA[<%= from_user %>]]></FromUserName>
    <CreateTime><%= timestamp %></CreateTime>
    <MsgType>update_template_card</MsgType>
    <%= template_card_xml %>
    </xml>
    """
  end

  def biz_msg_menu(show_text, reply_text \\ nil, id \\ 0) do
    reply_text = reply_text || show_text

    "<a href=\"weixin://bizmsgmenu?msgmenucontent=#{reply_text}&msgmenuid=#{id}\">#{show_text}</a>"
  end
end
