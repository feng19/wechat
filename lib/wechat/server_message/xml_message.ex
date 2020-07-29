defmodule WeChat.ServerMessage.XmlMessage do
  @moduledoc """
  回复推送消息

  [API Docs Link](https://developers.weixin.qq.com/doc/offiaccount/Message_Management/Passive_user_reply_message.html){:target="_blank"}
  """
  import Saxy.XML
  import WeChat.Utils, only: [doc_link_prefix: 0]

  @doc_link "#{doc_link_prefix()}/doc/offiaccount/Message_Management/Passive_user_reply_message.html"

  @doc """
  回包加密 - [Official API Docs Link](#{doc_link_prefix()}/doc/oplatform/Third-party_Platforms/Message_Encryption/Message_encryption_and_decryption.html)

  ```xml
  <xml>
    <Encrypt><![CDATA[encrypt_content]]></Encrypt>
    <MsgSignature><![CDATA[signature]]></MsgSignature>
    <TimeStamp>timestamp</TimeStamp>
    <Nonce><![CDATA[nonce]]></Nonce>
  </xml>
  ```
  """
  def reply_msg(signature, nonce, timestamp, encrypt_content) do
    element("xml", [], [
      element("Encrypt", [], cdata(encrypt_content)),
      element("MsgSignature", [], cdata(signature)),
      element("TimeStamp", [], to_string(timestamp)),
      element("Nonce", [], cdata(nonce))
    ])
    |> Saxy.encode!(nil)
  end

  @doc """
  回复文本消息 - [Official API Docs Link](#{@doc_link}#0){:target="_blank"}

  ```xml
  <xml>
    <ToUserName><![CDATA[toUser]]></ToUserName>
    <FromUserName><![CDATA[fromUser]]></FromUserName>
    <CreateTime>12345678</CreateTime>
    <MsgType><![CDATA[text]]></MsgType>
    <Content><![CDATA[你好]]></Content>
  </xml>
  ```
  """
  def reply_text(to_openid, from_wx_no, timestamp, content) do
    element("xml", [], [
      element("ToUserName", [], cdata(to_openid)),
      element("FromUserName", [], cdata(from_wx_no)),
      element("CreateTime", [], to_string(timestamp)),
      element("MsgType", [], "text"),
      element("Content", [], cdata(content))
    ])
    |> Saxy.encode!(nil)
  end

  @doc """
  回复图片消息 - [Official API Docs Link](#{@doc_link}#1){:target="_blank"}

  ```xml
  <xml>
    <ToUserName><![CDATA[toUser]]></ToUserName>
    <FromUserName><![CDATA[fromUser]]></FromUserName>
    <CreateTime>12345678</CreateTime>
    <MsgType><![CDATA[image]]></MsgType>
    <Image>
      <MediaId><![CDATA[media_id]]></MediaId>
    </Image>
  </xml>
  ```
  """
  def reply_image(to_openid, from_wx_no, timestamp, media_id) do
    element("xml", [], [
      element("ToUserName", [], cdata(to_openid)),
      element("FromUserName", [], cdata(from_wx_no)),
      element("CreateTime", [], to_string(timestamp)),
      element("MsgType", [], "image"),
      element("Image", [], element("MediaId", [], cdata(media_id)))
    ])
    |> Saxy.encode!(nil)
  end

  @doc """
  回复语音消息 - [Official API Docs Link](#{@doc_link}#2){:target="_blank"}

  ```xml
  <xml>
    <ToUserName><![CDATA[toUser]]></ToUserName>
    <FromUserName><![CDATA[fromUser]]></FromUserName>
    <CreateTime>12345678</CreateTime>
    <MsgType><![CDATA[voice]]></MsgType>
    <Voice>
      <MediaId><![CDATA[media_id]]></MediaId>
    </Voice>
  </xml>
  ```
  """
  def reply_voice(to_openid, from_wx_no, timestamp, media_id) do
    element("xml", [], [
      element("ToUserName", [], cdata(to_openid)),
      element("FromUserName", [], cdata(from_wx_no)),
      element("CreateTime", [], to_string(timestamp)),
      element("MsgType", [], "voice"),
      element("Voice", [], element("MediaId", [], cdata(media_id)))
    ])
    |> Saxy.encode!(nil)
  end

  @doc """
  回复视频消息 - [Official API Docs Link](#{@doc_link}#3){:target="_blank"}

  ```xml
  <xml>
    <ToUserName><![CDATA[toUser]]></ToUserName>
    <FromUserName><![CDATA[fromUser]]></FromUserName>
    <CreateTime>12345678</CreateTime>
    <MsgType><![CDATA[video]]></MsgType>
    <Video>
      <MediaId><![CDATA[media_id]]></MediaId>
      <Title><![CDATA[title]]></Title>
      <Description><![CDATA[description]]></Description>
    </Video>
  </xml>
  ```
  """
  def reply_video(to_openid, from_wx_no, timestamp, media_id, title, desc) do
    element("xml", [], [
      element("ToUserName", [], cdata(to_openid)),
      element("FromUserName", [], cdata(from_wx_no)),
      element("CreateTime", [], to_string(timestamp)),
      element("MsgType", [], "video"),
      element("Video", [], [
        element("MediaId", [], cdata(media_id)),
        element("Title", [], cdata(title)),
        element("Description", [], cdata(desc))
      ])
    ])
    |> Saxy.encode!(nil)
  end

  @doc """
  回复音乐消息 - [Official API Docs Link](#{@doc_link}#4){:target="_blank"}

  ```xml
  <xml>
    <ToUserName><![CDATA[toUser]]></ToUserName>
    <FromUserName><![CDATA[fromUser]]></FromUserName>
    <CreateTime>12345678</CreateTime>
    <MsgType><![CDATA[music]]></MsgType>
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
  def reply_music(
        to_openid,
        from_wx_no,
        timestamp,
        thumb_media_id,
        title,
        desc,
        music_url,
        hq_music_url
      ) do
    element("xml", [], [
      element("ToUserName", [], cdata(to_openid)),
      element("FromUserName", [], cdata(from_wx_no)),
      element("CreateTime", [], to_string(timestamp)),
      element("MsgType", [], "music"),
      element("Music", [], [
        element("Title", [], cdata(title)),
        element("Description", [], cdata(desc)),
        element("MusicUrl", [], cdata(music_url)),
        element("HQMusicUrl", [], cdata(hq_music_url)),
        element("ThumbMediaId", [], cdata(thumb_media_id))
      ])
    ])
    |> Saxy.encode!(nil)
  end

  @doc """
  回复图文消息 - 文章item - [Official API Docs Link](#{@doc_link}#5){:target="_blank"}

  ```xml
  <item>
    <Title><![CDATA[title1]]></Title>
    <Description><![CDATA[description1]]></Description>
    <PicUrl><![CDATA[picurl]]></PicUrl>
    <Url><![CDATA[url]]></Url>
  </item>
  ```
  """
  def article_item(title, desc, pic_url, url) do
    element("item", [], [
      element("Title", [], cdata(title)),
      element("Description", [], cdata(desc)),
      element("PicUrl", [], cdata(pic_url)),
      element("Url", [], cdata(url))
    ])
  end

  @doc """
  回复图文消息 - [Official API Docs Link](#{@doc_link}#5){:target="_blank"}

  ```xml
  <xml>
    <ToUserName><![CDATA[toUser]]></ToUserName>
    <FromUserName><![CDATA[fromUser]]></FromUserName>
    <CreateTime>12345678</CreateTime>
    <MsgType><![CDATA[news]]></MsgType>
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
  def reply_news(to_openid, from_wx_no, timestamp, article_items) do
    element("xml", [], [
      element("ToUserName", [], cdata(to_openid)),
      element("FromUserName", [], cdata(from_wx_no)),
      element("CreateTime", [], to_string(timestamp)),
      element("MsgType", [], "news"),
      element("ArticleCount", [], to_string(length(article_items))),
      element("Articles", [], article_items)
    ])
    |> Saxy.encode!(nil)
  end

  @doc """
  消息转发客服消息 - [Official API Docs Link](#{doc_link_prefix()}/doc/offiaccount/Customer_Service/Forwarding_of_messages_to_service_center.html){:target="_blank"}

  ```xml
  <xml>
    <ToUserName><![CDATA[touser]]></ToUserName>
    <FromUserName><![CDATA[fromuser]]></FromUserName>
    <CreateTime>1399197672</CreateTime>
    <MsgType><![CDATA[transfer_customer_service]]></MsgType>
  </xml>
  ```
  """
  def transfer_customer_service(to_openid, from_wx_no, timestamp) do
    element("xml", [], [
      element("ToUserName", [], cdata(to_openid)),
      element("FromUserName", [], cdata(from_wx_no)),
      element("CreateTime", [], to_string(timestamp)),
      element("MsgType", [], "transfer_customer_service")
    ])
    |> Saxy.encode!(nil)
  end

  @doc """
  消息转发到指定客服 - [Official API Docs Link](#{doc_link_prefix()}/doc/offiaccount/Customer_Service/Forwarding_of_messages_to_service_center.html){:target="_blank"}

  ```xml
  <xml>
    <ToUserName><![CDATA[touser]]></ToUserName>
    <FromUserName><![CDATA[fromuser]]></FromUserName>
    <CreateTime>1399197672</CreateTime>
    <MsgType><![CDATA[transfer_customer_service]]></MsgType>
    <TransInfo>
      <KfAccount><![CDATA[test1@test]]></KfAccount>
    </TransInfo>
  </xml>
  ```
  """
  def transfer_customer_service(to_openid, from_wx_no, timestamp, kf_account) do
    element("xml", [], [
      element("ToUserName", [], cdata(to_openid)),
      element("FromUserName", [], cdata(from_wx_no)),
      element("CreateTime", [], to_string(timestamp)),
      element("MsgType", [], "transfer_customer_service"),
      element("TransInfo", [], element("KfAccount", [], cdata(kf_account)))
    ])
    |> Saxy.encode!(nil)
  end
end
