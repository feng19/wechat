defmodule WeChat.Builder.Pay do
  @moduledoc false
  defmacro __using__(options \\ []) do
    options = Map.new(options)
    requester = Map.get(options, :requester, WeChat.Requester.Pay)
    storage = Map.get(options, :storage, WeChat.Storage.PayFile)
    public_key = WeChat.Pay.Utils.decode_key(options.client_cert)
    # private_key = WeChat.Pay.Utils.decode_key(options.client_key)

    quote do
      use Supervisor

      def start_link(opts) do
        opts = Map.new(opts)
        requester_a = get_requester_spec(:a, client, opts.cacerts)
        requester_b = get_requester_spec(:b, client, opts.cacerts)
        requester_name = elem(requester_a, 1) |> Keyword.get(:name)
        WeChat.Pay.put_requester_opts(__MODULE__, requester_name, opts.serial_no)
        refresher = Map.get(opts, :refresher, WeChat.Refresher.Pay)
        children = [{refresher, {__MODULE__, opts}}, requester_a, requester_b]
        opts = [strategy: :one_for_one, name: :"#{__MODULE__}.Supervisor"]
        Supervisor.start_link(children, opts)
      end

      def get(url), do: get(url, [])

      def get(url, opts) do
        %{name: name, serial_no: serial_no} = WeChat.Pay.get_requester_opts(__MODULE__)

        __MODULE__
        |> unquote(requester).new(__MODULE__, name, serial_no)
        |> Tesla.get(url, opts)
      end

      def post(url, body), do: post(url, body, [])

      def post(url, body, opts) do
        %{name: name, serial_no: serial_no} = WeChat.Pay.get_requester_opts(__MODULE__)

        __MODULE__
        |> unquote(requester).new(__MODULE__, name, serial_no)
        |> Tesla.post(url, body, opts)
      end

      def mch_id, do: unquote(options.mch_id)
      def api_secret_key, do: unquote(options.api_secret_key)
      def storage, do: unquote(storage)
      def client_cert, do: unquote(options.client_cert)
      def client_key, do: unquote(options.client_key)
      def public_key, do: unquote(public_key)
      # def private_key, do: unquote(private_key)
    end
  end
end
