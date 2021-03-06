defmodule WeChat.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    WeChat.Storage.Cache.init_table()
    finch_pool = Application.get_env(:wechat, :finch_pool, size: 32, count: 8)

    refresher = WeChat.get_refresher()
    refresh_settings = Application.get_env(:wechat, :refresh_settings, %{})

    children = [
      {Finch, name: WeChat.Finch, pools: %{:default => finch_pool}},
      {refresher, refresh_settings}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: WeChat.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
