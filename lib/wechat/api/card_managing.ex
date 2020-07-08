defmodule WeChat.CardManaging do
  @moduledoc """
  微信卡券 - 管理卡券

  [API Docs Link](https://developers.weixin.qq.com/doc/offiaccount/Cards_and_Offer/Managing_Coupons_Vouchers_and_Cards.html){:target="_blank"}
  """
  import Jason.Helpers
  alias WeChat.{Requester, Card}

  @doc_link "#{WeChat.doc_link_prefix()}/offiaccount/Cards_and_Offer/Managing_Coupons_Vouchers_and_Cards.html"

  @doc """
  获取用户已领取卡券

  ## API Docs
    [link](#{@doc_link}#1){:target="_blank"}
  """
  @spec get_user_card_list(WeChat.client(), WeChat.openid()) :: WeChat.response()
  def get_user_card_list(client, openid) do
    Requester.post(
      "/card/user/getcardlist",
      json_map(openid: openid),
      query: [access_token: WeChat.get_cache(client.appid(), :access_token)]
    )
  end

  def get_user_card_list(client, openid, card_id) do
    Requester.post(
      "/card/user/getcardlist",
      json_map(openid: openid, card_id: card_id),
      query: [access_token: WeChat.get_cache(client.appid(), :access_token)]
    )
  end

  @doc """
  查看卡券详情

  ## API Docs
    [link](#{@doc_link}#2){:target="_blank"}
  """
  @spec get_card_info(WeChat.client(), Card.card_id()) :: WeChat.response()
  def get_card_info(client, card_id) do
    Requester.post(
      "/card/get",
      json_map(card_id: card_id),
      query: [access_token: WeChat.get_cache(client.appid(), :access_token)]
    )
  end

  @doc """
  批量查询卡券列表

  ## API Docs
    [link](#{@doc_link}#3){:target="_blank"}
  """
  @spec batch_get_cards(WeChat.client(), count :: integer, offset :: integer) :: WeChat.response()
  def batch_get_cards(client, count, offset) when count <= 50 do
    Requester.post(
      "/card/batchget",
      json_map(offset: offset, count: count),
      query: [access_token: WeChat.get_cache(client.appid(), :access_token)]
    )
  end

  @doc """
  批量查询卡券列表 - 只获取指定状态

  ## API Docs
    [link](#{@doc_link}#3){:target="_blank"}
  """
  @spec batch_get_cards(
          WeChat.client(),
          [Card.card_status()],
          count :: integer,
          offset :: integer
        ) ::
          WeChat.response()
  def batch_get_cards(client, status_list, count, offset) when count <= 50 do
    Requester.post(
      "/card/batchget",
      json_map(offset: offset, count: count, status_list: status_list),
      query: [access_token: WeChat.get_cache(client.appid(), :access_token)]
    )
  end

  @doc """
  更改卡券信息

  ## API Docs
    [link](#{@doc_link}#4){:target="_blank"}
  """
  @spec update_card_info(WeChat.client(), Card.card_id(), Card.card_type(), card_info :: map) ::
          WeChat.response()
  def update_card_info(client, card_id, card_type, card_info) do
    Requester.post(
      "/card/update",
      %{
        "card_id" => card_id,
        card_type => card_info
      },
      query: [access_token: WeChat.get_cache(client.appid(), :access_token)]
    )
  end

  @doc """
  修改库存

  ## API Docs
    [link](#{@doc_link}#5){:target="_blank"}
  """
  @spec modify_card_stock(WeChat.client(), Card.card_id(), change_count :: integer) ::
          WeChat.response()
  def modify_card_stock(client, card_id, change_count) do
    body =
      if change_count > 0 do
        json_map(card_id: card_id, increase_stock_value: change_count)
      else
        json_map(card_id: card_id, reduce_stock_value: -change_count)
      end
      |> Jason.encode!()

    Requester.post("/card/modifystock", body,
      query: [access_token: WeChat.get_cache(client.appid(), :access_token)]
    )
  end

  @doc """
  更改Code

  ## API Docs
    [link](#{@doc_link}#6){:target="_blank"}
  """
  @spec update_card_code(WeChat.client(), Card.card_id(), Card.card_code(), Card.card_code()) ::
          WeChat.response()
  def update_card_code(client, card_id, old_code, new_code) do
    Requester.post(
      "/card/code/update",
      json_map(card_id: card_id, code: old_code, new_code: new_code),
      query: [access_token: WeChat.get_cache(client.appid(), :access_token)]
    )
  end

  @doc """
  删除卡券

  ## API Docs
    [link](#{@doc_link}#7){:target="_blank"}
  """
  @spec check_card_code(WeChat.client(), Card.card_id()) :: WeChat.response()
  def check_card_code(client, card_id) do
    Requester.post(
      "/card/delete",
      json_map(card_id: card_id),
      query: [access_token: WeChat.get_cache(client.appid(), :access_token)]
    )
  end

  @doc """
  设置卡券失效接口-非自定义code卡券的请求

  ## API Docs
    [link](#{@doc_link}#8){:target="_blank"}
  """
  @spec unavailable_card_code(WeChat.client(), Card.card_code(), reason :: String.t()) ::
          WeChat.response()
  def unavailable_card_code(client, code, reason) do
    Requester.post(
      "/card/code/unavailable",
      json_map(code: code, reason: reason),
      query: [access_token: WeChat.get_cache(client.appid(), :access_token)]
    )
  end

  @doc """
  设置卡券失效接口-自定义code卡券的请求

  ## API Docs
    [link](#{@doc_link}#8){:target="_blank"}
  """
  @spec unavailable_card_code(
          WeChat.client(),
          Card.card_id(),
          Card.card_code(),
          reason :: String.t()
        ) ::
          WeChat.response()
  def unavailable_card_code(client, card_id, code, reason) do
    Requester.post(
      "/card/code/unavailable",
      json_map(card_id: card_id, code: code, reason: reason),
      query: [access_token: WeChat.get_cache(client.appid(), :access_token)]
    )
  end

  @doc """
  拉取卡券概况数据

  ## API Docs
    [link](#{@doc_link}#10){:target="_blank"}
  """
  @spec get_card_bizuin_info(
          WeChat.client(),
          begin_date :: Card.date(),
          end_date :: Card.date(),
          Card.cond_source()
        ) ::
          WeChat.response()
  def get_card_bizuin_info(client, begin_date, end_date, cond_source \\ 1)
      when cond_source in 0..1 do
    Requester.post(
      "/datacube/getcardbizuininfo",
      json_map(begin_date: begin_date, end_date: end_date, cond_source: cond_source),
      query: [access_token: WeChat.get_cache(client.appid(), :access_token)]
    )
  end

  @doc """
  获取免费券数据

  ## API Docs
    [link](#{@doc_link}#11){:target="_blank"}
  """
  @spec get_card_analysis(
          WeChat.client(),
          begin_date :: Card.date(),
          end_date :: Card.date(),
          Card.cond_source()
        ) ::
          WeChat.response()
  def get_card_analysis(client, begin_date, end_date, cond_source) when cond_source in 0..1 do
    Requester.post(
      "/datacube/getcardcardinfo",
      json_map(begin_date: begin_date, end_date: end_date, cond_source: cond_source),
      query: [access_token: WeChat.get_cache(client.appid(), :access_token)]
    )
  end

  @doc """
  获取免费券数据 - 只获取指定卡券

  ## API Docs
    [link](#{@doc_link}#11){:target="_blank"}
  """
  @spec get_card_analysis(
          WeChat.client(),
          Card.card_id(),
          begin_date :: Card.date(),
          end_date :: Card.date(),
          Card.cond_source()
        ) :: WeChat.response()
  def get_card_analysis(client, card_id, begin_date, end_date, cond_source)
      when cond_source in 0..1 do
    Requester.post(
      "/datacube/getcardcardinfo",
      json_map(
        begin_date: begin_date,
        end_date: end_date,
        cond_source: cond_source,
        card_id: card_id
      ),
      query: [access_token: WeChat.get_cache(client.appid(), :access_token)]
    )
  end
end
