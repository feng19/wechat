defmodule WeChat.RefreshHelper do
  @moduledoc false
  alias WeChat.{Account, WebApp, Component, MiniProgram}

  def get_refresh_list_by_client(client) do
    case client.role do
      :official_account ->
        official_account_refresh_list()

      :component ->
        component_refresh_list()

      :mini_program ->
        mini_program_refresh_list()
    end
  end

  defp official_account_refresh_list,
    do: [
      {:appid, :access_token, &refresh_access_token/1},
      {:appid, :js_api_ticket, &refresh_ticket("jsapi", &1)},
      {:appid, :wx_card_ticket, &refresh_ticket("wx_card", &1)}
    ]

  defp component_refresh_list,
    do: [
      {:component_appid, :component_access_token, &refresh_component_access_token/1},
      {:appid, :access_token, &refresh_authorizer_access_token/1},
      {:appid, :js_api_ticket, &refresh_ticket("jsapi", &1)},
      {:appid, :wx_card_ticket, &refresh_ticket("wx_card", &1)}
    ]

  defp mini_program_refresh_list,
    do: [
      {:appid, :access_token, &refresh_mini_program_access_token/1}
    ]

  defp refresh_access_token(client) do
    with {:ok, %{status: 200, body: data}} <- Account.get_access_token(client),
         %{"access_token" => access_token, "expires_in" => expires_in} <- data do
      {:ok, access_token, expires_in}
    end
  end

  defp refresh_ticket(ticket_type, client) do
    with {:ok, %{status: 200, body: data}} <- WebApp.get_ticket(client, ticket_type),
         %{"ticket" => ticket, "expires_in" => expires_in} <- data do
      {:ok, ticket, expires_in}
    end
  end

  defp refresh_component_access_token(client) do
    with {:ok, %{status: 200, body: data}} <- Component.get_component_token(client),
         %{"component_access_token" => component_access_token, "expires_in" => expires_in} <- data do
      {:ok, component_access_token, expires_in}
    end
  end

  defp refresh_authorizer_access_token(client) do
    with {:ok, %{status: 200, body: data}} <- Component.authorizer_token(client),
         %{
           "authorizer_access_token" => authorizer_access_token,
           "authorizer_refresh_token" => authorizer_refresh_token,
           "expires_in" => expires_in
         } <- data do
      list = [
        {:access_token, authorizer_access_token, expires_in},
        # 官网并未说明有效期是多少，暂定30天有效期
        {:authorizer_refresh_token, authorizer_refresh_token, 30 * 24 * 60 * 60}
      ]

      {:ok, list, expires_in}
    end
  end

  defp refresh_mini_program_access_token(client) do
    with {:ok, %{status: 200, body: data}} <- MiniProgram.Auth.get_access_token(client),
         %{"access_token" => access_token, "expires_in" => expires_in} <- data do
      {:ok, access_token, expires_in}
    end
  end
end
