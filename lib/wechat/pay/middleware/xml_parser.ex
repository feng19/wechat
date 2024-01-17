defmodule WeChat.Pay.Middleware.XMLParser do
  @moduledoc """
  微信支付 V2 解构xml

  Tesla Middleware
  """
  alias WeChat.ServerMessage.XmlParser
  alias WeChat.Pay.Crypto

  @behaviour Tesla.Middleware
  @compile {:no_warn_undefined, XmlParser}

  @impl Tesla.Middleware
  def call(env, next, client) do
    method = Keyword.fetch!(env.opts, :auth_sign_method)

    with {:ok, %{status: 200, body: body} = env} when is_binary(body) <- Tesla.run(env, next) do
      with {:ok, xml} <- XmlParser.parse(body) do
        if Keyword.get(env.opts, :auth_verify_sign, true) do
          if Map.has_key?(xml, "sign") and
               Crypto.v2_verify(xml, method, client.api_secret_v2_key()) do
            {:ok, %{env | body: xml}}
          else
            {:error, :invaild_response}
          end
        else
          {:ok, %{env | body: xml}}
        end
      else
        _error -> {:error, :invaild_response}
      end
    end
  end
end
