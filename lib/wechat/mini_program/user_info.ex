defmodule WeChat.MiniProgram.UserInfo do
  @moduledoc """
  小程序 - 用户信息
  """
  import Jason.Helpers
  alias WeChat.{Utils, ServerMessage.Encryptor}

  @doc """
  获取插件用户openpid
  - [官方文档](https://developers.weixin.qq.com/miniprogram/dev/OpenApiDoc/user-info/basic-info/getPluginOpenPId.html){:target="_blank"}
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
  检查加密信息
  - [官方文档](https://developers.weixin.qq.com/miniprogram/dev/OpenApiDoc/user-info/basic-info/checkEncryptedData.html){:target="_blank"}
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
  支付后获取用户的`UnionId`
  - [官方文档](https://developers.weixin.qq.com/miniprogram/dev/OpenApiDoc/user-info/basic-info/getPaidUnionid.html){:target="_blank"}

  用户支付完成后，获取该用户的`UnionId`，无需用户授权.

  本接口支持第三方平台代理查询.

  **注意：调用前需要用户完成支付，且在支付后的五分钟内有效**
  """
  @spec get_paid_unionid(WeChat.client(), WeChat.openid()) :: WeChat.response()
  def get_paid_unionid(client, openid) do
    client.get("/wxa/getpaidunionid",
      query: [
        openid: openid,
        access_token: client.get_access_token()
      ]
    )
  end

  @doc """
  支付后获取用户的`UnionId` - 微信支付订单号(`transaction_id`)
  - [官方文档](https://developers.weixin.qq.com/miniprogram/dev/OpenApiDoc/user-info/basic-info/getPaidUnionid.html){:target="_blank"}

  用户支付完成后，获取该用户的`UnionId`，无需用户授权.

  本接口支持第三方平台代理查询.

  **注意：调用前需要用户完成支付，且在支付后的五分钟内有效**
  """
  @spec get_paid_unionid(WeChat.client(), WeChat.openid(), transaction_id :: String.t()) ::
          WeChat.response()
  def get_paid_unionid(client, openid, transaction_id) do
    client.get("/wxa/getpaidunionid",
      query: [
        openid: openid,
        transaction_id: transaction_id,
        access_token: client.get_access_token()
      ]
    )
  end

  @doc """
  支付后获取用户的`UnionId` - 微信支付商户订单号和微信支付商户号(`out_trade_no`及`mch_id`)
  - [官方文档](https://developers.weixin.qq.com/miniprogram/dev/OpenApiDoc/user-info/basic-info/getPaidUnionid.html){:target="_blank"}

  用户支付完成后，获取该用户的`UnionId`，无需用户授权.

  本接口支持第三方平台代理查询.

  **注意：调用前需要用户完成支付，且在支付后的五分钟内有效**
  """
  @spec get_paid_unionid(
          WeChat.client(),
          WeChat.openid(),
          mch_id :: String.t(),
          out_trade_no :: String.t()
        ) :: WeChat.response()
  def get_paid_unionid(client, openid, mch_id, out_trade_no) do
    client.get("/wxa/getpaidunionid",
      query: [
        openid: openid,
        mch_id: mch_id,
        out_trade_no: out_trade_no,
        access_token: client.get_access_token()
      ]
    )
  end

  @doc """
  获取用户 EncryptKey
  - [官方文档](https://developers.weixin.qq.com/miniprogram/dev/OpenApiDoc/user-info/internet/getUserEncryptKey.html){:target="_blank"}
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
  手机号快速验证
  - [官方文档](https://developers.weixin.qq.com/miniprogram/dev/OpenApiDoc/user-info/phone-number/getPhoneNumber.html){:target="_blank"}
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

  @doc """
  服务端获取开放数据
  - [官方文档](https://developers.weixin.qq.com/miniprogram/dev/framework/open-ability/signature.html){:target="_blank"}
  - [登录流程](https://developers.weixin.qq.com/miniprogram/dev/framework/open-ability/login.html)
  """
  @spec decode_user_info(
          session_key :: String.t(),
          raw_data :: String.t(),
          signature :: String.t()
        ) :: {:ok, map()} | {:error, String.t()}
  def decode_user_info(session_key, raw_data, signature) do
    case Utils.sha1(raw_data <> session_key) do
      ^signature ->
        Jason.decode(raw_data)

      _ ->
        {:error, "invalid"}
    end
  end

  @doc """
  服务端获取开放数据 - 包含敏感数据
  - [官方文档](https://developers.weixin.qq.com/miniprogram/dev/framework/open-ability/signature.html){:target="_blank"}
  - [小程序登录](https://developers.weixin.qq.com/miniprogram/dev/framework/open-ability/login.html)
  - [加密数据解密算法](https://developers.weixin.qq.com/miniprogram/dev/framework/open-ability/signature.html#加密数据解密算法)
  """
  @spec decode_get_user_sensitive_info(
          session_key :: String.t(),
          encrypted_data :: String.t(),
          iv :: String.t()
        ) :: {:ok, map()} | :error | {:error, any()}
  def decode_get_user_sensitive_info(session_key, encrypted_data, iv) do
    with {:ok, session_key} <- Base.decode64(session_key),
         {:ok, iv} <- Base.decode64(iv),
         {:ok, encrypted_data} <- Base.decode64(encrypted_data) do
      :crypto.crypto_one_time(:aes_128_cbc, session_key, iv, encrypted_data, false)
      |> Encryptor.decode_padding_with_pkcs7()
      |> Jason.decode()
    end
  end
end
