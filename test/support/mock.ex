defmodule WeChat.Test.Mock do
  @moduledoc false
  import Tesla.Mock

  @expires_in 7200

  def mock do
    mock_global(&api/1)
    :ok
  end

  defp api(%{method: :get, url: "/cgi-bin/token"}),
    do: json(%{"access_token" => "ACCESS_TOKEN", "expires_in" => @expires_in})

  defp api(%{method: :get, url: "/cgi-bin/ticket/getticket", query: query}),
    do: json(%{"ticket" => "#{query[:type]}-ticket", "expires_in" => @expires_in})
end
