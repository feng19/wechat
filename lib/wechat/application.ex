defmodule WeChat.Application do
  @moduledoc false

  use Application
  @app :wechat

  def start(_type, _args) do
    WeChat.Storage.Cache.init_table()
    config = Application.get_all_env(@app) |> normalize()

    config[:clients]
    |> case do
      clients when is_map(clients) -> Map.to_list(clients)
      clients -> List.wrap(clients)
    end
    |> setup_clients()

    children = [
      {Finch, name: WeChat.Finch, pools: %{:default => config[:finch_pool]}},
      {config[:refresher], config[:refresh_settings]},
      {WeChat.TokenChecker, config[:token_checker]}
    ]

    Supervisor.start_link(children, strategy: :one_for_one, name: WeChat.Supervisor)
  end

  defp normalize(config) do
    Keyword.merge(
      [
        finch_pool: [size: 32, count: 8],
        refresher: WeChat.Refresher.Default,
        refresh_settings: %{},
        clients: []
      ],
      config
    )
  end

  defp setup_clients(clients) do
    for {client, settings} <- clients, is_atom(client) do
      if match?(:work, client.app_type()) do
        setup_work_client(client, _agents = settings)
      else
        setup_client(client, settings)
      end
    end
  end

  defp setup_client(client, settings) do
    %{hub_springboard_url: hub_springboard_url, oauth2_callbacks: oauth2_callbacks} =
      replace_app(settings, client)

    # hub_springboard_url set for hub client
    if hub_springboard_url do
      WeChat.set_hub_springboard_url(client, hub_springboard_url)
    end

    # oauth2_callbacks set for hub server
    if oauth2_callbacks do
      for {env, url} <- oauth2_callbacks, is_binary(env) and is_binary(url) do
        WeChat.set_oauth2_env_url(client, env, url)
      end
    end
  end

  defp setup_work_client(client, %{all: settings}) do
    setup_work_client(client, all: settings)
  end

  defp setup_work_client(client, all: settings) do
    agents = Enum.map(client.agents(), fn %{id: id, name: name} -> {name || id, settings} end)
    setup_work_client(client, agents)
  end

  defp setup_work_client(client, agents) do
    for {agent, settings} <- agents do
      %{hub_springboard_url: hub_springboard_url, oauth2_callbacks: oauth2_callbacks} =
        settings |> replace_app(client) |> replace_agent(agent)

      # hub_springboard_url set for hub client
      if hub_springboard_url do
        WeChat.set_hub_springboard_url(client, agent, hub_springboard_url)
      end

      # oauth2_callbacks set for hub server
      if oauth2_callbacks do
        for {env, url} <- oauth2_callbacks, is_binary(env) and is_binary(url) do
          WeChat.set_oauth2_env_url(client, agent, env, url)
        end
      end
    end
  end

  defp replace_app(settings, client) do
    env = Application.get_env(@app, :env, "dev") |> to_string()

    settings
    |> Map.new()
    |> Enum.into(%{hub_springboard_url: nil, oauth2_callbacks: nil})
    |> replace(":app", client.code_name())
    |> replace_hub_springboard_url(":env", env)
  end

  defp replace_agent(settings, agent), do: replace(settings, ":agent", to_string(agent))

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
