if Code.ensure_loaded?(Plug) do
  defmodule WeChat.Plug.WorkEventHandler do
    @moduledoc """
    企业微信推送消息处理器

    ## Usage

    请将入口路径设置为如下格式 `/*xxx/:app/:agent` 并将代码加到 `router` 里面：

        scope "/wx/event/:app/:agent" do
          forward "/", #{inspect(__MODULE__)}, event_handler: &YourModule.handle_event/4
        end

    ## Options

    - `event_handler`: 必填, [定义](`t:event_handler/0`)
    - `event_parser`: 可选, [定义](`t:event_parser/0`),
      默认值: [&ServerMessage.EventHelper.parse_work_xml_event/4](`WeChat.ServerMessage.EventHelper.parse_work_xml_event/4`)
    """

    import Plug.Conn
    require Logger
    alias WeChat.Work.Agent
    alias WeChat.Plug.EventHandler
    alias WeChat.ServerMessage.{EventHelper, Encryptor}
    @behaviour Plug

    @typedoc "事件处理回调函数"
    @type event_handler ::
            (Plug.Conn.t(), WeChat.client(), Agent.t(), message :: map ->
               EventHandler.event_handler_return())
    @typedoc "事件解析函数"
    @type event_parser ::
            (params :: map, body :: String.t() | map, WeChat.client(), Agent.t() ->
               {:ok, EventHelper.data_type(), EventHelper.xml() | EventHelper.json()}
               | {:error, String.t()})

    @doc false
    def init(opts) do
      opts = Map.new(opts)

      event_handler =
        with {:ok, handler} <- Map.fetch(opts, :event_handler),
             true <- is_function(handler, 4) do
          handler
        else
          :error ->
            raise ArgumentError, "please set :event_handler when using #{inspect(__MODULE__)}"

          false ->
            raise ArgumentError,
                  "the :event_handler must arg 4 function when using #{inspect(__MODULE__)}"
        end

      event_parser =
        with {:ok, parser} <- Map.fetch(opts, :event_parser),
             true <- is_function(parser, 4) do
          parser
        else
          :error ->
            &EventHelper.parse_work_xml_event/4

          false ->
            raise ArgumentError,
                  "the :event_parser must arg 4 function when using #{inspect(__MODULE__)}"
        end

      %{event_handler: event_handler, event_parser: event_parser}
    end

    def call(%{method: "GET", path_params: path_params} = conn, _opts) do
      with %{"app" => app, "agent" => agent_str} <- path_params,
           {client, agent} <- WeChat.get_client_agent(app, agent_str) do
        validate_encrypted_request(conn, client.appid(), agent.token, agent.aes_key)
      else
        _ -> send_resp(conn, 400, "Bad Request") |> halt()
      end
    end

    def call(%{method: "POST", path_params: path_params} = conn, opts) do
      with %{"app" => app, "agent" => agent_str} <- path_params,
           {client, agent} <- WeChat.get_client_agent(app, agent_str) do
        handle_event_request(conn, client, agent, opts.event_parser, opts.event_handler)
      else
        _ -> send_resp(conn, 400, "Bad Request") |> halt()
      end
    end

    def call(conn, _opts) do
      send_resp(conn, 404, "Invalid Method") |> halt()
    end

    @doc """
    验证消息的确来自微信服务器
    """
    @spec validate_encrypted_request(
            Plug.Conn.t(),
            id :: String.t(),
            WeChat.token(),
            Encryptor.aes_key()
          ) :: Plug.Conn.t()
    def validate_encrypted_request(conn = %{query_params: query_params}, id, token, aes_key) do
      with echo_str when echo_str != nil <- query_params["echostr"],
           true <- EventHelper.check_msg_signature?(echo_str, query_params, token),
           {^id, message} <- Encryptor.decrypt(echo_str, aes_key) do
        send_resp(conn, 200, message)
      else
        _ -> send_resp(conn, 400, "Bad Request")
      end
      |> halt()
    end

    @doc "接受事件推送"
    @spec handle_event_request(
            Plug.Conn.t(),
            WeChat.client(),
            Agent.t(),
            event_parser,
            event_handler
          ) :: Plug.Conn.t()
    def handle_event_request(
          %{query_params: query_params} = conn,
          client,
          agent,
          event_parser,
          event_handler
        ) do
      with {:ok, body, conn} <- check_and_read_body(conn),
           {:ok, reply_type, message} <- event_parser.(query_params, body, client, agent) do
        try do
          event_handler.(conn, client, agent, message)
        rescue
          error ->
            Logger.error(
              "call #{inspect(event_handler)}.(#{inspect(client)}, #{inspect(message)}) get error: #{inspect(error)}"
            )

            send_resp(conn, 500, "Internal Server Error")
        else
          # 被动回复推送消息
          {:reply, xml_string, timestamp} ->
            body = EventHelper.reply_msg(reply_type, xml_string, timestamp, client, agent)
            send_resp(conn, 200, body)

          {:reply, body} ->
            send_resp(conn, 200, body)

          :retry ->
            send_resp(conn, 500, "please retry")

          :error ->
            send_resp(conn, 500, "error, please retry")

          {:error, _} ->
            send_resp(conn, 500, "error, please retry")

          :ok ->
            send_resp(conn, 200, "success")

          :ignore ->
            send_resp(conn, 200, "success")

          conn ->
            conn
        end
      else
        _ -> send_resp(conn, 400, "Bad Request")
      end
      |> halt()
    end

    defp check_and_read_body(%{body_params: body_params} = conn) when is_struct(body_params),
      do: read_body(conn)

    defp check_and_read_body(conn), do: {:ok, conn.body_params, conn}
  end
end
