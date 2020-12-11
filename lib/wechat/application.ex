defmodule WeChat.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    finch_pool = Application.get_env(:wechat, :finch_pool, size: 32, count: 8)
    refresh_timer = Application.get_env(:wechat, :refresh_timer, WeChat.RefreshTimer)

    children = [
      {Finch, name: WeChat.Finch, pools: %{:default => finch_pool}},
      refresh_timer
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: WeChat.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
