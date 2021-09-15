defmodule WeChat.Work.Agent do
  @moduledoc "应用"

  import WeChat.Utils, only: [work_doc_link_prefix: 0]
  alias WeChat.Work

  @term_introduction_doc_link "#{work_doc_link_prefix()}/90000/90135/90665"

  @typedoc """
  每个应用都有唯一的 agentid -
  [官方文档](#{@term_introduction_doc_link}#agentid)

  在管理后台->“应用与小程序”->“应用”，点进某个应用，即可看到 agentid
  """
  @type agent_id :: integer | atom
  @type agent_name :: atom | String.t()
  @typedoc """
  secret 是企业应用里面用于保障数据安全的“钥匙” -
  [官方文档](#{@term_introduction_doc_link}#secret)

  每一个应用都有一个独立的访问密钥，为了保证数据的安全，secret务必不能泄漏。
  目前 `secret` 有：

  - 自建应用 `secret`
    在管理后台->“应用与小程序”->“应用”->“自建”，点进某个应用，即可看到。
  - 基础应用 `secret`
    某些基础应用（如“审批”“打卡”应用），支持通过API进行操作。在管理后台->“应用与小程序”->“应用->”“基础”，点进某个应用，点开“API”小按钮，即可看到。
  - 通讯录管理 `secret`
    在“管理工具”-“通讯录同步”里面查看（需开启“API接口同步”）；
  - 外部联系人管理 `secret`
    在“客户联系”栏，点开“API”小按钮，即可看到。
  """
  @type secret :: String.t()

  @typedoc "应用配置"
  @type t :: %__MODULE__{
          id: agent_id,
          name: agent_name,
          secret: secret,
          encoding_aes_key: WeChat.ServerMessage.Encryptor.encoding_aes_key(),
          token: WeChat.token()
        }

  @enforce_keys [:id]
  defstruct [:name, :id, :secret, :encoding_aes_key, :token]

  @spec name2id(Work.client(), agent_name) :: agent_id | nil
  def name2id(client, name) do
    with %{id: id} <- Enum.find(client.agents(), &match?(%{name: ^name}, &1)) do
      id
    end
  end

  @spec agent2id(Work.client(), Work.agent()) :: agent_id | nil
  def agent2id(_client, id) when is_integer(id), do: id
  def agent2id(client, name), do: name2id(client, name)

  @doc "通讯录应用"
  @spec contacts_agent(options :: Keyword.t()) :: t
  def contacts_agent(options \\ []) do
    struct(%__MODULE__{id: :contacts, name: :contacts}, options)
  end

  @doc "客户联系应用"
  @spec customer_agent(options :: Keyword.t()) :: t
  def customer_agent(options \\ []) do
    struct(%__MODULE__{id: :customer, name: :customer}, options)
  end
end
