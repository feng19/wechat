defmodule WeChat.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application
  @app :wechat

  def start(_type, _args) do
    WeChat.Storage.Cache.init_table()
    config = Application.get_all_env(@app) |> normalize()
    config[:clients] |> List.wrap() |> setup_clients()

    children = [
      {Finch, name: WeChat.Finch, pools: %{:default => config[:finch_pool]}},
      {config[:refresher], config[:refresh_settings]}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: WeChat.Supervisor]
    Supervisor.start_link(children, opts)
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
        if hub_springboard_url = settings[:hub_springboard_url] do
          WeChat.set_hub_springboard_url(client, hub_springboard_url)
        end

        if oauth2_callbacks = settings[:oauth2_callbacks] do
          for {env, url} <- oauth2_callbacks, is_binary(env) and is_binary(url) do
            WeChat.set_oauth2_env_url(client, env, url)
          end
        end
      end
    end
  end

  defp setup_work_client(client, agents) do
    for {agent, settings} <- agents do
      if hub_springboard_url = settings[:hub_springboard_url] do
        WeChat.set_hub_springboard_url(client, agent, hub_springboard_url)
      end

      if oauth2_callbacks = settings[:oauth2_callbacks] do
        for {env, url} <- oauth2_callbacks, is_binary(env) and is_binary(url) do
          WeChat.set_oauth2_env_url(client, agent, env, url)
        end
      end
    end
  end
end
