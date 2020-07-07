defmodule WeChat.Utils do
  @moduledoc false

  @random_alphanumeric Enum.concat([?a..?z, ?A..?Z, 48..57])

  def random_string(length) when length > 0 do
    @random_alphanumeric
    |> Enum.take_random(length)
    |> List.to_string()
  end

  def now_unix, do: System.system_time(:second)
end
