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
      if hub_url = settings[:hub_url] do
        WeChat.set_hub_url(client, hub_url)
      end

      if oauth2_callbacks = settings[:oauth2_callbacks] do
        for {env, callback} <- oauth2_callbacks, is_binary(env) and is_binary(callback) do
          WeChat.set_oauth2_env_url(client, env, callback)
        end
      end
    end
  end
end
