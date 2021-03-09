defmodule WeChat.Builder do
  @moduledoc false
  alias WeChat.{Component, MiniProgram}

  @base_option_fields [
    :appid,
    :app_type,
    :by_component?,
    :server_role,
    :code_name,
    :storage,
    :requester,
    :encoding_aes_key,
    :token
  ]
  @default_opts [
    app_type: :official_account,
    server_role: :client,
    by_component?: false,
    storage: WeChat.Storage.File,
    requester: WeChat.Requester
  ]
  @both_modules [
    WeChat.CustomMessage,
    WeChat.SubscribeMessage
  ]
  @official_account_modules [
    WeChat.Menu,
    WeChat.Material,
    WeChat.Card,
    WeChat.CardManaging,
    WeChat.CardDistributing,
    WeChat.CustomService,
    WeChat.BatchSends,
    WeChat.Template,
    WeChat.User,
    WeChat.UserTag,
    WeChat.UserBlacklist,
    WeChat.Account,
    WeChat.Comment,
    WeChat.WebPage
  ]
  @mini_program_modules [
    MiniProgram.Auth,
    MiniProgram.Code,
    MiniProgram.UrlScheme,
    MiniProgram.NearbyPOI,
    MiniProgram.Live.Room,
    MiniProgram.Live.Goods,
    MiniProgram.Live.Role,
    MiniProgram.Live.Subscribe
  ]

  defmacro __using__(options \\ []) do
    opts = Macro.prewalk(options, &Macro.expand(&1, __CALLER__))
    default_opts = Keyword.merge(@default_opts, opts)
    app_type = Keyword.fetch!(default_opts, :app_type)

    sub_modules =
      case app_type do
        :official_account ->
          @official_account_modules ++ @both_modules

        :mini_program ->
          @mini_program_modules ++ @both_modules

        _ ->
          raise ArgumentError, "please set app_type in [:official_account, :mini_program]"
      end

    {sub_modules, default_opts} =
      if Keyword.get(default_opts, :by_component?, false) do
        unless Keyword.has_key?(default_opts, :component_appid) do
          raise ArgumentError, "please set :component_appid when setting by_component?: true"
        end

        {
          [Component | sub_modules],
          Keyword.take(default_opts, [
            :component_appid,
            :component_appsecret | @base_option_fields
          ])
        }
      else
        {
          sub_modules,
          Keyword.take(default_opts, [:appsecret | @base_option_fields])
        }
      end

    client = __CALLER__.module

    if Keyword.get(opts, :gen_sub_module?, true) do
      gen_get_functions(default_opts, client) ++ gen_sub_modules(sub_modules, client)
    else
      gen_get_functions(default_opts, client)
    end
  end

  defp gen_get_functions(default_opts, client) do
    appid =
      case Keyword.get(default_opts, :appid) do
        appid when is_binary(appid) -> appid
        _ -> raise ArgumentError, "please set appid"
      end

    {code_name, default_opts} =
      Keyword.pop_lazy(default_opts, :code_name, fn ->
        client |> to_string() |> String.split(".") |> List.last() |> String.downcase()
      end)

    {requester, default_opts} = Keyword.pop(default_opts, :requester)

    base =
      quote do
        def code_name, do: unquote(code_name)
        def get_access_token, do: WeChat.Storage.Cache.get_cache(unquote(appid), :access_token)
        defdelegate get(url), to: unquote(requester)
        defdelegate get(url, opts), to: unquote(requester)
        defdelegate get(client, url, opts), to: unquote(requester)
        defdelegate post(url, body), to: unquote(requester)
        defdelegate post(url, body, opts), to: unquote(requester)
        defdelegate post(client, url, body, opts), to: unquote(requester)
      end

    get_funs =
      Enum.map(default_opts, fn
        {:encoding_aes_key, value} ->
          aes_key = WeChat.ServerMessage.Encryptor.aes_key(value)

          quote do
            def encoding_aes_key, do: unquote(value)
            def aes_key, do: unquote(aes_key)
          end

        {key, value} ->
          quote do
            def unquote(key)(), do: unquote(value)
          end
      end)

    [base | get_funs]
  end

  def gen_sub_modules(sub_modules, parent_module, drop_amount \\ 1) do
    client_module =
      parent_module
      |> Module.split()
      |> List.last()
      |> String.to_atom()

    {sub_module_ast_list, files} =
      Enum.map_reduce(
        sub_modules,
        [],
        fn module, acc ->
          {file, ast} = _gen_sub_module(module, parent_module, client_module, drop_amount)
          {ast, [quote(do: @external_resource(unquote(file))) | acc]}
        end
      )

    files ++ sub_module_ast_list
  end

  defp _gen_sub_module(module, parent_module, client_module, drop_amount) do
    file = module.__info__(:compile)[:source]

    {:ok, ast} =
      file
      |> File.read!()
      |> Code.string_to_quoted()

    file =
      to_string(file)
      |> String.split("/")
      |> Enum.drop_while(&(&1 != "wechat"))
      |> Path.join()

    new_module_name_alias =
      module
      |> Module.split()
      |> Enum.drop(drop_amount)
      |> Enum.map(&String.to_atom/1)

    ast =
      Macro.prewalk(
        ast,
        fn
          {:defmodule, c_m, [{:__aliases__, c_a, _}, do_list]} ->
            [do: {:__block__, [], list}] = do_list

            do_list = [
              do:
                {:__block__, [],
                 [
                   quote(do: alias(unquote(parent_module))),
                   quote(do: @file(unquote(to_string(module))))
                   | list
                 ]}
            ]

            {:defmodule, c_m, [{:__aliases__, c_a, new_module_name_alias}, do_list]}

          {:spec, c_s, ast} ->
            ast =
              Macro.prewalk(
                ast,
                fn
                  {fun_name, context, [{{:., _, [{:__aliases__, _, _}, :client]}, _, _} | args]}
                  when is_atom(fun_name) ->
                    # del first argument
                    {fun_name, context, args}

                  sub_ast ->
                    sub_ast
                end
              )

            {:spec, c_s, ast}

          {:def, c_s, ast} ->
            ast =
              Macro.prewalk(
                ast,
                fn
                  {:., context, [{:client, c_c, nil}, fun_name]} ->
                    # replace client
                    {:., context, [{:__aliases__, c_c, [client_module]}, fun_name]}

                  {fun_name, context, [{:client, _, nil} | args]} when is_atom(fun_name) ->
                    # del first argument
                    {fun_name, context, args}

                  sub_ast ->
                    sub_ast
                end
              )

            {:def, c_s, ast}

          ast ->
            ast
        end
      )

    {file, ast}
  end
end
