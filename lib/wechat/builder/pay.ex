defmodule WeChat.Builder.Pay do
  @moduledoc false
  alias WeChat.Builder.Utils

  defmacro __using__(options \\ []) do
    client = __CALLER__.module
    options = check_options!(options, client, __CALLER__)
    requester = Map.get(options, :requester, WeChat.Requester.Pay)
    storage = Map.get(options, :storage, WeChat.Storage.PayFile)

    quote do
      use Supervisor

      @spec start_link(WeChat.Pay.start_options()) :: Supervisor.on_start()
      def start_link(opts) do
        Supervisor.start_link(__MODULE__, Map.new(opts), name: :"#{__MODULE__}.Supervisor")
      end

      @impl true
      def init(opts) do
        refresher = Map.get(opts, :refresher, WeChat.Refresher.Pay)

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
        unquote(requester).new(__MODULE__) |> Tesla.get(url, opts)
      end

      @spec post(url :: binary, body :: any) :: WeChat.response()
      def post(url, body), do: post(url, body, [])

      @spec post(url :: binary, body :: any, opts :: keyword) :: WeChat.response()
      def post(url, body, opts) do
        unquote(requester).new(__MODULE__) |> Tesla.post(url, body, opts)
      end

      @spec mch_id() :: WeChat.Pay.mch_id()
      def mch_id, do: unquote(options.mch_id)
      @spec api_secret_key() :: WeChat.Pay.api_secret_key()
      unquote(options.api_secret_key)
      @spec client_serial_no() :: WeChat.Pay.client_serial_no()
      def client_serial_no, do: unquote(options.client_serial_no)
      @spec storage() :: WeChat.Storage.Adapter.t()
      def storage, do: unquote(storage)
      @spec client_key() :: WeChat.Pay.client_key()
      def client_key, do: unquote(options.client_key)
      @doc false
      def public_key, do: unquote(options.public_key)
      @doc false
      def private_key, do: unquote(options.private_key)

      @doc "加密敏感信息"
      def encrypt_secret_data(data) do
        WeChat.Pay.Crypto.encrypt_secret_data(data, unquote(options.public_key))
      end

      @doc "解密敏感信息"
      def decrypt_secret_data(cipher_text) do
        WeChat.Pay.Crypto.decrypt_secret_data(cipher_text, unquote(options.private_key))
      end
    end
  end

  defp check_options!(options, client, caller) do
    options = options |> Macro.prewalk(&Macro.expand(&1, caller)) |> Map.new()

    unless Map.get(options, :mch_id) |> is_binary() do
      raise ArgumentError, "please set mch_id option for #{inspect(client)}"
    end

    unless Map.get(options, :client_serial_no) |> is_binary() do
      raise ArgumentError, "please set client_serial_no option for #{inspect(client)}"
    end

    api_secret_key =
      case Map.get(options, :api_secret_key) do
        api_secret_key when is_binary(api_secret_key) ->
          quote do
            def api_secret_key, do: unquote(options.api_secret_key)
          end

        api_secret_key when is_atom(api_secret_key) ->
          with :not_handle <-
                 Utils.handle_env_option(client, :api_secret_key, options.api_secret_key) do
            raise ArgumentError,
                  "bad api_secret_key: #{inspect(api_secret_key)} option for #{inspect(client)}"
          end

        api_secret_key when is_tuple(api_secret_key) ->
          with :not_handle <-
                 Utils.handle_env_option(client, :api_secret_key, options.api_secret_key) do
            raise ArgumentError,
                  "bad api_secret_key: #{inspect(api_secret_key)} option for #{inspect(client)}"
          end

        _ ->
          raise ArgumentError, "please set api_secret_key option for #{inspect(client)}"
      end

    client_key =
      case Map.get(options, :client_key) |> check_pem_file() do
        {:bad_arg, pem_file} ->
          raise ArgumentError,
                "bad client_key: #{inspect(pem_file)} option for #{inspect(client)}"

        :unset ->
          raise ArgumentError, "please set client_key option for #{inspect(client)}"

        pem_file ->
          pem_file
      end

    private_key = WeChat.Pay.Crypto.load_pem!(client_key)
    public_key = private_key |> X509.PublicKey.derive()

    %{options | api_secret_key: api_secret_key, client_key: Macro.escape(client_key)}
    |> Map.put(:private_key, Macro.escape(private_key))
    |> Map.put(:public_key, Macro.escape(public_key))
  end

  defp check_pem_file(quoted = {:{}, opts, list}) when is_list(opts) and is_list(list) do
    {pem_file, _} = Code.eval_quoted(quoted)
    if check_pem_file?(pem_file), do: pem_file, else: {:bad_arg, pem_file}
  end

  defp check_pem_file(pem_file) when is_tuple(pem_file) do
    if check_pem_file?(pem_file), do: pem_file, else: {:bad_arg, pem_file}
  end

  defp check_pem_file(nil), do: :unset
  defp check_pem_file(pem_file), do: {:bad_arg, pem_file}

  defp check_pem_file?({:app_dir, app, path}) when is_atom(app) and is_binary(path),
    do: Application.app_dir(app, path) |> File.exists?()

  defp check_pem_file?({:file, path}) when is_binary(path), do: File.exists?(path)
  defp check_pem_file?(_), do: false
end
