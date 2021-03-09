defmodule WeChat.User do
  @moduledoc "用户管理"
  import Jason.Helpers
  import WeChat.Utils, only: [doc_link_prefix: 0]

  @typedoc "微信号"
  @type username :: String.t()
  @typedoc "微信号列表"
  @type username_list :: [username]
  @typedoc "昵称"
  @type nickname :: String.t()
  @typedoc """
  国家地区语言
    * `"zh_CN"` - 简体
    * `"zh_TW"` - 繁体
    * `"en"` - 英语
  """
  @type lang :: String.t()
  @typedoc """
  公众号运营者对粉丝的备注，公众号运营者可在微信公众平台用户管理界面对粉丝添加备注
  """
  @type remark :: String.t()

  @doc_link "#{doc_link_prefix()}/doc/offiaccount/User_Management"

  @doc """
  设置用户备注名 -
  [官方文档](#{@doc_link}/Configuring_user_notes.html){:target="_blank"}
  """
  @spec update_remark(WeChat.client(), WeChat.openid(), remark) :: WeChat.response()
  def update_remark(client, openid, remark) do
    client.post(
      "/cgi-bin/user/info/updateremark",
      json_map(openid: openid, remark: remark),
      query: [access_token: client.get_access_token()]
    )
  end

  @doc """
  获取用户基本信息(UnionID机制) -
  [官方文档](#{@doc_link}/Get_users_basic_information_UnionID.html#UinonId){:target="_blank"}
  """
  @spec user_info(WeChat.client(), WeChat.openid()) :: WeChat.response()
  def user_info(client, openid) do
    client.get("/cgi-bin/user/info",
      query: [
        openid: openid,
        access_token: client.get_access_token()
      ]
    )
  end

  @doc """
  获取用户基本信息(UnionID机制) -
  [官方文档](#{@doc_link}/Get_users_basic_information_UnionID.html#UinonId){:target="_blank"}
  """
  @spec user_info(WeChat.client(), WeChat.openid(), lang) :: WeChat.response()
  def user_info(client, openid, lang) do
    client.get("/cgi-bin/user/info",
      query: [
        openid: openid,
        lang: lang,
        access_token: client.get_access_token()
      ]
    )
  end

  @doc """
  批量获取用户基本信息 -
  [官方文档](#{@doc_link}/Get_users_basic_information_UnionID.html){:target="_blank"}
  """
  @spec batch_get_user_info(WeChat.client(), [
          %{required(:openid) => WeChat.openid(), optional(:lang) => lang}
        ]) :: WeChat.response()
  def batch_get_user_info(client, user_list) do
    client.post(
      "/cgi-bin/user/info/batchget",
      json_map(user_list: user_list),
      query: [access_token: client.get_access_token()]
    )
  end

  @doc """
  获取用户列表 -
  [官方文档](#{@doc_link}/Getting_a_User_List.html){:target="_blank"}
  """
  @spec get_users(WeChat.client()) :: WeChat.response()
  def get_users(client) do
    client.get("/cgi-bin/user/get",
      query: [access_token: client.get_access_token()]
    )
  end

  @doc """
  获取用户列表 -
  [官方文档](#{@doc_link}/Getting_a_User_List.html){:target="_blank"}
  """
  @spec get_users(WeChat.client(), WeChat.openid()) :: WeChat.response()
  def get_users(client, next_openid) do
    client.get("/cgi-bin/user/get",
      query: [
        next_openid: next_openid,
        access_token: client.get_access_token()
      ]
    )
  end

  @doc """
  获取用户列表 -
  [官方文档](#{@doc_link}/Getting_a_User_List.html){:target="_blank"}
  """
  @spec stream_get_user(WeChat.client()) :: Enumerable.t()
  def stream_get_user(client) do
    Stream.unfold(nil, fn
      nil ->
        with {:ok, %{status: 200, body: body}} <- get_users(client),
             %{"data" => %{"openid" => openid_list}, "next_openid" => next_openid} <- body do
          {openid_list, next_openid}
        else
          _ ->
            nil
        end

      "" ->
        nil

      next_openid ->
        with {:ok, %{status: 200, body: body}} <- get_users(client, next_openid),
             %{"data" => %{"openid" => openid_list}, "next_openid" => next_openid} <- body do
          {openid_list, next_openid}
        else
          _ ->
            nil
        end
    end)
    |> Stream.flat_map(& &1)
  end
end
