if Code.ensure_loaded?(Plug) do
  defmodule WeChat.Pay.EventHandler do
    @moduledoc """
    微信支付 回调通知处理器

    ** 注意 **, 定义 `client` 时必须设置: `encoding_aes_key` & `token`

    ## Usage

    将下面的代码加到 `router` 里面：

        post "/wx/pay/event", #{inspect(__MODULE__)},
          client: WxPay,
          event_handler: &YourModule.handle_event/2

    before phoenix 1.17:

        forward "/wx/event/:app", #{inspect(__MODULE__)},
          client: WxPay,
          event_handler: &YourModule.handle_event/2

    ## Options

    - `event_handler`: 必填, [定义](`t:#{inspect(__MODULE__)}.event_handler/0`)
    - `client`: 必填, [定义](`t:WeChat.Pay.client/0`)
    """
    import Plug.Conn
    require Logger
    alias WeChat.Pay.{Crypto, Certificates}
    @behaviour Plug

    @typedoc """
    事件处理回调返回值

    返回值说明：
    - `:ok`: 成功
    - `:error`: 返回错误
    - `{:error, any}`: 返回错误
    """
    @type event_handler_return :: :ok | :error | {:error, any} | Plug.Conn.t()
    @typedoc "事件处理回调函数"
    @type event_handler :: (Plug.Conn.t(), message :: map -> event_handler_return)

    @doc false
    def init(opts) do
      opts = Map.new(opts)

      event_handler =
        with {:ok, handler} <- Map.fetch(opts, :event_handler),
             true <- is_function(handler, 2) do
          handler
        else
          :error ->
            raise ArgumentError, "please set :event_handler when using #{inspect(__MODULE__)}"

          false ->
            raise ArgumentError,
                  "the :event_handler must arg 2 function when using #{inspect(__MODULE__)}"
        end

      case Map.fetch(opts, :client) do
        {:ok, client} when is_atom(client) ->
          if function_exported?(client, :api_secret_key, 0) do
            %{event_handler: event_handler, client: client}
          else
            raise ArgumentError, "please set WeChat.Pay :client when using #{inspect(__MODULE__)}"
          end

        _ ->
          raise ArgumentError, "please set :client when using #{inspect(__MODULE__)}"
      end
    end

    @doc false
    def call(%{method: "POST"} = conn, %{client: client, event_handler: event_handler}) do
      handle_event_request(conn, client, event_handler)
    end

    def call(conn, _), do: json(conn, 400, %{"code" => "FAIL", "message" => "Bad Request"})

    def handle_event_request(conn, client, event_handler) do
      with nonce when is_binary(nonce) <- get_header(conn, "wechatpay-nonce"),
           signature when is_binary(signature) <- get_header(conn, "wechatpay-signature"),
           timestamp when is_binary(timestamp) <- get_header(conn, "wechatpay-timestamp"),
           serial_no when is_binary(serial_no) <- get_header(conn, "wechatpay-serial"),
           public_key when not is_nil(public_key) <- Certificates.get_cert(client, serial_no),
           {:ok, body, body_map, conn} <- check_and_read_body(conn),
           true <- Crypto.verify(signature, timestamp, nonce, body, public_key) do
        try do
          case body_map do
            %{
              "resource_type" => "encrypt-resource",
              "resource" => %{
                "algorithm" => "AEAD_AES_256_GCM",
                "nonce" => iv,
                "ciphertext" => ciphertext,
                "associated_data" => associated_data
              }
            } = message ->
              data = Crypto.decrypt_aes_256_gcm(client, ciphertext, associated_data, iv) |> Jason.decode!()
              event_handler.(conn, Map.put(message, "data", data))

            message ->
              event_handler.(conn, message)
          end
        rescue
          error ->
            Logger.error(
              "Handle request for #{inspect(client)} failed!!! body:#{body}, error: #{inspect(error)}"
            )

            json(conn, 500, %{"code" => "FAIL", "message" => "Internal Server Error"})
        else
          :ok -> send_resp(conn, 200, "")
          :error -> json(conn, 500, %{"code" => "FAIL", "message" => "Unexpected Error"})
          {:error, _} -> json(conn, 500, %{"code" => "FAIL", "message" => "Internal Error"})
          conn -> conn
        end
      else
        _ -> json(conn, 400, %{"code" => "FAIL", "message" => "Bad Request"})
      end
      |> halt()
    end

    defp get_header(conn, key) do
      case get_req_header(conn, key) do
        [v | _] -> v
        [] -> nil
      end
    end

    defp json(conn, status, data) do
      conn |> put_resp_content_type("application/json") |> send_resp(status, Jason.encode!(data))
    end

    defp check_and_read_body(%{body_params: body_params} = conn) do
      case body_params do
        body_map when is_map(body_map) ->
          {:ok, Jason.encode!(body_map), body_map, conn}

        body when is_binary(body) ->
          case Jason.encode(body) do
            {:ok, body_map} when is_map(body_map) -> {:ok, body, body_map, conn}
            _ -> :bad_request
          end

        b when is_struct(b) ->
          with {:ok, body, conn} when is_binary(body) <- read_body(conn),
               {:ok, body_map} when is_map(body_map) <- Jason.encode(body) do
            {:ok, body, body_map, conn}
          else
            _ -> :bad_request
          end
      end
    end
  end
end
