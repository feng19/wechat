defmodule WeChat.Builder.Pay do
  @moduledoc false
  defmacro __using__(options \\ []) do
    check_options!(options, __CALLER__.module)
    options = options |> Macro.prewalk(&Macro.expand(&1, __CALLER__)) |> Map.new()
    requester = Map.get(options, :requester, WeChat.Requester.Pay)
    storage = Map.get(options, :storage, WeChat.Storage.PayFile)
    public_key = WeChat.Pay.Crypto.decode_key(options.client_cert)
    private_key = WeChat.Pay.Crypto.decode_key(options.client_key)

    quote do
      use Supervisor

      @spec start_link(WeChat.Pay.start_options()) :: Supervisor.on_start()
      def start_link(opts) do
        opts = Map.new(opts)
        requester_a = WeChat.Pay.get_requester_spec(:A, __MODULE__, opts.cacerts)
        requester_b = WeChat.Pay.get_requester_spec(:B, __MODULE__, opts.cacerts)
        WeChat.Pay.put_requester_opts(__MODULE__, :A, opts.serial_no)
        refresher = Map.get(opts, :refresher, WeChat.Refresher.Pay)
        children = [{refresher, {__MODULE__, opts}}, requester_a, requester_b]
        opts = [strategy: :one_for_one, name: :"#{__MODULE__}.Supervisor"]
        Supervisor.start_link(children, opts)
      end

      @spec get(url :: binary) :: WeChat.response()
      def get(url), do: get(url, [])

      @spec get(url :: binary, opts :: keyword) :: WeChat.response()
      def get(url, opts) do
        %{name: name, serial_no: serial_no} = WeChat.Pay.get_requester_opts(__MODULE__)

        __MODULE__
        |> unquote(requester).new(__MODULE__, name, serial_no)
        |> Tesla.get(url, opts)
      end

      @spec post(url :: binary, body :: any) :: WeChat.response()
      def post(url, body), do: post(url, body, [])

      @spec post(url :: binary, body :: any, opts :: keyword) :: WeChat.response()
      def post(url, body, opts) do
        %{name: name, serial_no: serial_no} = WeChat.Pay.get_requester_opts(__MODULE__)

        __MODULE__
        |> unquote(requester).new(__MODULE__, name, serial_no)
        |> Tesla.post(url, body, opts)
      end

      @spec mch_id() :: WeChat.Pay.mch_id()
      def mch_id, do: unquote(options.mch_id)
      @spec api_secret_key() :: WeChat.Pay.api_secret_key()
      def api_secret_key, do: unquote(options.api_secret_key)
      @spec storage() :: WeChat.Storage.Adapter.t()
      def storage, do: unquote(storage)
      @spec client_cert() :: WeChat.Pay.client_cert()
      def client_cert, do: unquote(options.client_cert)
      @spec client_key() :: WeChat.Pay.client_key()
      def client_key, do: unquote(options.client_key)

      def public_key, do: unquote(public_key)
      def private_key, do: unquote(private_key)

      def encrypt_secret_data(data) do
        WeChat.Pay.Crypto.encrypt_secret_data(data, unquote(public_key))
      end

      def decrypt_secret_data(cipher_text) do
        WeChat.Pay.Crypto.decrypt_secret_data(cipher_text, unquote(private_key))
      end
    end
  end

  defp check_options!(options, client) do
    unless Keyword.get(options, :mch_id) |> is_binary() do
      raise ArgumentError, "please set mch_id option for #{inspect(client)}"
    end

    unless Keyword.get(options, :api_secret_key) |> is_binary() do
      raise ArgumentError, "please set api_secret_key option for #{inspect(client)}"
    end

    unless Keyword.get(options, :client_cert) |> is_binary() do
      raise ArgumentError, "please set client_cert option for #{inspect(client)}"
    end

    unless Keyword.get(options, :client_key) |> is_binary() do
      raise ArgumentError, "please set client_key option for #{inspect(client)}"
    end
  end
end
