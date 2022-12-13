defmodule WeChat.Work.Living do
  @moduledoc "直播"

  import Jason.Helpers
  alias WeChat.Work
  alias Work.Contacts.User

  @doc_link WeChat.Utils.work_doc_link_prefix()

  @typedoc "直播ID"
  @type living_id :: String.t()
  @type living_id_list :: [living_id]

  @doc """
  创建预约直播
  - [官方文档](#{@doc_link}/93637){:target="_blank"}
  """
  @spec create(Work.client(), Work.agent(), body :: map) :: WeChat.response()
  def create(client, agent, body) do
    client.post("/cgi-bin/living/create", body,
      query: [access_token: client.get_access_token(agent)]
    )
  end

  @doc """
  修改预约直播
  - [官方文档](#{@doc_link}/93640){:target="_blank"}
  """
  @spec modify(Work.client(), Work.agent(), body :: map) :: WeChat.response()
  def modify(client, agent, body) do
    client.post("/cgi-bin/living/modify", body,
      query: [access_token: client.get_access_token(agent)]
    )
  end

  @doc """
  获取直播详情
  - [官方文档](#{@doc_link}/93635){:target="_blank"}
  """
  @spec get_info(Work.client(), Work.agent(), living_id) :: WeChat.response()
  def get_info(client, agent, living_id) do
    client.get("/cgi-bin/living/get_living_info",
      query: [livingid: living_id, access_token: client.get_access_token(agent)]
    )
  end

  @doc """
  取消预约直播
  - [官方文档](#{@doc_link}/93638){:target="_blank"}
  """
  @spec cancel(Work.client(), Work.agent(), living_id) :: WeChat.response()
  def cancel(client, agent, living_id) do
    client.post("/cgi-bin/living/cancel", json_map(livingid: living_id),
      query: [access_token: client.get_access_token(agent)]
    )
  end

  @doc """
  删除直播回放
  - [官方文档](#{@doc_link}/93874){:target="_blank"}
  """
  @spec delete_replay(Work.client(), Work.agent(), living_id) :: WeChat.response()
  def delete_replay(client, agent, living_id) do
    client.post("/cgi-bin/living/delete_replay_data", json_map(livingid: living_id),
      query: [access_token: client.get_access_token(agent)]
    )
  end

  @doc """
  在微信中观看直播或直播回放-获取微信观看直播凭证
  - [官方文档](#{@doc_link}/93641#获取微信观看直播凭证){:target="_blank"}
  """
  @spec get_living_code(Work.client(), Work.agent(), living_id, WeChat.openid()) ::
          WeChat.response()
  def get_living_code(client, agent, living_id, openid) do
    client.post("/cgi-bin/living/get_living_code", json_map(livingid: living_id, openid: openid),
      query: [access_token: client.get_access_token(agent)]
    )
  end

  @doc """
  获取成员直播ID列表
  - [官方文档](#{@doc_link}/93634){:target="_blank"}
  """
  @spec list_user_living_ids(
          Work.client(),
          Work.agent(),
          User.userid(),
          cursor :: integer,
          limit :: 1..100
        ) :: WeChat.response()
  def list_user_living_ids(client, agent, userid, cursor \\ 0, limit \\ 100) do
    client.post(
      "/cgi-bin/living/get_user_all_livingid",
      json_map(userid: userid, cursor: cursor, limit: limit),
      query: [access_token: client.get_access_token(agent)]
    )
  end

  @doc """
  获取直播观看明细
  - [官方文档](#{@doc_link}/93636){:target="_blank"}
  """
  @spec get_watch_stat(Work.client(), Work.agent(), living_id, next_key :: String.t()) ::
          WeChat.response()
  def get_watch_stat(client, agent, living_id, next_key \\ "0") do
    client.post(
      "/cgi-bin/living/get_watch_stat",
      json_map(livingid: living_id, next_key: next_key),
      query: [access_token: client.get_access_token(agent)]
    )
  end

  @doc """
  获取跳转小程序商城的直播观众信息
  - [官方文档](#{@doc_link}/94442){:target="_blank"}
  """
  @spec get_living_share_info(Work.client(), Work.agent(), ww_share_code :: String.t()) ::
          WeChat.response()
  def get_living_share_info(client, agent, ww_share_code) do
    client.post(
      "/cgi-bin/living/get_living_share_info",
      json_map(ww_share_code: ww_share_code),
      query: [access_token: client.get_access_token(agent)]
    )
  end
end
