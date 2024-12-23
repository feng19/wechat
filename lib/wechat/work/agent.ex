defmodule WeChat.Work.Agent do
  @moduledoc "应用"

  alias WeChat.Work
  alias WeChat.ServerMessage.Encryptor
  alias WeChat.Storage.Cache

  @typedoc """
  每个应用都有唯一的 agentid -
  [官方文档](https://developer.work.weixin.qq.com/document/path/90665#agentid)

  在管理后台->“应用与小程序”->“应用”，点进某个应用，即可看到 agentid
  """
  @type agent_id :: integer | atom
  @type agent_name :: atom | String.t()
  @type agent_flag :: agent_id | agent_name
  @typedoc """
  secret 是企业应用里面用于保障数据安全的“钥匙” -
  [官方文档](https://developer.work.weixin.qq.com/document/path/90665#secret)

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
          refresh_list: [],
          cache_id: Cache.cache_id()
        }

  @enforce_keys [:id]
  defstruct [:name, :id, :secret, :token, :encoding_aes_key, :aes_key, :refresh_list, :cache_id]

  @spec find_agent(Work.client(), Work.agent()) :: t | nil
  def find_agent(client, id) when is_integer(id) do
    Enum.find(client.agents(), &match?(%{id: ^id}, &1))
  end

  def find_agent(client, name) do
    Enum.find(client.agents(), &match?(%{name: ^name}, &1))
  end

  @spec find_by_agent_string(Work.client(), agent :: String.t()) :: t | nil
  def find_by_agent_string(client, agent_str) when is_binary(agent_str) do
    Enum.find(client.agents(), fn %{id: id, name: name} ->
      case to_string(id) do
        ^agent_str ->
          true

        _ ->
          case to_string(name) do
            ^agent_str -> true
            _ -> false
          end
      end
    end)
  end

  @spec fetch_agent!(Work.client(), Work.agent()) :: t
  def fetch_agent!(client, agent) do
    if agent = find_agent(client, agent) do
      agent
    else
      raise "missing #{inspect(agent)} for #{inspect(client)}, maybe it's a wrong name or id, maybe it not set in agents."
    end
  end

  @spec fetch_agent_cache_id!(Work.client(), Work.agent()) :: Cache.cache_id()
  def fetch_agent_cache_id!(client, agent) do
    fetch_agent!(client, agent) |> Map.fetch!(:cache_id)
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
    %__MODULE__{id: id, name: id}
    |> struct(options)
    |> transform_aes_key()
  end

  @doc "构建[通讯录]应用(agent)"
  @spec contacts_agent(options) :: t
  def contacts_agent(options \\ []) do
    %__MODULE__{id: :contacts, name: :contacts}
    |> struct(options)
    |> transform_aes_key()
  end

  @doc "构建[客户联系]应用(agent)"
  @spec customer_agent(options) :: t
  def customer_agent(options \\ []) do
    %__MODULE__{id: :customer, name: :customer}
    |> struct(options)
    |> transform_aes_key()
  end

  @doc "构建[微信客服]应用(agent)"
  @spec kf_agent(options) :: t
  def kf_agent(options \\ []) do
    %__MODULE__{id: :kf, name: :kf}
    |> struct(options)
    |> transform_aes_key()
  end

  def maybe_init_work_agents(client) do
    with {:ok, configs} <- Application.fetch_env(:wechat, client),
         agents <- client.agents(),
         {:ok, ^agents} <- Keyword.fetch(configs, :agents),
         true <- Enum.any?(agents, &match?(%{cache_id: nil}, &1)) do
      agents
      |> Enum.all?(&is_struct(&1, __MODULE__))
      |> Kernel.!()
      |> if do
        raise ArgumentError, "please set WeChat.Work.Agent struct for :agents option"
      end

      corp_id = client.appid()

      Enum.map(agents, fn agent ->
        Map.put(agent, :cache_id, "#{corp_id}_#{agent.id}")
      end)
      |> then(&Keyword.put(configs, :agents, &1))
      |> then(&Application.put_env(:wechat, client, &1))
    end
  end

  def append_agent(client, agent) when is_struct(agent, __MODULE__) do
    with {_, nil} <- {:exist, find_agent(client, agent.id)},
         {_, nil} <- {:exist, find_agent(client, agent.name)},
         {:ok, configs} <- Application.fetch_env(:wechat, client),
         {:ok, agents} <- Keyword.fetch(configs, :agents) do
      agent =
        if !agent.cache_id do
          corp_id = client.appid()
          Map.put(agent, :cache_id, "#{corp_id}_#{agent.id}")
        else
          agent
        end

      Keyword.put(configs, :agents, agents ++ [agent])
      |> then(&Application.put_env(:wechat, client, &1))
    else
      {:exist, agent} -> {:error, {:already_exists, agent}}
      config -> {:error, {:wrong_env_config, config}}
    end
  end

  defp transform_aes_key(agent) do
    if is_nil(agent.aes_key) and agent.encoding_aes_key do
      aes_key = Encryptor.aes_key(agent.encoding_aes_key)
      %{agent | aes_key: aes_key}
    else
      agent
    end
  end
end
