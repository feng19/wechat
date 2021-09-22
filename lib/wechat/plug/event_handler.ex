if Code.ensure_loaded?(Plug) do
  defmodule WeChat.Plug.EventHandler do
    @moduledoc """
    微信推送消息处理器

    ## Usage

    将下面的代码加到 `router` 里面：

    - 单一应用的情况：

          forward "/wx/event", #{inspect(__MODULE__)},
            client: WxOfficialAccount,
            event_handler: &YourModule.handle_event/3

    - 多个应用的情况：

      请将入口路径设置为如下格式: `/*xxx/:app`

          scope "/wx/event/:app" do
            forward "/", #{inspect(__MODULE__)}, event_handler: &YourModule.handle_event/3
          end

    ## Options

    - `event_handler`: 必填， `t:#{inspect(__MODULE__)}.event_handler/0`
    - `event_parser`: 可选, `t:#{inspect(__MODULE__)}.event_parser/0`
    - `client`: 可选， `t:WeChat.client/0`
    """

    import Plug.Conn
    require Logger
    alias WeChat.ServerMessage.EventHelper

    @typep timestamp :: integer()
    @typedoc """
    事件处理回调返回值

    返回值说明：
    - `{:reply, xml_string, timestamp}`: 被动回复消息，仅限于公众号/第三方平台
    - `{:reply, json_string}`: 被动回复消息，仅限小程序推送消息
    - `:ok`: 成功
    - `:ignore`: 成功
    - `:retry`: 选择重试，微信服务器会重试三次
    - `:error`: 返回错误，微信服务器会重试三次
    - `{:error, any}`: 返回错误，微信服务器会重试三次
    """
    @type event_handler_return ::
            {:reply, reply_msg :: EventHelper.xml_string(), timestamp}
            | {:reply, reply_msg :: EventHelper.json_string()}
            | :ok
            | :ignore
            | :retry
            | :error
            | {:error, any}
            | Plug.Conn.t()
    @typedoc "事件处理回调函数"
    @type event_handler ::
            (Plug.Conn.t(), WeChat.client(), message :: map -> event_handler_return)
    @typedoc "事件解析函数"
    @type event_parser ::
            :auto
            | :xml
            | :json
            | (params :: map, body :: String.t() | map, WeChat.client() ->
                 {:ok, EventHelper.data_type(), EventHelper.xml() | EventHelper.json()}
                 | {:error, String.t()})

    @doc false
    def init(opts) do
      opts = Map.new(opts)

      event_handler =
        with {:ok, handler} <- Map.fetch(opts, :event_handler),
             true <- is_function(handler, 3) do
          handler
        else
          :error ->
            raise ArgumentError, "please set :event_handler when using #{inspect(__MODULE__)}"

          false ->
            raise ArgumentError,
                  "the :event_handler must arg 4 function when using #{inspect(__MODULE__)}"
        end

      event_parser =
        case Map.fetch(opts, :event_parser) do
          {:ok, parser} when is_function(parser, 4) ->
            parser

          {:ok, :auto} ->
            :auto

          {:ok, :xml} ->
            &EventHelper.parse_json_event/3

          {:ok, :json} ->
            &EventHelper.parse_xml_event/3

          {:ok, _} ->
            raise ArgumentError,
                  "the :event_handler must arg 4 function when using #{inspect(__MODULE__)}"

          :error ->
            :auto
        end

      case Map.fetch(opts, :client) do
        {:ok, client} when is_atom(client) ->
          %{event_parser: event_parser, event_handler: event_handler, client: client}

        _ ->
          %{event_parser: event_parser, event_handler: event_handler}
      end
    end

    @doc false
    def call(%{method: "GET"} = conn, %{client: client}),
      do: validate_request(conn, client.token())

    def call(%{method: "GET", path_params: path_params} = conn, _opts) do
      with app <- path_params["app"],
           client when client != nil <- WeChat.get_client(app) do
        validate_request(conn, client.token())
      else
        _ -> send_resp(conn, 400, "Bad Request") |> halt()
      end
    end

    def call(%{method: "POST"} = conn, %{
          client: client,
          event_parser: event_parser,
          event_handler: event_handler
        }) do
      handle_event_request(conn, client, event_parser, event_handler)
    end

    def call(%{method: "POST", path_params: path_params} = conn, %{
          event_parser: event_parser,
          event_handler: event_handler
        }) do
      with app <- path_params["app"],
           client when client != nil <- WeChat.get_client(app) do
        handle_event_request(conn, client, event_parser, event_handler)
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
    @spec validate_request(Plug.Conn.t(), WeChat.token()) :: Plug.Conn.t()
    def validate_request(conn = %{query_params: query_params}, token) do
      if EventHelper.check_signature?(query_params, token) do
        send_resp(conn, 200, query_params["echostr"])
      else
        send_resp(conn, 400, "Bad Request")
      end
      |> halt()
    end

    def get_event_parser(conn) do
      conn
      |> get_req_header("content-type")
      |> hd()
      |> Plug.Conn.Utils.content_type()
      |> case do
        {:ok, _, "json", _} -> &EventHelper.parse_json_event/3
        _ -> &EventHelper.parse_xml_event/3
      end
    end

    @doc "接受事件推送"
    @spec handle_event_request(Plug.Conn.t(), WeChat.client(), event_parser, event_handler) ::
            Plug.Conn.t()
    def handle_event_request(conn, client, :auto, event_handler) do
      event_parser = get_event_parser(conn)
      handle_event_request(conn, client, event_parser, event_handler)
    end

    def handle_event_request(
          %{query_params: query_params} = conn,
          client,
          event_parser,
          event_handler
        ) do
      with true <- EventHelper.check_signature?(query_params, client.token()),
           {:ok, body, conn} <- check_and_read_body(conn),
           {:ok, reply_type, message} <- event_parser.(query_params, body, client) do
        try do
          event_handler.(conn, client, message)
        rescue
          error ->
            Logger.error(
              "call #{inspect(event_handler)}.(#{inspect(client)}, #{inspect(message)}) get error: #{inspect(error)}"
            )

            send_resp(conn, 500, "Internal Server Error")
        else
          # 被动回复推送消息
          {:reply, xml_string, timestamp} ->
            body = EventHelper.reply_msg(reply_type, xml_string, timestamp, client)
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
