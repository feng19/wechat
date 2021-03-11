defmodule WeChat.MiniProgram.Search do
  @moduledoc """
  小程序 - 搜索接口
  """
  import Jason.Helpers
  import WeChat.Utils, only: [doc_link_prefix: 0]
  alias Tesla.Multipart

  @typedoc "页面路径"
  @type path :: String.t()
  @typedoc "页面参数"
  @type query :: String.t()

  @typedoc "小程序页面信息"
  @type page :: %{path: path, query: query}
  @typedoc "小程序页面信息列表"
  @type pages :: [page]

  @typep file_path :: Path.t()
  @typep filename :: String.t()
  @typep file_data :: binary

  @doc_link "#{doc_link_prefix()}/miniprogram/dev/api-backend/open-api/search/search"

  @doc """
  图片搜索
  - [官方文档](#{@doc_link}.imageSearch.html){:target="_blank"}

  本接口提供基于小程序的站内搜商品图片搜索能力
  """
  @spec image_search(WeChat.client(), file_path) :: WeChat.response()
  def image_search(client, file_path) do
    multipart =
      Multipart.new()
      |> Multipart.add_file(file_path, name: "img", detect_content_type: true)

    client.post("/wxa/imagesearch", multipart, query: [access_token: client.get_access_token()])
  end

  @doc """
  图片搜索(binary)
  - [官方文档](#{@doc_link}.imageSearch.html){:target="_blank"}

  本接口提供基于小程序的站内搜商品图片搜索能力
  """
  @spec image_search(WeChat.client(), filename, file_data) :: WeChat.response()
  def image_search(client, filename, file_data) do
    multipart =
      Multipart.new()
      |> Multipart.add_file_content(file_data, filename,
        name: "img",
        headers: [{"content-type", MIME.from_path(filename)}]
      )

    client.post("/wxa/imagesearch", multipart, query: [access_token: client.get_access_token()])
  end

  @doc """
  页面搜索(binary)
  - [官方文档](#{@doc_link}.siteSearch.html){:target="_blank"}

  小程序内部搜索API提供针对页面的查询能力，小程序开发者输入搜索词后，将返回自身小程序和搜索词相关的页面。
  因此，利用该接口，开发者可以查看指定内容的页面被微信平台的收录情况；同时，该接口也可供开发者在小程序内应用，给小程序用户提供搜索能力。
  """
  @spec site_search(WeChat.client(), keyword :: String.t(), next_page_info :: String.t()) ::
          WeChat.response()
  def site_search(client, keyword, next_page_info \\ "") do
    client.post(
      "/wxa/sitesearch",
      json_map(keyword: keyword, next_page_info: next_page_info),
      query: [access_token: client.get_access_token()]
    )
  end

  @doc """
  提交页面(binary)
  - [官方文档](#{@doc_link}.submitPages.html){:target="_blank"}

  小程序开发者可以通过本接口提交小程序页面url及参数信息(不要推送webview页面)，
  让微信可以更及时的收录到小程序的页面信息，开发者提交的页面信息将可能被用于小程序搜索结果展示。
  """
  @spec submit_pages(WeChat.client(), pages) :: WeChat.response()
  def submit_pages(client, pages) do
    client.post(
      "/wxa/search/wxaapi_submitpages",
      json_map(pages: pages),
      query: [access_token: client.get_access_token()]
    )
  end
end
