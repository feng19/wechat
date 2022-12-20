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
    |> WeChat.Setup.setup_clients()

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
end
