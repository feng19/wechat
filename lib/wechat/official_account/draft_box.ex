defmodule WeChat.DraftBox do
  @moduledoc "草稿箱"
  import Jason.Helpers
  alias WeChat.Material.Article

  @doc_link "https://developers.weixin.qq.com/doc/offiaccount/Draft_Box"

  @typedoc "草稿箱的media_id"
  @type media_id :: String.t()

  @doc """
  新建草稿 -
  [官方文档](#{@doc_link}/Add_draft.html){:target="_blank"}

  开发者可新增常用的素材到草稿箱中进行使用。上传到草稿箱中的素材被群发或发布后，该素材将从草稿箱中移除。新增草稿可在公众平台官网-草稿箱中查看和管理。
  """
  @spec add(WeChat.client(), Article.t()) :: WeChat.response()
  def add(client, article) do
    client.post("/cgi-bin/draft/add", json_map(articles: [article]),
      query: [access_token: client.get_access_token()]
    )
  end

  @doc """
  获取草稿 -
  [官方文档](#{@doc_link}/Get_draft.html){:target="_blank"}

  新增草稿后，开发者可以根据草稿指定的字段来下载草稿。
  """
  @spec get(WeChat.client(), media_id) :: WeChat.response()
  def get(client, media_id) do
    client.post("/cgi-bin/draft/get", json_map(media_id: media_id),
      query: [access_token: client.get_access_token()]
    )
  end

  @doc """
  删除草稿 -
  [官方文档](#{@doc_link}/Delete_draft.html){:target="_blank"}

  新增草稿后，开发者可以根据本接口来删除不再需要的草稿，节省空间。**此操作无法撤销，请谨慎操作。**
  """
  @spec delete(WeChat.client(), media_id) :: WeChat.response()
  def delete(client, media_id) do
    client.post("/cgi-bin/draft/delete", json_map(media_id: media_id),
      query: [access_token: client.get_access_token()]
    )
  end

  @doc """
  修改草稿 -
  [官方文档](#{@doc_link}/Update_draft.html){:target="_blank"}

  开发者可通过本接口对草稿进行修改。
  """
  @spec update(WeChat.client(), media_id, Article.t(), index :: integer) :: WeChat.response()
  def update(client, media_id, article, index \\ 0) do
    client.post(
      "/cgi-bin/draft/update",
      json_map(media_id: media_id, index: index, articles: article),
      query: [access_token: client.get_access_token()]
    )
  end

  @doc """
  获取草稿总数 -
  [官方文档](#{@doc_link}/Count_drafts.html){:target="_blank"}

  开发者可以根据本接口来获取草稿的总数。此接口只统计数量，不返回草稿的具体内容。
  """
  @spec count(WeChat.client()) :: WeChat.response()
  def count(client) do
    client.get("/cgi-bin/draft/count", query: [access_token: client.get_access_token()])
  end

  @doc """
  获取草稿列表 -
  [官方文档](#{@doc_link}/Get_draft_list.html){:target="_blank"}

  新增草稿之后，开发者可以获取草稿的列表。

  ## 参数说明
    * offset: 从全部素材的该偏移位置开始返回，0表示从第一个素材 返回
    * count:  返回素材的数量，取值在1到20之间
    * no_content: 是否返回 content 字段
  """
  @spec batch_get(WeChat.client(), count :: integer, offset :: integer, no_content :: boolean) ::
          WeChat.response()
  def batch_get(client, count \\ 10, offset \\ 0, no_content \\ false) when count in 1..20 do
    client.post(
      "/cgi-bin/draft/batchget",
      json_map(offset: offset, count: count, no_content: if(no_content, do: 1, else: 0)),
      query: [access_token: client.get_access_token()]
    )
  end

  @doc """
  获取草稿列表(stream) -
  [官方文档](#{@doc_link}/Get_draft_list.html){:target="_blank"}

  新增草稿之后，开发者可以获取草稿的列表。

  ## 参数说明
    * count:  返回素材的数量，取值在1到20之间
    * no_content: 是否返回 content 字段
  """
  @spec stream_get(WeChat.client(), count :: integer, no_content :: boolean) :: Enumerable.t()
  def stream_get(client, count \\ 20, no_content \\ false) do
    Stream.unfold(0, fn offset ->
      with {:ok, %{status: 200, body: body}} <- batch_get(client, count, offset, no_content),
           %{"item" => items} when items != [] <- body do
        {items, offset + count}
      else
        _ -> nil
      end
    end)
    |> Stream.flat_map(& &1)
  end
end
