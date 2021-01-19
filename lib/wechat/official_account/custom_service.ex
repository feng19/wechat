defmodule WeChat.CustomService do
  @moduledoc """
  客服帐号管理

  [API Docs Link](https://developers.weixin.qq.com/doc/offiaccount/Message_Management/Service_Center_messages.html#0){:target="_blank"}
  """
  import Jason.Helpers
  import WeChat.Utils, only: [doc_link_prefix: 0]

  @doc_link "#{doc_link_prefix()}/doc/offiaccount/Message_Management/Service_Center_messages.html"

  @type kf_account :: String.t()
  @type nickname :: String.t()
  @type password :: String.t()

  @doc """
  添加客服帐号 -
  [Official API Docs Link](#{@doc_link}#1){:target="_blank"}
  """
  @spec add_kf_account(WeChat.client(), kf_account, nickname, password) :: WeChat.response()
  def add_kf_account(client, kf_account, nickname, password) do
    client.post(
      "/cgi-bin/customservice/kfaccount/add",
      json_map(kf_account: kf_account, nickname: nickname, password: password),
      query: [access_token: client.get_access_token()]
    )
  end

  @doc """
  修改客服帐号 -
  [Official API Docs Link](#{@doc_link}#2){:target="_blank"}
  """
  @spec update_kf_account(WeChat.client(), kf_account, nickname, password) :: WeChat.response()
  def update_kf_account(client, kf_account, nickname, password) do
    client.post(
      "/cgi-bin/customservice/kfaccount/update",
      json_map(kf_account: kf_account, nickname: nickname, password: password),
      query: [access_token: client.get_access_token()]
    )
  end

  @doc """
  删除客服帐号

  ## API Docs
    [link](#{@doc_link}#3){:target="_blank"}
  """
  @spec del_kf_account(WeChat.client(), kf_account, nickname, password) :: WeChat.response()
  def del_kf_account(client, kf_account, nickname, password) do
    client.post(
      "/cgi-bin/customservice/kfaccount/del",
      json_map(kf_account: kf_account, nickname: nickname, password: password),
      query: [access_token: client.get_access_token()]
    )
  end

  # @doc """
  # 设置客服帐号的头像 -
  #   [Official API Docs Link](#{@doc_link}#4){:target="_blank"}
  # """
  # @spec upload_head_img(WeChat.client, kf_account, file_path :: Path.t) :: WeChat.response
  # def upload_head_img(client, kf_account, file_path) do
  #  # todo upload file_path
  #  client.post("/cgi-bin/customservice/kfaccount/uploadheadimg", mp,
  #    query: [
  #      kf_account: kf_account, access_token: client.get_access_token()
  #    ]
  #  )
  # end

  @doc """
  获取所有客服账号 -
  [Official API Docs Link](#{@doc_link}#5){:target="_blank"}
  """
  @spec get_kf_list(WeChat.client()) :: WeChat.response()
  def get_kf_list(client) do
    client.get("/cgi-bin/customservice/getkflist",
      query: [access_token: client.get_access_token()]
    )
  end
end
