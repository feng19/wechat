defmodule WeChat.Plug.EventHandler do
  @moduledoc """
  微信推送消息处理器

  ## Usage

  - 单一 client：

    ```elixir
    plug WeChat.Plug.EventHandler, client: WxOfficialAccount, handler: &Module:handle_event/2
    ```

  - 兼容多个 client：

    请将入口路径设置为如下格式: `/xxx/:appid/xxx`

    ```elixir
    plug WeChat.Plug.EventHandler, handler: &Module:handle_event/2
    ```

  ## Options

  - `handler`: 必填， `t:WeChat.ServerMessage.EventHandler.handle_event_fun/0`
  - `client`: 可选， `t:WeChat.client/0`
  """

  import Plug.Conn
  alias WeChat.ServerMessage

  def init(opts) do
    opts = Map.new(opts)

    unless Map.has_key?(opts, :handler) do
      raise ArgumentError, "please set :handler when using #{inspect(__MODULE__)}"
    end

    opts
  end

  def call(%{method: "GET", query_params: params} = conn, %{client: client}) do
    {status, resp} = ServerMessage.EventHandler.handle_get(params, client)
    send_resp(conn, status, resp)
  end

  def call(%{method: "GET", query_params: params} = conn, _opts) do
    with appid <- params["appid"],
         client when client != nil <- WeChat.get_client_by_appid(appid) do
      {status, resp} = ServerMessage.EventHandler.handle_get(params, client)
      send_resp(conn, status, resp)
    end
  end

  def call(%{method: "POST"} = conn, %{client: client, handler: handler}) do
    {status, resp} = ServerMessage.EventHandler.handle_post(conn, client, handler)
    send_resp(conn, status, resp)
  end

  def call(%{method: "POST", query_params: params} = conn, %{handler: handler}) do
    with appid <- params["appid"],
         client when client != nil <- WeChat.get_client_by_appid(appid) do
      {status, resp} = ServerMessage.EventHandler.handle_post(conn, client, handler)
      send_resp(conn, status, resp)
    end
  end

  def call(conn, _opts) do
    send_resp(conn, 404, "Invalid Method")
  end
end
