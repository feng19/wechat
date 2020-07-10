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

  def doc_link_prefix, do: "https://developers.weixin.qq.com"

  @spec sha1([String.t()] | String.t()) :: signature :: String.t()
  def sha1(list) when is_list(list) do
    Enum.sort(list) |> Enum.join() |> sha1()
  end

  def sha1(string) when is_binary(string) do
    :crypto.hash(:sha, string) |> Base.encode16(case: :lower)
  end
end
