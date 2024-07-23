defmodule WeChat.MiniProgram.Code do
  @moduledoc "小程序码"
  import Jason.Helpers

  @typedoc """
  场景值

  最大`32`个可见字符，只支持数字，大小写英文以及部分特殊字符：`!#$&'()*+,/:;=?@-._~`，
  其它字符请自行编码为合法字符（因不支持%，中文无法使用 `UrlEncode` 处理，请使用其他编码方式）

  `scene` 字段的值会作为 `query` 参数传递给小程序/小游戏。用户扫描该码进入小程序/小游戏后，开发者可以获取到二维码中的 `scene` 值，再做处理逻辑。
  调试阶段可以使用开发工具的条件编译自定义参数 `scene=xxxx` 进行模拟，开发工具模拟时的 `scene` 的参数值需要进行 `encodeURIComponent`
  """
  @type scene :: String.t()
  @typedoc """
  小程序页面路径

  最大长度 `128` 字节，不能为空；对于小游戏，可以只传入 `query` 部分，来实现传参效果，如：传入 `?foo=bar`，
  即可在 `wx.getLaunchOptionsSync` 接口中的 `query` 参数获取到 `{foo:"bar"}`。
  """
  @type path :: String.t()
  @typedoc """
  二维码的宽度

  单位 `px`。最小 `280px`，最大 `1280px`
  """
  @type width :: 280..1280
  @typedoc """
  自动配置线条颜色，如果颜色依然是黑色，则说明不建议配置主色调
  """
  @type auto_color :: boolean
  @typedoc """
  auto_color 为 false 时生效，使用 rgb 设置颜色

  例如 `%{r: "xxx",g: "xxx",b: "xxx"}` 十进制表示
  """
  @type line_color :: map
  @typedoc """
  是否需要透明底色，为 `true` 时，生成透明底色的小程序码
  """
  @type is_hyaline :: boolean
  @type code_options :: %{
          :path => path,
          :width => width,
          :auto_color => auto_color,
          :line_color => line_color,
          :is_hyaline => is_hyaline
        }

  @doc """
  生成的小程序二维码 -
  [官方文档](https://developers.weixin.qq.com/miniprogram/dev/OpenApiDoc/qrcode-link/qr-code/createQRCode.html){:target="_blank"}

  获取小程序二维码，适用于需要的码数量较少的业务场景。通过该接口生成的小程序二维码，永久有效，有数量限制，
  详见[获取二维码](https://developers.weixin.qq.com/miniprogram/dev/framework/open-ability/qr-code.html){:target="_blank"}。
  """
  @spec create_qrcode(WeChat.client(), path, width) :: WeChat.response()
  def create_qrcode(client, path, width \\ 430) when is_binary(path) do
    client.post(
      "/cgi-bin/wxaapp/createwxaqrcode",
      json_map(path: path, width: width),
      query: [access_token: client.get_access_token()]
    )
  end

  @doc """
  生成的小程序码 -
  [官方文档](https://developers.weixin.qq.com/miniprogram/dev/OpenApiDoc/qrcode-link/qr-code/getQRCode.html){:target="_blank"}

  获取小程序码，适用于需要的码数量较少的业务场景。通过该接口生成的小程序码，永久有效，有数量限制，
  详见[获取二维码](https://developers.weixin.qq.com/miniprogram/dev/framework/open-ability/qr-code.html){:target="_blank"}。
  """
  @spec create_code(WeChat.client(), path, width, code_options) :: WeChat.response()
  def create_code(client, path, width \\ 430, options \\ %{}) when is_binary(path) do
    client.post(
      "/wxa/getwxacode",
      Map.merge(options, %{path: path, width: width}),
      query: [access_token: client.get_access_token()]
    )
  end

  @doc """
  生成的小程序码 -
  [官方文档](https://developers.weixin.qq.com/miniprogram/dev/OpenApiDoc/qrcode-link/qr-code/getQRCode.html){:target="_blank"}

  获取小程序码，适用于需要的码数量极多的业务场景。通过该接口生成的小程序码，永久有效，数量暂无限制，
  详见[获取二维码](https://developers.weixin.qq.com/miniprogram/dev/framework/open-ability/qr-code.html){:target="_blank"}。
  """
  @spec create_code_unlimited(WeChat.client(), scene, code_options) :: WeChat.response()
  def create_code_unlimited(client, scene, options \\ %{}) when is_binary(scene) do
    client.post(
      "/wxa/getwxacodeunlimit",
      Map.put(options, :scene, scene),
      query: [access_token: client.get_access_token()]
    )
  end

  @spec download(file_path :: Path.t(), create_fun :: (-> WeChat.response())) ::
          WeChat.response() | :ok | {:error, File.posix()}
  def download(file_path, create_fun) do
    file_path
    |> Path.dirname()
    |> File.mkdir_p!()

    with {:ok, %{body: body}} when is_binary(body) <- create_fun.() do
      File.write(file_path, body)
    end
  end
end
