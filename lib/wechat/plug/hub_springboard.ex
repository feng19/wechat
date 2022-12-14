if Code.ensure_loaded?(Plug) do
  defmodule WeChat.Plug.HubSpringboard do
    @moduledoc """
    OAuth2 跳板 - 用于 Hub Server(中控服务器)

    由于微信对于网页授权有域名校验，需要在除指定域名外的域名也支持网页授权，可以使用此跳板

    ## Usage

    使用 Phoenix 时，将下面的代码加到 `router` 里面：

        # for normal
        get "/:app/:env/cb/*callback_path", #{inspect(__MODULE__)}, clients: [Client, ...]

        # for work
        get "/:app/:agent/:env/cb/*callback_path", #{inspect(__MODULE__)}, clients: [Client, ...]

    使用 PlugCowboy 时，将下面的代码加到 `router` 里面：

        # for normal
        get "/:app/:env/cb/*callback_path",
          to: #{inspect(__MODULE__)},
          init_opts: [clients: [Client, ...]]

        # for work
        get "/:app/:agent/:env/cb/*callback_path",
          to: #{inspect(__MODULE__)},
          init_opts: [clients: [Client, ...]]
    """
    import WeChat.Plug.Helper

    @doc false
    def init(opts) do
      opts |> Map.new() |> init_plug_clients(__MODULE__)
    end

    @doc false
    def call(
          %{
            query_params: %{"code" => _code},
            path_params: %{"env" => env, "callback_path" => callback_path}
          } = conn,
          options
        ) do
      with {_type, client, agent} <- setup_plug(conn, options) do
        oauth2_callback(conn, client, agent, env, callback_path)
      end
    end

    def call(conn, _opts), do: not_found(conn)

    def oauth2_callback(conn, client, agent, env, callback_path) do
      env_url =
        if agent do
          WeChat.get_oauth2_env_url(client, agent.id, env)
        else
          WeChat.get_oauth2_env_url(client, env)
        end

      if env_url do
        callback_url = [env_url | List.wrap(callback_path)] |> Path.join()
        redirect(conn, callback_url <> "?" <> conn.query_string)
      else
        not_found(conn)
      end
    end
  end
end
