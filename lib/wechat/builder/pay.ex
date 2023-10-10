defmodule WeChat.Builder.Pay do
  @moduledoc false
  defmacro __using__(options \\ []) do
    check_options!(options, __CALLER__.module)
    options = options |> Macro.prewalk(&Macro.expand(&1, __CALLER__)) |> Map.new()
    requester = Map.get(options, :requester, WeChat.Requester.Pay)
    storage = Map.get(options, :storage, WeChat.Storage.PayFile)
    private_key = WeChat.Pay.Crypto.load_pem!(options.client_key)
    public_key = private_key |> X509.PublicKey.derive() |> Macro.escape()
    private_key = Macro.escape(private_key)

    quote do
      use Supervisor

      @spec start_link(WeChat.Pay.start_options()) :: Supervisor.on_start()
      def start_link(opts) do
        Supervisor.start_link(__MODULE__, Map.new(opts), name: :"#{__MODULE__}.Supervisor")
      end

      @impl true
      def init(opts) do
        refresher = Map.get(opts, :refresher, WeChat.Refresher.Pay)

        Map.get_lazy(opts, :cacerts, fn ->
          # Load Cacerts From Storage
          {:ok, cacerts} = unquote(storage).restore(unquote(options.mch_id), :cacerts)
          cacerts
        end)
        |> WeChat.Pay.Certificates.put_certs(__MODULE__)

        children = [
          {refresher, Map.put(opts, :client, __MODULE__)},
          WeChat.Pay.get_requester_spec(__MODULE__)
        ]

        Supervisor.init(children, strategy: :one_for_one)
      end

      @spec get(url :: binary) :: WeChat.response()
      def get(url), do: get(url, [])

      @spec get(url :: binary, opts :: keyword) :: WeChat.response()
      def get(url, opts) do
        unquote(requester).new(__MODULE__)
        |> Tesla.get(url, opts)
      end

      @spec post(url :: binary, body :: any) :: WeChat.response()
      def post(url, body), do: post(url, body, [])

      @spec post(url :: binary, body :: any, opts :: keyword) :: WeChat.response()
      def post(url, body, opts) do
        unquote(requester).new(__MODULE__)
        |> Tesla.post(url, body, opts)
      end

      @spec mch_id() :: WeChat.Pay.mch_id()
      def mch_id, do: unquote(options.mch_id)
      @spec api_secret_key() :: WeChat.Pay.api_secret_key()
      def api_secret_key, do: unquote(options.api_secret_key)
      @spec client_serial_no() :: WeChat.Pay.client_serial_no()
      def client_serial_no, do: unquote(options.client_serial_no)
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

    unless Keyword.get(options, :client_serial_no) |> is_binary() do
      raise ArgumentError, "please set client_serial_no option for #{inspect(client)}"
    end

    unless Keyword.get(options, :api_secret_key) |> is_binary() do
      raise ArgumentError, "please set api_secret_key option for #{inspect(client)}"
    end

    unless Keyword.get(options, :client_cert) |> check_pem_file() do
      raise ArgumentError, "please set client_cert option for #{inspect(client)}"
    end

    unless Keyword.get(options, :client_key) |> check_pem_file() do
      raise ArgumentError, "please set client_key option for #{inspect(client)}"
    end
  end

  defp check_pem_file({:app_dir, app, path}) when is_atom(app) and is_binary(path),
    do: Application.app_dir(app, path) |> File.exists?()

  defp check_pem_file({:file, path}) when is_binary(path), do: File.exists?(path)
  defp check_pem_file(_), do: false
end
