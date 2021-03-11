defmodule WeChat.MiniProgram.OCR do
  @moduledoc """
  小程序 - OCR接口
  """
  import WeChat.Utils, only: [doc_link_prefix: 0]

  @typep url :: String.t()
  # 图片识别模式，photo（拍照模式）或 scan（扫描模式）
  @typep type :: String.t()

  @doc_link "#{doc_link_prefix()}/miniprogram/dev/api-backend/open-api/ocr/ocr"

  @doc """
  识别银行卡
  - [官方文档](#{@doc_link}.bankcard.html){:target="_blank"}

  本接口提供基于小程序的银行卡 OCR 识别
  """
  @spec bankcard(WeChat.client(), url) :: WeChat.response()
  def bankcard(client, img_url) do
    client.post("/cv/ocr/bankcard", "",
      query: [img_url: img_url, access_token: client.get_access_token()]
    )
  end

  @doc """
  营业执照
  - [官方文档](#{@doc_link}.businessLicense.html){:target="_blank"}

  本接口提供基于小程序的营业执照 OCR 识别
  """
  @spec business_license(WeChat.client(), url) :: WeChat.response()
  def business_license(client, img_url) do
    client.post("/cv/ocr/bizlicense", "",
      query: [img_url: img_url, access_token: client.get_access_token()]
    )
  end

  @doc """
  驾驶证
  - [官方文档](#{@doc_link}.driverLicense.html){:target="_blank"}

  本接口提供基于小程序的驾驶证 OCR 识别
  """
  @spec driver_license(WeChat.client(), url) :: WeChat.response()
  def driver_license(client, img_url) do
    client.post("/cv/ocr/drivinglicense", "",
      query: [img_url: img_url, access_token: client.get_access_token()]
    )
  end

  @doc """
  身份证
  - [官方文档](#{@doc_link}.idcard.html){:target="_blank"}

  本接口提供基于小程序的身份证 OCR 识别
  """
  @spec id_card(WeChat.client(), url) :: WeChat.response()
  def id_card(client, img_url) do
    client.post("/cv/ocr/idcard", "",
      query: [img_url: img_url, access_token: client.get_access_token()]
    )
  end

  @doc """
  通用印刷体
  - [官方文档](#{@doc_link}.printedText.html){:target="_blank"}

  本接口提供基于小程序的通用印刷体 OCR 识别
  """
  @spec printed_text(WeChat.client(), url) :: WeChat.response()
  def printed_text(client, img_url) do
    client.post("/cv/ocr/comm", "",
      query: [img_url: img_url, access_token: client.get_access_token()]
    )
  end

  @doc """
  行驶证
  - [官方文档](#{@doc_link}.vehicleLicense.html){:target="_blank"}

  本接口提供基于小程序的行驶证 OCR 识别
  """
  @spec vehicle_license(WeChat.client(), url, type) :: WeChat.response()
  def vehicle_license(client, img_url, type \\ "photo") do
    client.post("/cv/ocr/driving", "",
      query: [img_url: img_url, type: type, access_token: client.get_access_token()]
    )
  end
end
