defmodule WeChat.Work.Contacts.Tag do
  @moduledoc "通讯录管理-标签管理"

  import WeChat.Utils, only: [work_doc_link_prefix: 0]
  alias WeChat.Work

  @doc_link "#{work_doc_link_prefix()}/90000/90135"

  @typedoc """
  每个标签都有唯一的标签id -
  [官方文档](#{@doc_link}/90665#tagid){:target="_blank"}

  在管理后台->“通讯录”->“标签”，选中某个标签，在右上角会有“标签详情”按钮，点击即可看到
  """
  @type tag_id :: integer

  @doc """
  获取标签列表 -
  [官方文档](#{@doc_link}/90216){:target="_blank"}
  """
  @spec list(Work.client()) :: WeChat.response()
  def list(client) do
    client.get("/cgi-bin/tag/list", query: [access_token: client.get_access_token(:contacts)])
  end
end
