defmodule WeChat.Utils do
  @moduledoc false

  @random_alphanumeric Enum.concat([?a..?z, ?A..?Z, 48..57])
  @type timestamp :: integer

  if Mix.env() == :test do
    def default_adapter, do: Tesla.Mock
  else
    def default_adapter,
      do: {Tesla.Adapter.Finch, name: WeChat.Finch, pool_timeout: 5_000, receive_timeout: 5_000}
  end

  @spec random_string(length :: integer) :: String.t()
  def random_string(length) when length > 0 do
    @random_alphanumeric
    |> Enum.take_random(length)
    |> List.to_string()
  end

  @spec now_unix :: timestamp
  def now_unix, do: System.system_time(:second)

  def doc_link_prefix, do: "https://developers.weixin.qq.com"
  def work_doc_link_prefix, do: "https://developer.work.weixin.qq.com/document/path"
  def work_kf_doc_link_prefix, do: "https://open.work.weixin.qq.com/kf/doc/92512/93143"
  def pay_doc_link_prefix, do: "https://pay.weixin.qq.com/docs"
  def pay_v2_doc_link_prefix, do: "https://pay.weixin.qq.com/wiki/doc"

  @spec sha1([String.t()] | String.t()) :: signature :: String.t()
  def sha1(list) when is_list(list) do
    Enum.sort(list) |> Enum.join() |> sha1()
  end

  def sha1(string) when is_binary(string) do
    :crypto.hash(:sha, string) |> Base.encode16(case: :lower)
  end

  defmacro def_eex({name, _, args}, do: source) do
    args = Enum.map(args, &elem(&1, 0))

    quote do
      require EEx

      EEx.function_from_string(
        :def,
        unquote(name),
        String.replace(unquote(source), ["\n", "\n  ", "\n    ", "\n      "], ""),
        unquote(args)
      )
    end
  end

  def transfer_clients(opts, plug) do
    Map.get(opts, :clients)
    |> List.wrap()
    |> case do
      [] -> raise ArgumentError, "please set clients when using #{inspect(plug)}"
      list -> list
    end
    |> Enum.reduce(%{}, &transfer_client/2)
  end

  def transfer_clients(clients) do
    Enum.reduce(clients, %{}, &transfer_client/2)
  end

  def transfer_client(client) do
    transfer_client(client, [])
  end

  defp transfer_client(client, acc) when is_atom(client) do
    if match?(:work, client.app_type()) do
      transfer_client({client, :all}, acc)
    else
      transfer_client({client, nil}, acc)
    end
  end

  defp transfer_client({client, :all}, acc) do
    agents = Enum.map(client.agents(), & &1.id)
    transfer_client({client, agents}, acc)
  end

  defp transfer_client({client, agents}, acc) do
    value =
      if match?(:work, client.app_type()) do
        agents = agents |> List.wrap() |> Enum.uniq()
        agent_flag_list = transfer_agents(client, agents) |> Enum.sort()

        if Enum.empty?(agent_flag_list) do
          raise ArgumentError, "please set agents for client: #{inspect(client)}"
        end

        {client, agent_flag_list}
      else
        client
      end

    Enum.into([{client.appid(), value}, {client.code_name(), value}], acc)
  end

  defp transfer_agents(client, agents) when is_list(agents) do
    Enum.reduce(client.agents(), [], fn agent, acc ->
      agent_id = agent.id
      name = agent.name

      if agent_id in agents or name in agents do
        Enum.uniq([agent_id, name, to_string(agent_id), to_string(name)]) ++ acc
      else
        acc
      end
    end)
  end

  def uniq_and_sort(list) do
    list |> Enum.uniq() |> Enum.sort()
  end
end
