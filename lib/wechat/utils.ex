defmodule WeChat.Utils do
  @moduledoc false

  @random_alphanumeric Enum.concat([?a..?z, ?A..?Z, 48..57])
  @type timestamp :: integer

  @spec random_string(length :: integer()) :: String.t()
  def random_string(length) when length > 0 do
    @random_alphanumeric
    |> Enum.take_random(length)
    |> List.to_string()
  end

  @spec now_unix() :: timestamp()
  def now_unix, do: System.system_time(:second)
end
