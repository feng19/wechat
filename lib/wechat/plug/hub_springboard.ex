if Code.ensure_loaded?(Plug) do
  defmodule WeChat.Plug.HubSpringboard do
    @moduledoc """
    OAuth2 跳板 - 用于 Hub Server

    由于微信对于网页授权有域名校验，需要在除指定域名外的域名也支持网页授权，可以使用此跳板
    """
    alias WeChat.Plug.{Helper, OAuth2Checker}

    @doc false
    def init(opts), do: OAuth2Checker.init(opts)

    @doc false
    def call(
          %{
            query_params: %{"code" => code},
            path_params: %{"env" => env, "callback_path" => callback_path}
          } = conn,
          opts
        ) do
      oauth2_callback_fun = fn _type, conn, _code, client, agent ->
        oauth2_callback(conn, client, agent, env, callback_path)
      end

      OAuth2Checker.check_code(conn, code, %{opts | oauth2_callback_fun: oauth2_callback_fun})
    end

    def call(conn, _opts), do: Helper.not_found(conn)

    def oauth2_callback(conn, client, agent, env, callback_path) do
      env_url =
        if agent do
          WeChat.get_oauth2_env_url(client, agent.id, env)
        else
          WeChat.get_oauth2_env_url(client, env)
        end

      if env_url do
        callback_url = [env_url | List.wrap(callback_path)] |> Path.join()
        Helper.redirect(conn, callback_url <> "?" <> conn.query_string)
      else
        Helper.not_found(conn)
      end
    end
  end
end
