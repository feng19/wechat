defmodule WeChat.Work.KF.Customer do
  @moduledoc "客户"

  import Jason.Helpers
  import WeChat.Utils, only: [work_kf_doc_link_prefix: 0]
  alias WeChat.Work
  alias WeChat.Work.Customer, as: C

  @doc_link work_kf_doc_link_prefix()

  @doc """
  获取客户基本信息 -
  [官方文档](#{@doc_link}/94769){:target="_blank"}
  """
  @spec get_customer_info(Work.client(), C.external_userid_list()) :: WeChat.response()
  def get_customer_info(client, external_userid_list) do
    client.post(
      "/cgi-bin/kf/customer/batchget",
      json_map(external_userid_list: external_userid_list),
      query: [access_token: client.get_access_token(:kf)]
    )
  end
end
