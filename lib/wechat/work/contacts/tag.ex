defmodule WeChat.Work.Contacts.Tag do
  @moduledoc "通讯录管理-标签管理"

  import Jason.Helpers
  alias WeChat.Work
  alias Work.Contacts.{Department, User}

  @doc_link WeChat.Utils.work_doc_link_prefix()

  @typedoc """
  每个标签都有唯一的标签id -
  [官方文档](#{@doc_link}/90665#tagid){:target="_blank"}

  在管理后台->“通讯录”->“标签”，选中某个标签，在右上角会有“标签详情”按钮，点击即可看到
  """
  @type tag_id :: integer
  @type tag_id_list :: [tag_id]
  @typedoc "标签名称，长度限制为32个字以内（汉字或英文字母），标签名不可与其他标签重名"
  @type tag_name :: String.t()

  @doc """
  创建标签 -
  [官方文档](#{@doc_link}/90210){:target="_blank"}
  """
  @spec create(Work.client(), tag_name, tag_id) :: WeChat.response()
  def create(client, tag_name, tag_id \\ nil) do
    json =
      if tag_id do
        json_map(tagname: tag_name, tagid: tag_id)
      else
        json_map(tagname: tag_name)
      end

    client.post("/cgi-bin/tag/create", json,
      query: [access_token: client.get_access_token(:contacts)]
    )
  end

  @doc """
  更新标签名字 -
  [官方文档](#{@doc_link}/90211){:target="_blank"}
  """
  @spec update(Work.client(), tag_id, tag_name) :: WeChat.response()
  def update(client, tag_id, tag_name) do
    client.post("/cgi-bin/tag/update", json_map(tagid: tag_id, tagname: tag_name),
      query: [access_token: client.get_access_token(:contacts)]
    )
  end

  @doc """
  删除标签 -
  [官方文档](#{@doc_link}/90212){:target="_blank"}
  """
  @spec delete(Work.client(), tag_id) :: WeChat.response()
  def delete(client, tag_id) do
    client.get("/cgi-bin/tag/delete",
      query: [access_token: client.get_access_token(:contacts), tagid: tag_id]
    )
  end

  @doc """
  获取标签成员 -
  [官方文档](#{@doc_link}/90213){:target="_blank"}
  """
  @spec list_user(Work.client(), tag_id) :: WeChat.response()
  def list_user(client, tag_id) do
    client.get("/cgi-bin/tag/get",
      query: [access_token: client.get_access_token(:contacts), tagid: tag_id]
    )
  end

  @doc """
  增加标签成员 -
  [官方文档](#{@doc_link}/90214){:target="_blank"}
  """
  @spec add_user(
          Work.client(),
          tag_id,
          nil | User.userid_list(),
          nil | Department.id_list()
        ) :: WeChat.response()
  def add_user(client, tag_id, userid_list, party_id_list) do
    body =
      [userlist: List.wrap(userid_list), partylist: List.wrap(party_id_list)]
      |> Enum.reject(&Enum.empty?(elem(&1, 1)))
      |> Enum.into(%{tagid: tag_id})

    client.post("/cgi-bin/tag/addtagusers", body,
      query: [access_token: client.get_access_token(:contacts)]
    )
  end

  @doc """
  删除标签成员 -
  [官方文档](#{@doc_link}/90215){:target="_blank"}
  """
  @spec delete_user(
          Work.client(),
          tag_id,
          nil | User.userid_list(),
          nil | Department.id_list()
        ) :: WeChat.response()
  def delete_user(client, tag_id, userid_list, party_id_list) do
    body =
      [userlist: List.wrap(userid_list), partylist: List.wrap(party_id_list)]
      |> Enum.reject(&Enum.empty?(elem(&1, 1)))
      |> Enum.into(%{tagid: tag_id})

    client.post("/cgi-bin/tag/deltagusers", body,
      query: [access_token: client.get_access_token(:contacts)]
    )
  end

  @doc """
  获取标签列表 -
  [官方文档](#{@doc_link}/90216){:target="_blank"}
  """
  @spec list(Work.client()) :: WeChat.response()
  def list(client) do
    client.get("/cgi-bin/tag/list", query: [access_token: client.get_access_token(:contacts)])
  end
end
