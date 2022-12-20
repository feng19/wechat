defmodule WeChat.Setup do
  @moduledoc false
  alias WeChat.Work.Agent, as: WorkAgent

  @type options :: %{
          optional(:hub_springboard_url) => WeChat.hub_springboard_url(),
          optional(:oauth2_callbacks) => WeChat.oauth2_callbacks()
        }

  @app :wechat

  def setup_clients(clients) do
    for {client, settings} <- clients, is_atom(client) do
      if match?(:work, client.app_type()) do
        setup_work_client(client, _agents = settings)
      else
        setup_client(client, settings)
      end
    end
  end

  def setup_client(client, settings) do
    %{hub_springboard_url: hub_springboard_url, oauth2_callbacks: oauth2_callbacks} =
      replace_app(settings, client)

    # hub_springboard_url set for hub client
    if hub_springboard_url do
      WeChat.set_hub_springboard_url(client, hub_springboard_url)
    end

    # oauth2_callbacks set for hub server
    if oauth2_callbacks do
      WeChat.set_oauth2_callbacks(client, oauth2_callbacks)
    end
  end

  def setup_work_client(client, %{all: settings}) do
    setup_work_client(client, all: settings)
  end

  def setup_work_client(client, all: settings) do
    agents = Enum.map(client.agents(), fn %{id: id, name: name} -> {name || id, settings} end)
    setup_work_client(client, agents)
  end

  def setup_work_client(client, agents) do
    WorkAgent.maybe_init_work_agents(client)

    for {agent, settings} <- agents do
      setup_work_agent(client, agent, settings)
    end
  end

  def setup_work_agent(client, agent, settings) when is_struct(agent, WorkAgent) do
    setup_work_agent(client, agent.name || agent.id, settings)
  end

  def setup_work_agent(client, agent, settings) do
    %{hub_springboard_url: hub_springboard_url, oauth2_callbacks: oauth2_callbacks} =
      settings |> replace_app(client) |> replace_agent(agent)

    # hub_springboard_url set for hub client
    if hub_springboard_url do
      WeChat.set_hub_springboard_url(client, agent, hub_springboard_url)
    end

    # oauth2_callbacks set for hub server
    if oauth2_callbacks do
      WeChat.set_oauth2_callbacks(client, agent, oauth2_callbacks)
    end
  end

  def replace_app(settings, client) do
    env = Application.get_env(@app, :env, "dev") |> to_string()

    settings
    |> Map.new()
    |> Enum.into(%{hub_springboard_url: nil, oauth2_callbacks: nil})
    |> replace(":app", client.code_name())
    |> replace_hub_springboard_url(":env", env)
  end

  def replace_agent(settings, agent), do: replace(settings, ":agent", to_string(agent))

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

  def replace_hub_springboard_url(
        %{hub_springboard_url: hub_springboard_url} = settings,
        match,
        replacement
      ) do
    if hub_springboard_url do
      %{settings | hub_springboard_url: String.replace(hub_springboard_url, match, replacement)}
    else
      settings
    end
  end
end
