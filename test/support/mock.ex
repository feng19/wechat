defmodule WeChat.Test.Mock do
  @moduledoc false
  import Tesla.Mock
  alias WeChat.{Utils, Storage.Cache}

  @expires_in 7200

  def mock do
    mock_global(&api/1)
    mock_component_verify_ticket()
    :ok
  end

  defp mock_component_verify_ticket do
    store_id = WeChat.Test.Component.component_appid()
    store_key = :component_verify_ticket
    ticket = "COMPONENT_VERIFY_TICKET"
    store_map = %{"value" => ticket, "expired_time" => Utils.now_unix() + @expires_in}
    Cache.put_cache(store_id, store_key, ticket)
    Cache.put_cache({:store_map, store_id}, store_key, store_map)
  end

  defp api(%{method: :get, url: "/cgi-bin/token"}),
    do: json(%{"access_token" => "ACCESS_TOKEN", "expires_in" => @expires_in})

  defp api(%{method: :post, url: "/cgi-bin/component/api_component_token"}),
    do: json(%{"component_access_token" => "COMPONENT_ACCESS_TOKEN", "expires_in" => @expires_in})

  defp api(%{method: :get, url: "/cgi-bin/ticket/getticket", query: query}),
    do: json(%{"ticket" => "#{query[:type]}-ticket", "expires_in" => @expires_in})
end
