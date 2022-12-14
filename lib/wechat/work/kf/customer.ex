defmodule WeChat.Work.KF.Customer do
  @moduledoc "客户"

  import Jason.Helpers
  alias WeChat.Work
  alias WeChat.Work.Customer, as: C

  @doc_link WeChat.Utils.work_kf_doc_link_prefix()

  @doc """
  获取客户基本信息 -
  [官方文档](#{@doc_link}/94769){:target="_blank"}
  """
  @spec get_customer_info(Work.client(), Work.agent(), C.external_userid_list()) ::
          WeChat.response()
  def get_customer_info(client, agent, external_userid_list) do
    client.post(
      "/cgi-bin/kf/customer/batchget",
      json_map(external_userid_list: external_userid_list),
      query: [access_token: client.get_access_token(agent)]
    )
  end
end
