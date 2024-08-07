defmodule WeChat.Work.KF.Account do
  @moduledoc "客服账号管理"

  import Jason.Helpers
  alias WeChat.{Work, Work.Material}

  @typedoc "客服帐号ID"
  @type open_kfid :: String.t()
  @typedoc "客服帐号名称"
  @type name :: String.t()
  @typedoc """
  场景值，字符串类型，由开发者自定义。
  不多于32字节
  字符串取值范围(正则表达式)：[0-9a-zA-Z_-]*
  """
  @type scene :: String.t()

  @doc """
  添加客服帐号 -
  [官方文档](https://developer.work.weixin.qq.com/document/path/94662){:target="_blank"}

  添加客服帐号，并可设置客服名称和头像。
  """
  @spec add(Work.client(), Work.agent(), name, Material.media_id()) :: WeChat.response()
  def add(client, agent, name, media_id) do
    client.post("/cgi-bin/kf/account/add", json_map(name: name, media_id: media_id),
      query: [access_token: client.get_access_token(agent)]
    )
  end

  @doc """
  删除客服帐号 -
  [官方文档](https://developer.work.weixin.qq.com/document/path/94663){:target="_blank"}

  删除已有的客服帐号。
  """
  @spec delete(Work.client(), Work.agent(), open_kfid) :: WeChat.response()
  def delete(client, agent, open_kfid) do
    client.post("/cgi-bin/kf/account/del", json_map(open_kfid: open_kfid),
      query: [access_token: client.get_access_token(agent)]
    )
  end

  @doc """
  修改客服帐号 -
  [官方文档](https://developer.work.weixin.qq.com/document/path/94664){:target="_blank"}

  修改已有的客服帐号，可修改客服名称和头像。
  """
  @spec update(Work.client(), Work.agent(), open_kfid, opts :: Enumerable.t()) ::
          WeChat.response()
  def update(client, agent, open_kfid, opts) do
    client.post(
      "/cgi-bin/kf/account/update",
      Map.new(opts) |> Map.put(:open_kfid, open_kfid),
      query: [access_token: client.get_access_token(agent)]
    )
  end

  @doc """
  获取客服帐号列表 -
  [官方文档](https://developer.work.weixin.qq.com/document/path/94661){:target="_blank"}

  获取客服帐号列表，包括所有的客服帐号的客服ID、名称和头像。
  """
  @spec list(Work.client(), Work.agent()) :: WeChat.response()
  def list(client, agent) do
    client.get("/cgi-bin/kf/account/list",
      query: [access_token: client.get_access_token(agent)]
    )
  end

  @doc """
  获取客服帐号链接 -
  [官方文档](https://developer.work.weixin.qq.com/document/path/94665){:target="_blank"}

  企业可通过此接口获取带有不同参数的客服链接，不同客服帐号对应不同的客服链接。获取后，企业可将链接嵌入到网页等场景中，微信用户点击链接即可向对应的客服帐号发起咨询。企业可依据参数来识别用户的咨询来源等。
  """
  @spec add_contact_way(Work.client(), Work.agent(), open_kfid, scene) :: WeChat.response()
  def add_contact_way(client, agent, open_kfid, scene \\ nil) do
    json =
      if scene do
        json_map(open_kfid: open_kfid, scene: scene)
      else
        json_map(open_kfid: open_kfid)
      end

    client.post("/cgi-bin/kf/add_contact_way", json,
      query: [access_token: client.get_access_token(agent)]
    )
  end
end
