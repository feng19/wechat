defmodule WeChat.ServerMessage.XmlMessage do
  @moduledoc """
  回复推送消息
  [API Docs Link](https://developers.weixin.qq.com/doc/offiaccount/Message_Management/Passive_user_reply_message.html)
  """
  import Saxy.XML

  @doc_link "#{WeChat.doc_link_prefix()}/offiaccount/Message_Management/Passive_user_reply_message.html"

  @doc """
  return reply_msg

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
  回复文本消息

  ```xml
  <xml>
    <ToUserName><![CDATA[toUser]]></ToUserName>
    <FromUserName><![CDATA[fromUser]]></FromUserName>
    <CreateTime>12345678</CreateTime>
    <MsgType><![CDATA[text]]></MsgType>
    <Content><![CDATA[你好]]></Content>
  </xml>
  ```

  ## API Docs
    [link](#{@doc_link}#0){:target="_blank"}
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
  回复图片消息

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

  ## API Docs
    [link](#{@doc_link}#1){:target="_blank"}
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
  回复语音消息

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

  ## API Docs
    [link](#{@doc_link}#2){:target="_blank"}
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
  回复视频消息

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

  ## API Docs
    [link](#{@doc_link}#3){:target="_blank"}
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
  回复音乐消息

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

  ## API Docs
    [link](#{@doc_link}#4){:target="_blank"}
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
  文章

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
  回复图文消息

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

  ## API Docs
    [link](#{@doc_link}#3){:target="_blank"}
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
end
