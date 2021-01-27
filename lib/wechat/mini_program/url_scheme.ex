defmodule WeChat.MiniProgram.UrlScheme do
  @moduledoc """
  小程序scheme码，适用于短信、邮件、外部网页等拉起小程序的业务场景
  """

  import Jason.Helpers
  import WeChat.Utils, only: [doc_link_prefix: 0]

  @typedoc """
  通过 `scheme` 码进入的小程序页面路径

  必须是已经发布的小程序存在的页面，不可携带 `query`。`path` 为空时会跳转小程序主页。
  """
  @type path :: String.t()
  @typedoc """
  通过 `scheme` 码进入小程序时的 `query`

  最大 `128` 个字符，只支持数字，大小写英文以及部分特殊字符：`!#$&'()*+,/:;=?@-._~`
  """
  @type query :: String.t()
  @typedoc """
  跳转到的目标小程序信息
  """
  @type jump_wxa :: %{path: path, query: query}
  @typedoc """
  到期失效的scheme码的失效时间，为Unix时间戳。

  生成的到期失效scheme码在该时间前有效。最长有效期为1年。生成到期失效的scheme时必填。
  """
  @type expire_time :: non_neg_integer

  @doc """
  生成的小程序码 -
  [官方文档](#{doc_link_prefix()}/miniprogram/dev/api-backend/open-api/url-scheme/urlscheme.generate.html){:target="_blank"}

  获取小程序scheme码，适用于短信、邮件、外部网页等拉起小程序的业务场景。
  通过该接口，可以选择生成到期失效和永久有效的小程序码，目前仅针对国内非个人主体的小程序开放，
  详见[获取URL scheme码](#{doc_link_prefix()}/miniprogram/dev/framework/open-ability/url-scheme.html){:target="_blank"}。
  """
  @spec create_scheme(WeChat.client(), jump_wxa, expire_time) :: WeChat.response()
  def create_scheme(client, jump_wxa, expire_time \\ nil) when is_map(jump_wxa) do
    body =
      if is_integer(expire_time) do
        json_map(jump_wxa: jump_wxa, is_expire: true, expire_time: expire_time)
      else
        json_map(jump_wxa: jump_wxa)
      end

    client.post("/wxa/generatescheme", body, query: [access_token: client.get_access_token()])
  end
end
