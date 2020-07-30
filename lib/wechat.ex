defmodule WeChat do
  @moduledoc """
  WeChat SDK for Elixir
  """
  import WeChat.Utils, only: [doc_link_prefix: 0]
  alias WeChat.{Component, MiniProgram}

  @type appid :: String.t()
  @type openid :: String.t()
  @typedoc """
  [UnionID机制说明](#{doc_link_prefix()}/doc/offiaccount/User_Management/Get_users_basic_information_UnionID.html)
  """
  @type unionid :: String.t()
  @type username :: String.t()

  @typedoc """
  国家地区语言
    * `"zh_CN"` - 简体
    * `"zh_TW"` - 繁体
    * `"en"` - 英语
  """
  @type lang :: String.t()

  @type client :: module()
  @type role :: :official_account | :component | :mini_program
  @type app_type :: :official_account | :mini_program | :both
  @type response :: Tesla.Env.result()

  @default_opts [role: :official_account, storage: WeChat.Storage.File]
  @official_account_modules [
    WeChat.Material,
    WeChat.Card,
    WeChat.CardManaging,
    WeChat.CardDistributing,
    WeChat.CustomService,
    WeChat.CustomMessage,
    WeChat.BatchSends,
    WeChat.Template,
    WeChat.User,
    WeChat.UserTag,
    WeChat.UserBlacklist,
    WeChat.Account,
    WeChat.Comment,
    WeChat.WebApp
  ]
  @mini_program_modules [
    MiniProgram.Auth
  ]

  defmacro __using__(opts \\ []) do
    opts = Keyword.merge(@default_opts, opts)
    role = Keyword.get(opts, :role, :official_account)

    sub_modules =
      case role do
        :official_account ->
          @official_account_modules

        :component ->
          case Keyword.get(opts, :app_type, :official_account) do
            :official_account ->
              [Component | @official_account_modules]

            :mini_program ->
              [Component | @mini_program_modules]

            :both ->
              [Component | @official_account_modules ++ @mini_program_modules]
          end

        :mini_program ->
          @mini_program_modules

        _ ->
          raise ArgumentError, "please set role in [:official_account, :component, :mini_program]"
      end

    {sub_module_ast_list, files} =
      Enum.map_reduce(
        sub_modules,
        [],
        fn module, acc ->
          {file, ast} = gen_sub_module(module, __CALLER__.module)
          {ast, [quote(do: @external_resource(unquote(file))) | acc]}
        end
      )

    default_opts = Macro.prewalk(opts, &Macro.expand(&1, __CALLER__))

    gen_get_function(role, default_opts) ++ files ++ sub_module_ast_list
  end

  defp gen_get_function(:official_account, default_opts) do
    default_opts
    |> Keyword.take([:role, :storage, :appid, :appsecret, :encoding_aes_key, :token])
    |> gen_get_function()
  end

  defp gen_get_function(:component, default_opts) do
    default_opts
    |> Keyword.take([
      :role,
      :storage,
      :appid,
      :component_appid,
      :component_appsecret,
      :encoding_aes_key,
      :token
    ])
    |> gen_get_function()
  end

  defp gen_get_function(:mini_program, default_opts) do
    default_opts
    |> Keyword.take([:role, :storage, :appid, :appsecret, :encoding_aes_key, :token])
    |> gen_get_function()
  end

  defp gen_get_function(default_opts) do
    appid =
      case Keyword.get(default_opts, :appid) do
        appid when is_binary(appid) ->
          appid

        _ ->
          raise ArgumentError, "please set appid"
      end

    [
      quote do
        def default_opts, do: unquote(default_opts)
      end,
      quote do
        def get_access_token, do: WeChat.Storage.Cache.get_cache(unquote(appid), :access_token)
      end
      | Enum.map(default_opts, fn {key, value} ->
          quote do
            def unquote(key)(), do: unquote(value)
          end
        end)
    ]
  end

  defp gen_sub_module(module, parent_module) do
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

    client_module =
      parent_module
      |> Module.split()
      |> List.last()
      |> String.to_atom()

    new_module_name =
      module
      |> Module.split()
      |> List.last()
      |> String.to_atom()

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

            {:defmodule, c_m, [{:__aliases__, c_a, [new_module_name]}, do_list]}

          {:spec, c_s, ast} ->
            # del first argument
            ast =
              Macro.prewalk(
                ast,
                fn
                  {fun_name, context, [{{:., _, [{:__aliases__, _, _}, :client]}, _, _} | args]}
                  when is_atom(fun_name) ->
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
                    # replace first argument
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
            # IO.inspect(ast)
            ast
        end
      )

    {file, ast}
  end

  defmodule Article do
    @moduledoc "文章"

    @typedoc """
    | argument            | 是否必须 | 说明 |
    | ------------------- | ------ | --- |
    | title               | 是 | 标题 |
    | thumb_media_id      | 是 | 图文消息的封面图片素材id（必须是永久mediaID）|
    | author              | 否 | 作者 |
    | digest              | 否 | 图文消息的摘要，仅有单图文消息才有摘要，多图文此处为空。如果本字段为没有填写，则默认抓取正文前64个字。 |
    | show_cover_pic      | 是 | 是否显示封面，0为false，即不显示，1为true，即显示 |
    | content             | 是 | 图文消息的具体内容，支持HTML标签，必须少于2万字符，小于1M，且此处会去除JS,涉及图片url必须来源 "上传图文消息内的图片获取URL"接口获取。外部图片url将被过滤。 |
    | content_source_url  | 是 | 图文消息的原文地址，即点击“阅读原文”后的URL |
    | need_open_comment   | 否 | Uint32 是否打开评论，0不打开，1打开 |
    | only_fans_can_comment | 否 | Uint32 是否粉丝才可评论，0所有人可评论，1粉丝才可评论 |
    """
    @type t :: %__MODULE__{
            title: String.t(),
            thumb_media_id: WeChat.Material.media_id(),
            author: String.t(),
            digest: String.t(),
            show_cover_pic: integer,
            content: String.t(),
            content_source_url: String.t(),
            need_open_comment: integer(),
            only_fans_can_comment: integer()
          }

    defstruct [
      :title,
      :thumb_media_id,
      :author,
      :digest,
      {:show_cover_pic, 1},
      :content,
      {:content_source_url, ""},
      {:need_open_comment, 1},
      {:only_fans_can_comment, 1}
    ]
  end
end
