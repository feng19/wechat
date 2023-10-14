if Code.ensure_loaded?(Plug) do
  defmodule WeChat.Pay.EventHandler do
    @moduledoc """
    微信支付 回调通知处理器

    [官方文档](https://pay.weixin.qq.com/docs/merchant/apis/jsapi-payment/payment-notice.html)

        ** 注意 **

        对后台通知交互时，如果微信收到应答不是成功或超时，微信认为通知失败，
        微信会通过一定的策略定期重新发起通知，尽可能提高通知的成功率，但微信不保证通知最终能成功

        同样的通知可能会多次发送给商户系统。商户系统必须能够正确处理重复的通知。
        推荐的做法是，当商户系统收到通知进行处理时，先检查对应业务数据的状态，
        并判断该通知是否已经处理。如果未处理，则再进行处理；如果已处理，则直接返回结果成功。
        在对业务数据进行状态检查和处理之前，要采用数据锁进行并发控制，以避免函数重入造成的数据混乱。

        如果在所有通知频率后没有收到微信侧回调。商户应调用查询订单接口确认订单状态。

    ## 通知规则

    用户支付完成后，微信会把相关支付结果和用户信息发送给商户，商户需要接收处理该消息，并返回应答。

    对后台通知交互时，如果微信收到商户的应答不符合规范或超时，微信认为通知失败，微信会通过一定的策略定期重新发起通知，尽可能提高通知的成功率，
    但微信不保证通知最终能成功。

    通知频率为 `15s`/`15s`/`30s`/`3m`/`10m`/`20m`/`30m`/`30m`/`30m`/`60m`/`3h`/`3h`/`3h`/`6h`/`6h` - 总计 `24h4m`

    ## Usage

    ### For Plug

        defmodule YourAppWeb.PayEventRouter do
          use Plug.Router

          plug :match
          plug :dispatch

          Code.ensure_compiled!(WechatPayDemo.PayClient)

          post "/api/pay/callback",
            to: #{inspect(__MODULE__)},
            init_opts: [client: WxPay, event_handler: &YourModule.handle_event/2]

          match _, do: conn
        end

    ### For Phoenix

    建议是定义一个上方的 `PayEventRouter`, 然后接入到 `endpoint` 中 `plug Plug.Parsers` 的上一行:

        defmodule YourAppWeb.Endpoint do
          # ...
          plug Plug.RequestId
          plug Plug.Telemetry, event_prefix: [:phoenix, :endpoint]
          plug YourAppWeb.PayEventRouter # <<== add to here, before Plug.Parsers

          plug Plug.Parsers,
            parsers: [:urlencoded, :multipart, :json],
            pass: ["*/*"],
            json_decoder: Phoenix.json_library()

          plug Plug.MethodOverride
          plug Plug.Head
          plug Plug.Session, @session_options
          plug YourAppWeb.Router
          # ...
        end

    ** 注意 **, `Plug.Parsers` 会解析 `body`, 请确保此 `plug` 传入的 `body` 为 `binary` 格式, 否则将会导致验签失败

    如果确认 `body` 未被解析, 亦可使用下面方式接入到 `router` 里面:

        post "/wx/pay/event", #{inspect(__MODULE__)},
          client: WxPay,
          event_handler: &YourModule.handle_event/2

    before phoenix 1.17:

        forward "/wx/pay/event", #{inspect(__MODULE__)},
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
              data =
                Crypto.decrypt_aes_256_gcm(client, ciphertext, associated_data, iv)
                |> Jason.decode!()

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
        b when is_struct(b) ->
          with {:ok, body, conn} when is_binary(body) <- read_body(conn),
               {:ok, body_map} when is_map(body_map) <- Jason.decode(body) do
            {:ok, body, body_map, conn}
          else
            _ -> :bad_request
          end

        body when is_binary(body) ->
          case Jason.decode(body) do
            {:ok, body_map} when is_map(body_map) -> {:ok, body, body_map, conn}
            _ -> :bad_request
          end

        body when is_map(body) ->
          Logger.warning(
            "#{inspect(__MODULE__)} handle parsed body: #{inspect(body)}, please use origin body."
          )

          :bad_request
      end
    end
  end
end
