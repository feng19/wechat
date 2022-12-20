defmodule WeChat.Setup do
  @moduledoc "Setup WeChat clients"
  alias WeChat.{Work, HubClient, HubServer}
  alias Work.Agent, as: WorkAgent

  @type options :: %{
          optional(:hub_springboard_url) => HubClient.hub_springboard_url(),
          optional(:oauth2_callbacks) => HubServer.oauth2_callbacks()
        }
  @type work_options :: %{all: options} | [all: options] | [{Work.agent(), options}]

  @app :wechat

  @spec setup_clients([{WeChat.client(), options | work_options}]) :: list
  def setup_clients(clients) do
    for {client, options} <- clients, is_atom(client) do
      if match?(:work, client.app_type()) do
        setup_work_client(client, _agents = options)
      else
        setup_client(client, options)
      end
    end
  end

  @spec setup_client(WeChat.client(), options | work_options) :: :ok
  def setup_client(client, options) do
    %{hub_springboard_url: hub_springboard_url, oauth2_callbacks: oauth2_callbacks} =
      replace_app(options, client)

    # hub_springboard_url set for hub client
    if hub_springboard_url do
      HubClient.set_hub_springboard_url(client, hub_springboard_url)
    end

    # oauth2_callbacks set for hub server
    if oauth2_callbacks do
      HubServer.set_oauth2_callbacks(client, oauth2_callbacks)
    end

    :ok
  end

  @spec setup_work_client(WeChat.client(), work_options) :: :ok
  def setup_work_client(client, %{all: options}) do
    setup_work_client(client, all: options)
  end

  def setup_work_client(client, all: options) do
    agents = Enum.map(client.agents(), fn %{id: id, name: name} -> {name || id, options} end)
    setup_work_client(client, agents)
  end

  def setup_work_client(client, agents) do
    WorkAgent.maybe_init_work_agents(client)

    for {agent, options} <- agents do
      setup_work_agent(client, agent, options)
    end

    :ok
  end

  @spec setup_work_agent(WeChat.client(), Work.agent() | WorkAgent.t(), options) :: :ok
  def setup_work_agent(client, agent, options) when is_struct(agent, WorkAgent) do
    setup_work_agent(client, agent.name || agent.id, options)
  end

  def setup_work_agent(client, agent, options) do
    %{hub_springboard_url: hub_springboard_url, oauth2_callbacks: oauth2_callbacks} =
      options |> replace_app(client) |> replace_agent(agent)

    # hub_springboard_url set for hub client
    if hub_springboard_url do
      HubClient.set_hub_springboard_url(client, agent, hub_springboard_url)
    end

    # oauth2_callbacks set for hub server
    if oauth2_callbacks do
      HubServer.set_oauth2_callbacks(client, agent, oauth2_callbacks)
    end

    :ok
  end

  defp replace_app(options, client) do
    env = Application.get_env(@app, :env, "dev") |> to_string()

    options
    |> Map.new()
    |> Enum.into(%{hub_springboard_url: nil, oauth2_callbacks: nil})
    |> replace(":app", client.code_name())
    |> replace_hub_springboard_url(":env", env)
  end

  defp replace_agent(options, agent), do: replace(options, ":agent", to_string(agent))

  defp replace(
         %{hub_springboard_url: hub_springboard_url, oauth2_callbacks: oauth2_callbacks},
         match,
         replacement
       ) do
    hub_springboard_url =
      if hub_springboard_url do
        String.replace(hub_springboard_url, match, replacement)
      end

    oauth2_callbacks =
      if oauth2_callbacks do
        for {env, url} <- oauth2_callbacks do
          {env, String.replace(url, match, replacement)}
        end
      end

    %{hub_springboard_url: hub_springboard_url, oauth2_callbacks: oauth2_callbacks}
  end

  defp replace_hub_springboard_url(
         %{hub_springboard_url: hub_springboard_url} = options,
         match,
         replacement
       ) do
    if hub_springboard_url do
      %{options | hub_springboard_url: String.replace(hub_springboard_url, match, replacement)}
    else
      options
    end
  end
end
