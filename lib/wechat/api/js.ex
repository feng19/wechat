defmodule WeChat.JS do
  @moduledoc """
  JS-SDK

  [API Docs Link](https://developers.weixin.qq.com/doc/offiaccount/OA_Web_Apps/JS-SDK.html)
  """
  alias WeChat.{Requester, Utils}

  @doc_link "#{WeChat.doc_link_prefix()}/offiaccount/OA_Web_Apps/JS-SDK.html"

  @typedoc """
  JS API的临时票据类型
    * `"jsapi"` - JS-SDK Config
    * `"wx_card"` - 微信卡券
  """
  @type js_api_ticket_type :: String.t()

  @doc """
  JS-SDK配置

  ## API Docs
    [link](#{@doc_link}#4)
  """
  @spec js_sdk_config(WeChat.client(), url :: String.t()) :: WeChat.response()
  def js_sdk_config(client, url) do
    appid = client.appid()

    appid
    |> WeChat.get_cache(:js_api_ticket)
    |> sign_jssdk(url)
    |> Map.put(:appid, appid)
  end

  @spec sign_jssdk(jsapi_ticket :: String.t(), url :: String.t()) :: JSSDKSignature.t()
  def sign_jssdk(jsapi_ticket, url) do
    url = String.replace(url, ~r/\#.*/, "")
    nonce_str = Utils.random_string(16)
    timestamp = Utils.now_unix()

    str_to_sign =
      "jsapi_ticket=#{jsapi_ticket}&noncestr=#{nonce_str}&timestamp=#{timestamp}&url=#{url}"

    signature =
      :crypto.hash(:sha, str_to_sign)
      |> Base.encode16(case: :lower)

    %{signature: signature, timestamp: timestamp, nonceStr: nonce_str}
  end

  @doc """
  微信卡券配置 - 添加卡券

  ## API Docs
    [link](#{@doc_link}#53)
  """
  def add_card_config(client, card_id, outer_str) do
    appid = client.appid()

    card_ext =
      appid
      |> WeChat.get_cache(:wx_card_ticket)
      |> sign_card(card_id)
      |> Map.merge(%{appid: client.appid(), outer_str: outer_str})
      |> Jason.encode!()

    %{
      cardId: card_id,
      cardExt: card_ext
    }
  end

  @doc """
  微信卡券配置 - 添加卡券(绑定openid)

  ## API Docs
    [link](#{@doc_link}#53)
  """
  def add_card_config(client, card_id, outer_str, openid) do
    appid = client.appid()

    card_ext =
      appid
      |> WeChat.get_cache(:wx_card_ticket)
      |> sign_card(card_id, openid)
      |> Map.merge(%{appid: client.appid(), outer_str: outer_str, openid: openid})
      |> Jason.encode!()

    %{
      cardId: card_id,
      cardExt: card_ext
    }
  end

  @doc """
  To initialize WeChat Card functions via JSSDK, use `wxcard_ticket`, `card_id` to generate an signature for this scenario.

  ## API Docs
    [link](#{@doc_link}#65)
  """
  @spec sign_card(list :: [String.t()]) :: CardSignature.t()
  @spec sign_card(wxcard_ticket :: String.t(), card_id :: String.t()) :: CardSignature.t()
  @spec sign_card(wxcard_ticket :: String.t(), card_id :: String.t(), openid :: String.t()) ::
          CardSignature.t()
  def sign_card(wxcard_ticket, card_id), do: sign_card([wxcard_ticket, card_id])
  def sign_card(wxcard_ticket, card_id, openid), do: sign_card([wxcard_ticket, card_id, openid])

  def sign_card(list) do
    nonce_str = Utils.random_string(16)
    timestamp = Utils.now_unix()
    timestamp_str = Integer.to_string(timestamp)

    str_to_sign =
      Enum.sort([timestamp_str, nonce_str | list])
      |> Enum.join()

    signature =
      :crypto.hash(:sha, str_to_sign)
      |> Base.encode16(case: :lower)

    %{signature: signature, timestamp: timestamp, nonce_str: nonce_str}
  end

  @doc """
  获取api_ticket

  ## API Docs
    [link](#{@doc_link}#62)
  """
  @spec get_ticket(WeChat.client(), js_api_ticket_type) :: WeChat.response()
  def get_ticket(client, type) do
    Requester.get("/cgi-bin/ticket/getticket",
      query: [type: type, access_token: WeChat.get_cache(client.appid(), :access_token)]
    )
  end
end
