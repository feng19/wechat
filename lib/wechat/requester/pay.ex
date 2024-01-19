defmodule WeChat.Requester.Pay do
  @moduledoc """
  默认的请求客户端(微信支付)
  """

  alias WeChat.Pay
  alias Tesla.Middleware

  @adapter_options [pool_timeout: 5_000, receive_timeout: 5_000]
  @base_url "https://api.mch.weixin.qq.com"
  @user_agent "Tesla"

  # v3
  def client(client) do
    name = WeChat.Pay.finch_name(client)

    Tesla.client(
      [
        {Middleware.BaseUrl, @base_url},
        {Middleware.Headers, [{"accept", "application/json"}, {"user-agent", @user_agent}]},
        Middleware.EncodeJson,
        {Pay.Middleware.Authorization, client},
        {Pay.Middleware.VerifySignature, client},
        Middleware.Logger
      ],
      {Tesla.Adapter.Finch, [{:name, name} | @adapter_options]}
    )
  end

  def client_v2(client, ssl? \\ false) do
    name =
      if ssl? do
        WeChat.Pay.v2_ssl_finch_name(client)
      else
        WeChat.Pay.finch_name(client)
      end

    Tesla.client(
      [
        {Middleware.BaseUrl, @base_url},
        {Middleware.Headers,
         [
           {"accept", "application/xml"},
           {"content-type", "application/xml"},
           {"user-agent", @user_agent}
         ]},
        {Pay.Middleware.XMLBuilder, client},
        {Pay.Middleware.XMLParser, client},
        Middleware.Logger
      ],
      {Tesla.Adapter.Finch, [{:name, name} | @adapter_options]}
    )
  end

  @doc false
  def first_time_download_certificates_client(client) do
    # 第一次下载平台证书 跳过验签: https://github.com/wechatpay-apiv3/CertificateDownloader#如何第一次下载证书
    Tesla.client(
      [
        {Middleware.BaseUrl, @base_url},
        {Middleware.Headers, [{"accept", "application/json"}, {"user-agent", @user_agent}]},
        Middleware.EncodeJson,
        {Pay.Middleware.Authorization, client},
        Middleware.DecodeJson,
        Middleware.Logger
      ],
      {Tesla.Adapter.Finch, [{:name, WeChat.Finch} | @adapter_options]}
    )
  end

  @doc false
  def download_url(client, url) do
    %{path: path, query: query} = URI.parse(url)
    query = URI.decode_query(query) |> Map.to_list()

    token =
      Pay.Middleware.Authorization.gen_token(
        client.mch_id(),
        client.client_serial_no(),
        client.private_key(),
        %{url: path, query: query, method: "GET", body: ""}
      )

    Tesla.client(
      [
        {Middleware.Headers,
         [
           {"accept", "*/*"},
           {"user-agent", @user_agent},
           {"authorization", "WECHATPAY2-SHA256-RSA2048 #{token}"}
         ]},
        Tesla.Middleware.DecompressResponse
      ],
      {Tesla.Adapter.Finch, [{:name, WeChat.Finch} | @adapter_options]}
    )
    |> Tesla.get(url)
  end
end
