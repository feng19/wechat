defmodule WeChat.MiniProgram.UserInfo do
  import Jason.Helpers
  import WeChat.Utils, only: [doc_link_prefix: 0]

  @doc """
  > 小程序 - 用户信息 - 获取插件用户openpid
  [- 官方文档](#{doc_link_prefix()}/miniprogram/dev/OpenApiDoc/user-info/basic-info/getPluginOpenPId.html)
  """
  @spec get_plugin_openpid(WeChat.client(), code :: String.t()) :: WeChat.response()
  def get_plugin_openpid(client, code) do
    client.get("/wxa/getpluginopenpid",
      query: [
        access_token: client.get_access_token(),
        code: code
      ]
    )
  end

  @doc """
   > 小程序 - 用户信息 - 检查加密信息
  - [官方文档](#{doc_link_prefix()}/miniprogram/dev/OpenApiDoc/user-info/basic-info/checkEncryptedData.html)
  """
  @spec check_encrypted_data(WeChat.client(), encrypted_msg_hash :: String.t()) ::
          WeChat.response()
  def check_encrypted_data(client, encrypted_msg_hash) do
    client.post(
      "/wxa/business/checkencryptedmsg",
      json_map(encrypted_msg_hash: encrypted_msg_hash),
      query: [access_token: client.get_access_token()]
    )
  end

  @doc """
  > 小程序 - 用户信息 - 支付后获取 Unionid
  - [官方文档](#{doc_link_prefix()}/wxa/getpaidunionid)
  """
  @spec get_paid_unionid(
          WeChat.client(),
          WeChat.openid(),
          transaction_id :: String.t(),
          out_trade_no :: String.t()
        ) ::
          WeChat.response()
  def get_paid_unionid(client, openid, transaction_id, out_trade_no) do
    client.get("/wxa/getpaidunionid",
      query: [
        access_token: client.get_access_token(),
        mch_id: client.mch_id(),
        openid: openid,
        transaction_id: transaction_id,
        out_trade_no: out_trade_no
      ]
    )
  end

  @doc """
  > 小程序 - 用户信息 - 获取用户encryptKey
  - [官方文档](#{doc_link_prefix()}/wxa/business/getuserencryptkey)
  """
  @spec get_user_encrypt_key(WeChat.client(), WeChat.openid(), session_key :: String.t()) ::
          WeChat.response()
  def get_user_encrypt_key(client, openid, session_key) do
    signature = :crypto.mac(:hmac, :sha256, session_key, "") |> Base.encode16()

    client.get("/wxa/business/getuserencryptkey",
      query: [
        access_token: client.get_access_token(),
        openid: openid,
        signature: signature,
        sig_method: "hmac_sha256"
      ]
    )
  end

  @doc """
  > 小程序 - 用户信息 - 手机号快速验证
  - [官方文档](#{doc_link_prefix()}/miniprogram/dev/OpenApiDoc/user-info/phone-number/getPhoneNumber.html)
  """
  @spec get_phone_number(WeChat.client(), WeChat.openid(), code :: String.t()) ::
          WeChat.response()
  def get_phone_number(client, openid, code) do
    client.post(
      "/wxa/business/getuserphonenumber",
      json_map(openid: openid, code: code),
      query: [access_token: client.get_access_token()]
    )
  end
end
