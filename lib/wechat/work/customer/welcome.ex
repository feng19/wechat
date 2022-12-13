defmodule WeChat.Work.Customer.Welcome do
  @moduledoc "客户欢迎语"

  alias WeChat.Work

  @doc_link WeChat.Utils.work_doc_link_prefix()

  @typedoc "群欢迎语的素材id"
  @type template_id :: String.t()

  @doc """
  发送新客户欢迎语 -
  [官方文档](#{@doc_link}/92137){:target="_blank"}

  - 企业微信在向企业推送添加外部联系人事件时，会额外返回一个welcome_code，企业以此为凭据调用接口，即可通过成员向新添加的客户发送个性化的欢迎语。
  - 为了保证用户体验以及避免滥用，企业仅可在收到相关事件后20秒内调用，且只可调用一次。
  - 如果企业已经在管理端为相关成员配置了可用的欢迎语，则推送添加外部联系人事件时不会返回welcome_code。
  - 每次添加新客户时可能有多个企业自建应用/第三方应用收到带有welcome_code的回调事件，但仅有最先调用的可以发送成功。后续调用将返回41051（externaluser has started chatting）错误，请用户根据实际使用需求，合理设置应用可见范围，避免冲突。
  - 旧接口发送新客户欢迎语已经废弃，接口升级后支持发送视频文件，并且最多支持同时发送9个附件
  """
  @spec send_welcome_msg(Work.client(), Work.agent(), body :: map) :: WeChat.response()
  def send_welcome_msg(client, agent, body) do
    client.post("/cgi-bin/externalcontact/send_welcome_msg", body,
      query: [access_token: client.get_access_token(agent)]
    )
  end

  @doc """
  添加入群欢迎语素材 -
  [官方文档](#{@doc_link}/92366#添加入群欢迎语素材){:target="_blank"}

  企业可通过此API向企业的入群欢迎语素材库中添加素材。每个企业的入群欢迎语素材库中，最多容纳100个素材。
  """
  @spec add_group_template(Work.client(), Work.agent(), body :: map) :: WeChat.response()
  def add_group_template(client, agent, body) do
    client.post("/cgi-bin/externalcontact/group_welcome_template/add", body,
      query: [access_token: client.get_access_token(agent)]
    )
  end

  @doc """
  编辑入群欢迎语素材 -
  [官方文档](#{@doc_link}/92366#编辑入群欢迎语素材){:target="_blank"}

  企业可通过此API编辑入群欢迎语素材库中的素材，且仅能够编辑调用方自己创建的入群欢迎语素材。
  """
  @spec edit_group_template(Work.client(), Work.agent(), body :: map) :: WeChat.response()
  def edit_group_template(client, agent, body) do
    client.post("/cgi-bin/externalcontact/group_welcome_template/edit", body,
      query: [access_token: client.get_access_token(agent)]
    )
  end

  @doc """
  获取入群欢迎语素材 -
  [官方文档](#{@doc_link}/92366#获取入群欢迎语素材){:target="_blank"}

  企业可通过此API获取入群欢迎语素材。
  """
  @spec get_group_template(Work.client(), Work.agent(), body :: map) :: WeChat.response()
  def get_group_template(client, agent, body) do
    client.post("/cgi-bin/externalcontact/group_welcome_template/get", body,
      query: [access_token: client.get_access_token(agent)]
    )
  end

  @doc """
  删除入群欢迎语素材 -
  [官方文档](#{@doc_link}/92366#删除入群欢迎语素材){:target="_blank"}

  企业可通过此API删除入群欢迎语素材，且仅能删除调用方自己创建的入群欢迎语素材。
  """
  @spec delete_group_template(Work.client(), Work.agent(), body :: map) :: WeChat.response()
  def delete_group_template(client, agent, body) do
    client.post("/cgi-bin/externalcontact/group_welcome_template/del", body,
      query: [access_token: client.get_access_token(agent)]
    )
  end
end
