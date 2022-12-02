defmodule WeChat.Builder.OfficialAccount do
  @moduledoc false
  alias WeChat.{Component, MiniProgram, Builder.Utils}

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
    requester: WeChat.Requester.OfficialAccount
  ]

  @both_modules [
    WeChat.CustomMessage,
    WeChat.SubscribeMessage
  ]

  @official_account_modules [
    WeChat.Menu,
    WeChat.Material,
    WeChat.DraftBox,
    WeChat.Publish,
    WeChat.Card,
    WeChat.CardManaging,
    WeChat.CardDistributing,
    WeChat.MemberCard,
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
    MiniProgram.Search,
    MiniProgram.OCR,
    MiniProgram.Security,
    MiniProgram.Live.Room,
    MiniProgram.Live.Goods,
    MiniProgram.Live.Role,
    MiniProgram.Live.Subscribe
  ]

  defmacro __using__(options \\ []) do
    client = __CALLER__.module
    opts = Macro.prewalk(options, &Macro.expand(&1, __CALLER__))
    default_opts = Keyword.merge(@default_opts, opts)

    unless Keyword.get(default_opts, :appid) |> is_binary() do
      raise ArgumentError, "please set appid option for #{inspect(client)}"
    end

    app_type = Keyword.fetch!(default_opts, :app_type)

    sub_modules =
      Keyword.get_lazy(default_opts, :sub_modules, fn ->
        case app_type do
          :official_account ->
            @official_account_modules ++ @both_modules

          :mini_program ->
            @mini_program_modules ++ @both_modules

          _ ->
            raise ArgumentError, "please set app_type in [:official_account, :mini_program]"
        end
      end)

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

    if Keyword.get(opts, :gen_sub_module?, true) do
      gen_get_functions(default_opts, client) ++ Utils.gen_sub_modules(sub_modules, client)
    else
      gen_get_functions(default_opts, client)
    end
  end

  defp gen_get_functions(default_opts, client) do
    {appid, default_opts} = Keyword.pop!(default_opts, :appid)
    {requester, default_opts} = Keyword.pop!(default_opts, :requester)

    {code_name, default_opts} =
      Keyword.pop_lazy(default_opts, :code_name, fn ->
        client |> to_string() |> String.split(".") |> List.last() |> String.downcase()
      end)

    base_funs =
      quote do
        def appid, do: unquote(appid)
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
        {:encoding_aes_key, value} when is_binary(value) ->
          aes_key = WeChat.ServerMessage.Encryptor.aes_key(value)

          quote do
            def encoding_aes_key, do: unquote(value)
            def aes_key, do: unquote(aes_key)
          end

        {:encoding_aes_key, value} ->
          [
            Utils.handle_env_option(client, :encoding_aes_key, value),
            Utils.handle_env_option(client, :aes_key, value)
          ]

        {key, value} ->
          with :not_handle <- Utils.handle_env_option(client, key, value) do
            quote do
              def unquote(key)(), do: unquote(value)
            end
          end
      end)

    [base_funs | get_funs]
  end
end
