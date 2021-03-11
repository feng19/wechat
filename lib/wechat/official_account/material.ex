defmodule WeChat.Material do
  @moduledoc "素材管理"
  import Jason.Helpers
  import WeChat.Utils, only: [doc_link_prefix: 0]
  alias Tesla.Multipart

  @doc_link "#{doc_link_prefix()}/doc/offiaccount/Asset_Management"

  @typedoc """
  素材的类型
    * `image` - 图片
    * `video` - 视频
    * `voice` - 语音
    * `news`  - 图文
    * `thumb`  - 缩略图

  support type
    * String.t :: ["image", "video", "voice", "news"]
    * atom :: [:image, :video, :voice, :news]
  """
  @type material_type :: :image | :video | :voice | :news | :thumb | String.t()
  @typedoc "素材的数量"
  @type material_count :: 1..20
  @typedoc "媒体文件ID"
  @type media_id :: String.t()
  @typedoc "文章"
  @type article :: WeChat.Material.Article.t()
  @typedoc "文章列表"
  @type articles :: [article]
  @typep file_path :: Path.t()
  @typep filename :: String.t()
  @typep file_data :: binary
  @typep title :: String.t()
  @typep description :: String.t()
  @typep introduction :: String.t()

  @doc """
  新增临时素材 - 文件 -
  [官方文档](#{@doc_link}/New_temporary_materials.html){:target="_blank"}

  公众号经常有需要用到一些临时性的多媒体素材的场景，例如在使用接口特别是发送消息时，对多媒体文件、多媒体消息的获取和调用等操作，
  是通过media_id来进行的。素材管理接口对所有认证的订阅号和服务号开放。通过本接口，公众号可以新增临时素材（即上传临时多媒体文件）。
  """
  @spec upload_media(WeChat.client(), material_type, file_path) :: WeChat.response()
  def upload_media(client, type, file_path) do
    multipart =
      Multipart.new()
      |> Multipart.add_file(file_path, name: "media", detect_content_type: true)

    client.post("/cgi-bin/media/upload", multipart,
      query: [access_token: client.get_access_token(), type: to_string(type)]
    )
  end

  @doc """
  新增临时素材(binary) -
  [官方文档](#{@doc_link}/New_temporary_materials.html){:target="_blank"}

  公众号经常有需要用到一些临时性的多媒体素材的场景，例如在使用接口特别是发送消息时，对多媒体文件、多媒体消息的获取和调用等操作，
  是通过media_id来进行的。素材管理接口对所有认证的订阅号和服务号开放。通过本接口，公众号可以新增临时素材（即上传临时多媒体文件）。
  """
  @spec upload_media(WeChat.client(), material_type, filename, file_data) :: WeChat.response()
  def upload_media(client, type, filename, file_data) do
    multipart =
      Multipart.new()
      |> Multipart.add_file_content(file_data, filename, name: "media", detect_content_type: true)

    client.post("/cgi-bin/media/upload", multipart,
      query: [access_token: client.get_access_token(), type: to_string(type)]
    )
  end

  @doc """
  获取临时素材 -
  [官方文档](#{@doc_link}/Get_temporary_materials.html){:target="_blank"}

  公众号可以使用本接口获取临时素材（即下载临时的多媒体文件）。
  """
  @spec get_media(WeChat.client(), media_id) :: WeChat.response()
  def get_media(client, media_id) do
    client.get("/cgi-bin/media/get",
      query: [
        media_id: media_id,
        access_token: client.get_access_token()
      ]
    )
  end

  @doc """
  新增永久图文素材 -
  [官方文档](#{@doc_link}/Adding_Permanent_Assets.html#新增永久图文素材){:target="_blank"}

  对于常用的素材，开发者可通过本接口上传到微信服务器，永久使用。新增的永久素材也可以在公众平台官网素材管理模块中查询管理。
  """
  @spec add_news(WeChat.client(), articles) :: WeChat.response()
  def add_news(client, articles) do
    client.post(
      "/cgi-bin/material/add_news",
      json_map(articles: articles),
      query: [access_token: client.get_access_token()]
    )
  end

  @doc """
  上传图文消息内的图片获取URL -
  [官方文档](#{@doc_link}/Adding_Permanent_Assets.html#上传图文消息内的图片获取URL){:target="_blank"}

  本接口所上传的图片不占用公众号的素材库中图片数量的100000个的限制。图片仅支持jpg/png格式，大小必须在1MB以下。
  """
  @spec upload_image(WeChat.client(), file_path) :: WeChat.response()
  def upload_image(client, file_path) do
    multipart =
      Multipart.new()
      |> Multipart.add_file(file_path, name: "media", detect_content_type: true)

    client.post("/cgi-bin/media/uploadimg", multipart,
      query: [access_token: client.get_access_token()]
    )
  end

  @doc """
  上传图文消息内的图片获取URL(binary) -
  [官方文档](#{@doc_link}/Adding_Permanent_Assets.html#上传图文消息内的图片获取URL){:target="_blank"}

  本接口所上传的图片不占用公众号的素材库中图片数量的100000个的限制。图片仅支持jpg/png格式，大小必须在1MB以下。
  """
  @spec upload_image(WeChat.client(), filename, file_data) :: WeChat.response()
  def upload_image(client, filename, file_data) do
    multipart =
      Multipart.new()
      |> Multipart.add_file_content(file_data, filename,
        name: "media",
        headers: [{"content-type", MIME.from_path(filename)}]
      )

    client.post("/cgi-bin/media/uploadimg", multipart,
      query: [access_token: client.get_access_token()]
    )
  end

  @doc """
  上传图文消息素材 -
  [官方文档](#{doc_link_prefix()}/doc/offiaccount/Message_Management/Batch_Sends_and_Originality_Checks.html#1){:target="_blank"}
  """
  @spec upload_news(WeChat.client(), articles) :: WeChat.response()
  def upload_news(client, articles) do
    client.post("/cgi-bin/media/uploadnews", json_map(articles: articles),
      query: [access_token: client.get_access_token()]
    )
  end

  @doc """
  获取批量推送类型为 `mpvideo` 时要求的 `media_id` -
  [官方文档](#{doc_link_prefix()}/doc/offiaccount/Message_Management/Batch_Sends_and_Originality_Checks.html#2){:target="_blank"}

  原 `media_id` 需通过 [素材管理] -> [新增素材] 来得到
  """
  @spec upload_video(WeChat.client(), media_id, title, description) :: WeChat.response()
  def upload_video(client, media_id, title, description) do
    client.post(
      "/cgi-bin/media/uploadvideo",
      json_map(media_id: media_id, title: title, description: description),
      query: [access_token: client.get_access_token()]
    )
  end

  @doc """
  新增其他类型永久素材 -
  [官方文档](#{@doc_link}/Adding_Permanent_Assets.html#新增其他类型永久素材){:target="_blank"}

  请注意：图片素材将进入公众平台官网素材管理模块中的默认分组。
  """
  @spec add_material(WeChat.client(), material_type, file_path) :: WeChat.response()
  def add_material(client, type, file_path) do
    multipart =
      Multipart.new()
      |> Multipart.add_file(file_path, name: "media", detect_content_type: true)

    client.post("/cgi-bin/material/add_material", multipart,
      query: [access_token: client.get_access_token(), type: to_string(type)]
    )
  end

  @doc """
  新增其他类型永久素材(binary) -
  [官方文档](#{@doc_link}/Adding_Permanent_Assets.html#新增其他类型永久素材){:target="_blank"}

  请注意：图片素材将进入公众平台官网素材管理模块中的默认分组。
  """
  @spec add_material(WeChat.client(), material_type, filename, file_data) :: WeChat.response()
  def add_material(client, type, filename, file_data) do
    multipart =
      Multipart.new()
      |> Multipart.add_file_content(file_data, filename,
        name: "media",
        headers: [{"content-type", MIME.from_path(filename)}]
      )

    client.post("/cgi-bin/material/add_material", multipart,
      query: [access_token: client.get_access_token(), type: to_string(type)]
    )
  end

  @doc """
  新增其他类型永久素材 - 视频 -
  [官方文档](#{@doc_link}/Adding_Permanent_Assets.html#新增其他类型永久素材){:target="_blank"}

  请注意：图片素材将进入公众平台官网素材管理模块中的默认分组。
  """
  @spec add_video_material(WeChat.client(), title, introduction, file_path) :: WeChat.response()
  def add_video_material(client, title, introduction, file_path) do
    description = Jason.encode!(json_map(title: title, introduction: introduction))

    multipart =
      Multipart.new()
      |> Multipart.add_file(file_path, name: "media", detect_content_type: true)
      |> Multipart.add_field("description", description)

    client.post("/cgi-bin/material/add_material", multipart,
      query: [access_token: client.get_access_token(), type: "video"]
    )
  end

  @doc """
  新增其他类型永久素材(binary) - 视频 -
  [官方文档](#{@doc_link}/Adding_Permanent_Assets.html#新增其他类型永久素材){:target="_blank"}

  请注意：图片素材将进入公众平台官网素材管理模块中的默认分组。
  """
  @spec add_video_material(WeChat.client(), title, introduction, filename, file_data) ::
          WeChat.response()
  def add_video_material(client, title, introduction, filename, file_data) do
    description = Jason.encode!(json_map(title: title, introduction: introduction))

    multipart =
      Multipart.new()
      |> Multipart.add_file_content(file_data, filename,
        name: "media",
        headers: [{"content-type", MIME.from_path(filename)}]
      )
      |> Multipart.add_field("description", description)

    client.post("/cgi-bin/material/add_material", multipart,
      query: [access_token: client.get_access_token(), type: "video"]
    )
  end

  @doc """
  获取永久素材 -
  [官方文档](#{@doc_link}/Getting_Permanent_Assets.html){:target="_blank"}

  在新增了永久素材后，开发者可以根据media_id通过本接口下载永久素材。公众号在公众平台官网素材管理模块中新建的永久素材，
  可通过"获取素材列表"获知素材的media_id。

  请注意：临时素材无法通过本接口获取
  """
  @spec get_material(WeChat.client(), media_id) :: WeChat.response()
  def get_material(client, media_id) do
    client.post(
      "/cgi-bin/material/get_material",
      json_map(media_id: media_id),
      query: [access_token: client.get_access_token()]
    )
  end

  @doc """
  删除永久素材 -
  [官方文档](#{@doc_link}/Deleting_Permanent_Assets.html){:target="_blank"}

  在新增了永久素材后，开发者可以根据本接口来删除不再需要的永久素材，节省空间。

  请注意：

  - 请谨慎操作本接口，因为它可以删除公众号在公众平台官网素材管理模块中新建的图文消息、语音、视频等素材（但需要先通过获取素材列表来获知素材的media_id）
  - 临时素材无法通过本接口删除
  - 调用该接口需https协议
  """
  @spec del_material(WeChat.client(), media_id) :: WeChat.response()
  def del_material(client, media_id) do
    client.post(
      "/cgi-bin/material/del_material",
      json_map(media_id: media_id),
      query: [access_token: client.get_access_token()]
    )
  end

  @doc """
  修改永久图文素材 -
  [官方文档](#{@doc_link}/Editing_Permanent_Rich_Media_Assets.html){:target="_blank"}

  开发者可以通过本接口对永久图文素材进行修改。

  请注意：

  - 也可以在公众平台官网素材管理模块中保存的图文消息（永久图文素材）
  - 调用该接口需https协议
  """
  @spec update_news(WeChat.client(), media_id, article, index :: integer) :: WeChat.response()
  def update_news(client, media_id, article, index \\ 0) do
    # 不支持编辑最后两个字段
    article =
      article
      |> Map.from_struct()
      |> Map.drop([:need_open_comment, :only_fans_can_comment])

    client.post(
      "/cgi-bin/material/update_news",
      json_map(
        media_id: media_id,
        index: index,
        articles: article
      ),
      query: [access_token: client.get_access_token()]
    )
  end

  @doc """
  获取素材总数 -
  [官方文档](#{@doc_link}/Get_the_total_of_all_materials.html){:target="_blank"}

  开发者可以根据本接口来获取永久素材的列表，需要时也可保存到本地。

  请注意：

  - 永久素材的总数，也会计算公众平台官网素材管理中的素材
  - 图片和图文消息素材（包括单图文和多图文）的总数上限为100000，其他素材的总数上限为1000
  - 调用该接口需https协议
  """
  @spec get_material_count(WeChat.client()) :: WeChat.response()
  def get_material_count(client) do
    client.get("/cgi-bin/material/get_materialcount",
      query: [access_token: client.get_access_token()]
    )
  end

  @doc """
  获取素材列表 -
  [官方文档](#{@doc_link}/Get_materials_list.html){:target="_blank"}

  在新增了永久素材后，开发者可以分类型获取永久素材的列表。

  请注意：

  - 获取永久素材的列表，也包含公众号在公众平台官网素材管理模块中新建的图文消息、语音、视频等素材
  - 临时素材无法通过本接口获取
  - 调用该接口需https协议

  ## 参数说明
    * type:   素材的类型，图片（image）、视频（video）、语音 （voice）、图文（news）
    * offset: 从全部素材的该偏移位置开始返回，0表示从第一个素材 返回
    * count:  返回素材的数量，取值在1到20之间
  """
  @spec batch_get_material(WeChat.client(), material_type, material_count, offset :: integer) ::
          WeChat.response()
  def batch_get_material(client, type, count \\ 10, offset \\ 0) when count in 1..20 do
    client.post(
      "/cgi-bin/material/batchget_material",
      json_map(type: type, offset: offset, count: count),
      query: [access_token: client.get_access_token()]
    )
  end

  @doc """
  获取素材列表(stream) -
  [官方文档](#{@doc_link}/Get_materials_list.html){:target="_blank"}

  在新增了永久素材后，开发者可以分类型获取永久素材的列表。

  请注意：

  - 获取永久素材的列表，也包含公众号在公众平台官网素材管理模块中新建的图文消息、语音、视频等素材
  - 临时素材无法通过本接口获取
  - 调用该接口需https协议

  ## 参数说明
    * type:   素材的类型，图片（image）、视频（video）、语音 （voice）、图文（news）
    * count:  返回素材的数量，取值在1到20之间
  """
  @spec stream_get_material(WeChat.client(), material_type, material_count) :: Enumerable.t()
  def stream_get_material(client, type, count \\ 20) do
    Stream.unfold(0, fn offset ->
      with {:ok, %{status: 200, body: body}} <-
             batch_get_material(client, type, count, offset),
           %{"item" => items} when items != [] <- body do
        {items, offset + count}
      else
        _ -> nil
      end
    end)
    |> Stream.flat_map(& &1)
  end
end
