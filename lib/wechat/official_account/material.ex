defmodule WeChat.Material do
  @moduledoc "素材管理"
  import Jason.Helpers
  import WeChat.Utils, only: [doc_link_prefix: 0]
  alias Tesla.Multipart
  alias WeChat.Requester

  @doc_link "#{doc_link_prefix()}/doc/offiaccount/Asset_Management"

  @typedoc """
  素材的类型
    * `image` - 图片
    * `video` - 视频
    * `voice` - 语音
    * `news`  - 图文

  support type
    * String.t :: ["image", "video", "voice", "news"]
    * atom :: [:image, :video, :voice, :news]
  """
  @type material_type :: String.t() | atom
  @typedoc """
  素材的数量，取值在1到20之间

  material_count in 1..20
  """
  @type material_count :: integer
  @type media_id :: String.t()
  @type article :: WeChat.Article.t()

  @doc """
  新增临时素材 - 文件 - [Official API Docs Link](#{@doc_link}/New_temporary_materials.html){:target="_blank"}
  """
  @spec upload_media(WeChat.client(), material_type, file_path :: Path.t()) :: WeChat.response()
  def upload_media(client, type, file_path) do
    mp =
      Multipart.new()
      |> Multipart.add_file(file_path, name: "media", detect_content_type: true)
      |> Multipart.add_field("type", type)

    Requester.post("/cgi-bin/media/upload", mp, query: [access_token: client.get_access_token()])
  end

  @doc """
  新增临时素材 - binary - [Official API Docs Link](#{@doc_link}/New_temporary_materials.html){:target="_blank"}
  """
  @spec upload_media(
          WeChat.client(),
          material_type,
          file_name :: String.t(),
          file_content :: binary
        ) :: WeChat.response()
  def upload_media(client, type, file_name, file_content) do
    mp =
      Multipart.new()
      |> Multipart.add_file_content(file_content, file_name, name: "media")
      |> Multipart.add_field("type", type)

    Requester.post("/cgi-bin/media/upload", mp, query: [access_token: client.get_access_token()])
  end

  @doc """
  获取临时素材 - [Official API Docs Link](#{@doc_link}/Get_temporary_materials.html){:target="_blank"}
  """
  @spec get_media(WeChat.client(), media_id) :: WeChat.response()
  def get_media(client, media_id) do
    Requester.get("/cgi-bin/media/get",
      query: [
        media_id: media_id,
        access_token: client.get_access_token()
      ]
    )
  end

  @doc """
  新增永久图文素材 - [Official API Docs Link](#{@doc_link}/Adding_Permanent_Assets.html#新增永久图文素材){:target="_blank"}
  """
  @spec add_news(WeChat.client(), articles :: [article]) :: WeChat.response()
  def add_news(client, articles) do
    Requester.post(
      "/cgi-bin/material/add_news",
      json_map(articles: articles),
      query: [access_token: client.get_access_token()]
    )
  end

  #  @doc """
  #  上传图文消息内的图片获取URL - [Official API Docs Link](#{@doc_link}/Adding_Permanent_Assets.html#上传图文消息内的图片获取URL){:target="_blank"}
  #  """
  #  @spec upload_image(WeChat.client, file_path :: Path.t) :: WeChat.response
  #  def upload_image(client, file_path) do
  #    Requester.post("/cgi-bin/media/uploadimg", mp, query: [access_token: client.get_access_token()])
  #  end
  #  @spec upload_image(WeChat.client, file_name :: String.t, file_content :: binary) :: WeChat.response
  #  def upload_image(client, type, file_name, file_content) do
  #    Requester.post("/cgi-bin/media/uploadimg", mp, query: [access_token: client.get_access_token()])
  #  end
  #
  #  @doc """
  #  新增其他类型永久素材 - [Official API Docs Link](#{@doc_link}/Adding_Permanent_Assets.html#新增其他类型永久素材){:target="_blank"}
  #  """
  #  def add_material(client) do
  #    :todo
  #  end

  @doc """
  获取永久素材 - [Official API Docs Link](#{@doc_link}/Getting_Permanent_Assets.html){:target="_blank"}
  """
  @spec get_material(WeChat.client(), media_id) :: WeChat.response()
  def get_material(client, media_id) do
    Requester.post(
      "/cgi-bin/material/get_material",
      json_map(media_id: media_id),
      query: [access_token: client.get_access_token()]
    )
  end

  @doc """
  删除永久素材 - [Official API Docs Link](#{@doc_link}/Deleting_Permanent_Assets.html){:target="_blank"}
  """
  @spec del_material(WeChat.client(), media_id) :: WeChat.response()
  def del_material(client, media_id) do
    Requester.post(
      "/cgi-bin/material/del_material",
      json_map(media_id: media_id),
      query: [access_token: client.get_access_token()]
    )
  end

  @doc """
  修改永久图文素材 - [Official API Docs Link](#{@doc_link}/Editing_Permanent_Rich_Media_Assets.html){:target="_blank"}
  """
  @spec update_news(WeChat.client(), media_id, article, index :: integer) :: WeChat.response()
  def update_news(client, media_id, article, index \\ 0) do
    # 不支持编辑最后两个字段
    article =
      article
      |> Map.from_struct()
      |> Map.drop([:need_open_comment, :only_fans_can_comment])

    Requester.post(
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
  获取素材总数 - [Official API Docs Link](#{@doc_link}/Get_the_total_of_all_materials.html){:target="_blank"}
  """
  @spec get_material_count(WeChat.client()) :: WeChat.response()
  def get_material_count(client) do
    Requester.get("/cgi-bin/material/get_materialcount",
      query: [access_token: client.get_access_token()]
    )
  end

  @doc """
  获取素材列表 - [Official API Docs Link](#{@doc_link}/Get_materials_list.html){:target="_blank"}

  ## 参数说明:
    * type:   素材的类型，图片（image）、视频（video）、语音 （voice）、图文（news）
    * offset: 从全部素材的该偏移位置开始返回，0表示从第一个素材 返回
    * count:  返回素材的数量，取值在1到20之间
  """
  @spec batch_get_material(WeChat.client(), material_type, material_count, offset :: integer) ::
          WeChat.response()
  def batch_get_material(client, type, count \\ 10, offset \\ 0) when count in 1..20 do
    Requester.post(
      "/cgi-bin/material/batchget_material",
      json_map(type: type, offset: offset, count: count),
      query: [access_token: client.get_access_token()]
    )
  end

  @doc """
  获取素材列表 - [Official API Docs Link](#{@doc_link}/Get_materials_list.html){:target="_blank"}

  ## 参数说明:
    * type:   素材的类型，图片（image）、视频（video）、语音 （voice）、图文（news）
    * count:  返回素材的数量，取值在1到20之间
  """
  @spec stream_unfold_material(WeChat.client(), material_type, material_count) :: Stream.t()
  def stream_unfold_material(client, type, count \\ 20) do
    Stream.unfold(0, fn offset ->
      with {:ok, 200, %{"item" => items}} when items != [] <-
             batch_get_material(client, type, count, offset) do
        {items, offset + count}
      else
        _ -> nil
      end
    end)
    |> Stream.flat_map(& &1)
  end
end
