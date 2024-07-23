defmodule WeChat.Utils do
  @moduledoc false

  @random_alphanumeric Enum.concat([?a..?z, ?A..?Z, 48..57])
  @type timestamp :: integer

  if Mix.env() == :test do
    def default_adapter, do: Tesla.Mock
  else
    def default_adapter,
      do: {Tesla.Adapter.Finch, name: WeChat.Finch, pool_timeout: 5_000, receive_timeout: 5_000}
  end

  @spec random_string(length :: integer) :: String.t()
  def random_string(length) when length > 0 do
    @random_alphanumeric
    |> Enum.take_random(length)
    |> List.to_string()
  end

  @spec now_unix :: timestamp
  def now_unix, do: System.system_time(:second)

  @spec sha1([String.t()] | String.t()) :: signature :: String.t()
  def sha1(list) when is_list(list) do
    Enum.sort(list) |> Enum.join() |> sha1()
  end

  def sha1(string) when is_binary(string) do
    :crypto.hash(:sha, string) |> Base.encode16(case: :lower)
  end

  defmacro def_eex({name, _, args}, do: source) do
    args = Enum.map(args, &elem(&1, 0))

    quote do
      require EEx

      EEx.function_from_string(
        :def,
        unquote(name),
        String.replace(unquote(source), ["\n", "\n  ", "\n    ", "\n      "], ""),
        unquote(args)
      )
    end
  end

  def uniq_and_sort(list) do
    list |> Enum.uniq() |> Enum.sort()
  end

  def expand_file({:app_dir, app, path}) do
    file = Application.app_dir(app, path)

    if File.exists?(file) do
      {:ok, file}
    else
      {:error, :not_exists}
    end
  end

  def expand_file(path) when is_binary(path) do
    file = Path.expand(path)

    if File.exists?(file) do
      {:ok, file}
    else
      {:error, :not_exists}
    end
  end

  def expand_file(_path), do: {:error, :bad_arg}

  def request_should_retry({:ok, %{status: status}}) when status in [400, 500], do: true
  def request_should_retry({:ok, _}), do: false
  def request_should_retry({:error, _}), do: true
end
