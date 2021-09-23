defmodule WeChat.Storage.HttpForHubClient do
  @moduledoc """
  通过 Http 获取 Hub 的 token 等，仅用于 hub_client

  此模块使用 basic_auth 鉴权，如果需要其他鉴权方式，请参照自行实现

      config :wechat, #{inspect(__MODULE__)}, [
        hub_base_url: "http://hub.example.com",
        username: "username",
        password: "password"
      ]
  """
  alias WeChat.Storage.Adapter
  @behaviour WeChat.Storage.Adapter

  @app :wechat

  @impl true
  @spec store(Adapter.store_id(), Adapter.store_key(), Adapter.value()) :: :ok | any
  def store(_store_id, _store_key, _value) do
    {:error, "Did not supported store value, this storage only used for hub_client."}
  end

  @impl true
  @spec restore(Adapter.store_id(), Adapter.store_key()) :: {:ok, Adapter.value()} | any
  def restore(store_id, store_key) do
    %{hub_base_url: hub_base_url, username: username, password: password} =
      Application.get_env(@app, __MODULE__) |> Map.new()

    authorization = Plug.BasicAuth.encode_basic_auth(username, password)

    Tesla.client(
      [
        {Tesla.Middleware.BaseUrl, hub_base_url},
        {Tesla.Middleware.Headers, [{"authorization", authorization}]},
        Tesla.Middleware.DecodeJson,
        Tesla.Middleware.Logger
      ],
      {Tesla.Adapter.Finch, name: WeChat.Finch, pool_timeout: 5_000, receive_timeout: 5_000}
    )
    |> Tesla.get("/#{store_id}/#{store_key}")
    |> case do
      {:ok, %{status: 200, body: %{"error" => 0, "value" => value}}} -> {:ok, value}
      {:ok, %{status: 200, body: %{"msg" => error_msg}}} -> {:error, error_msg}
      _ -> {:error, "request error"}
    end
  end
end
