defmodule WeChat.Work.Agent do
  @moduledoc "应用"

  import WeChat.Utils, only: [work_doc_link_prefix: 0]
  alias WeChat.Work
  alias WeChat.ServerMessage.Encryptor

  @term_introduction_doc_link "#{work_doc_link_prefix()}/90135/90665"

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
  - 客户联系管理 `secret`
    在“客户联系”栏，点开“API”小按钮，即可看到。
  """
  @type secret :: String.t()
  @type options :: Keyword.t()
  @type refresh_key :: :js_api_ticket | :agent_js_api_ticket
  @type refresh_list :: [refresh_key]

  @typedoc "应用配置"
  @type t :: %__MODULE__{
          id: agent_id,
          name: agent_name,
          secret: secret,
          token: WeChat.token(),
          encoding_aes_key: Encryptor.encoding_aes_key(),
          aes_key: Encryptor.aes_key(),
          refresh_list: []
        }

  @enforce_keys [:id]
  defstruct [:name, :id, :secret, :token, :encoding_aes_key, :aes_key, :refresh_list]

  @spec find_agent(Work.client(), Work.agent()) :: t | nil
  def find_agent(client, id) when is_integer(id) do
    Enum.find(client.agents(), &match?(%{id: ^id}, &1))
  end

  def find_agent(client, name) do
    Enum.find(client.agents(), &match?(%{name: ^name}, &1))
  end

  @spec name2id(Work.client(), agent_name) :: agent_id | nil
  def name2id(client, name) do
    with %{id: id} <- Enum.find(client.agents(), &match?(%{name: ^name}, &1)) do
      id
    end
  end

  @spec agent2id(Work.client(), Work.agent()) :: agent_id | nil
  def agent2id(_client, id) when is_integer(id), do: id
  def agent2id(client, name), do: name2id(client, name)

  @doc "构建应用(agent)"
  @spec agent(agent_id, options) :: t
  def agent(id, options \\ []) do
    struct(%__MODULE__{id: id, name: id}, options)
    |> transfer_aes_key()
  end

  @doc "构建[通讯录]应用(agent)"
  @spec contacts_agent(options) :: t
  def contacts_agent(options \\ []) do
    struct(%__MODULE__{id: :contacts, name: :contacts}, options)
    |> transfer_aes_key()
  end

  @doc "构建[客户联系]应用(agent)"
  @spec customer_agent(options) :: t
  def customer_agent(options \\ []) do
    struct(%__MODULE__{id: :customer, name: :customer}, options)
    |> transfer_aes_key()
  end

  @doc "构建[微信客服]应用(agent)"
  @spec kf_agent(options) :: t
  def kf_agent(options \\ []) do
    struct(%__MODULE__{id: :kf, name: :kf}, options)
    |> transfer_aes_key()
  end

  defp transfer_aes_key(agent) do
    if is_nil(agent.aes_key) and agent.encoding_aes_key do
      aes_key = Encryptor.aes_key(agent.encoding_aes_key)
      %{agent | aes_key: aes_key}
    else
      agent
    end
  end
end
