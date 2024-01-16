defmodule WeChat.Pay.Middleware.XMLBuilder do
  @moduledoc """
  微信支付 V2 构建xml & 签名

  Tesla Middleware

  [签名算法](#{WeChat.Utils.pay_v2_doc_link_prefix()}/api/micropay.php?chapter=4_3){:target="_blank"}
  """
  @behaviour Tesla.Middleware
  alias WeChat.Pay.Crypto

  @impl Tesla.Middleware
  def call(env, next, client) do
    data = env.body
    method = Map.get(data, "sign_type", "MD5")
    signature = Crypto.v2_sign(data, method, client.api_secret_v2_key())
    body = data |> Map.put("sign", signature) |> encode()

    %{env | opts: [{:auth_sign_method, method} | env.opts]}
    |> Tesla.put_body(body)
    |> Tesla.run(next)
  end

  defp encode(params) do
    Enum.map(params, fn
      {_k, nil} -> ""
      {_k, ""} -> ""
      {k, v} when is_list(v) -> "<#{k}><![CDATA[#{Jason.encode!(v)}]]></#{k}>"
      {k, v} when is_map(v) -> "<#{k}><![CDATA[#{Jason.encode!(v)}]]></#{k}>"
      {k, v} -> "<#{k}><![CDATA[#{v}]]></#{k}>"
    end)
    |> Enum.join()
    |> then(&"<xml>#{&1}</xml>")
  end
end
