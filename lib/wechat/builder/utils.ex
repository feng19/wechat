defmodule WeChat.Builder.Utils do
  @moduledoc false
  require Logger

  def gen_code_name(client) do
    client |> to_string() |> String.split(".") |> List.last() |> String.downcase()
  end

  def gen_sub_modules(sub_modules, client_module, drop_amount \\ 1) do
    {sub_module_ast_list, files} =
      sub_modules
      |> Enum.uniq()
      |> Enum.map_reduce([], fn module, acc ->
        {file, ast} = _gen_sub_module(module, client_module, drop_amount)
        {ast, [quote(do: @external_resource(unquote(file))) | acc]}
      end)

    files ++ sub_module_ast_list
  end

  defp _gen_sub_module(module, client, drop_amount) do
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

    sub_module =
      module
      |> Module.split()
      |> Enum.drop(drop_amount)
      |> Enum.map(&String.to_atom/1)

    {_, funs} =
      Macro.prewalk(ast, [], fn
        sub_ast = {o, _c_s, ast}, funs when o in [:def, :defp] ->
          fun_name =
            case hd(ast) do
              {:when, _, [{fun_name, _, _} | _]} -> fun_name
              {fun_name, _, _} -> fun_name
            end

          {sub_ast, Enum.uniq([fun_name | funs])}

        sub_ast, funs ->
          {sub_ast, funs}
      end)

    ast =
      Macro.prewalk(
        ast,
        &ast_transform(&1, %{module: module, client: client, sub_module: sub_module, funs: funs})
      )

    {file, ast}
  end

  defp ast_transform({:defmodule, c_m, [{:__aliases__, c_a, _}, do_list]}, acc) do
    [do: {:__block__, [], list}] = do_list

    do_list = [
      do:
        {:__block__, [],
         [
           quote do
             @file unquote(to_string(acc.module))
             @compile {:no_warn_undefined, unquote(acc.client)}
           end
           | list
         ]}
    ]

    {:defmodule, c_m, [{:__aliases__, c_a, acc.sub_module}, do_list]}
  end

  defp ast_transform({:spec, c_s, ast}, _acc) do
    ast =
      Macro.prewalk(
        ast,
        fn
          {fun_name, context, [{{:., _, [{:__aliases__, _, _}, :client]}, _, _} | args]}
          when is_atom(fun_name) ->
            # call inner function, del first argument: send(client, ...) => send(...)
            {fun_name, context, args}

          sub_ast ->
            sub_ast
        end
      )

    {:spec, c_s, ast}
  end

  defp ast_transform({o, c_s, ast}, %{client: client, funs: funs}) when o in [:def, :defp] do
    ast =
      Macro.prewalk(
        ast,
        fn
          {:., context, [{:client, c_c, nil}, fun_name]} ->
            # replace client: client.appid() => Client.appid()
            {:., context, [{:__aliases__, c_c, [client]}, fun_name]}

          {fun_name, context, [{:client, c_c, nil} | args]} when is_atom(fun_name) ->
            if fun_name in funs do
              # call inner function, del first argument: send(client, ...) => send(...)
              {fun_name, context, args}
            else
              # call external function, del first argument: send(client, ...) => send(Client, ...)
              {fun_name, context, [{:__aliases__, c_c, [client]} | args]}
            end

          {:client, c_c, nil} ->
            # replace client: client => Client
            {:__aliases__, c_c, [client]}

          sub_ast ->
            sub_ast
        end
      )

    {:def, c_s, ast}
  end

  defp ast_transform(ast, _acc), do: ast

  def check_env_option?(:runtime_env), do: true
  def check_env_option?({:runtime_env, app}) when is_atom(app), do: true
  def check_env_option?(:compile_env), do: true
  def check_env_option?({:compile_env, app}) when is_atom(app), do: true
  def check_env_option?(_), do: false

  def handle_env_option(_client, key, :runtime_env) do
    quote do
      def unquote(key)(),
        do: Application.fetch_env!(:wechat, __MODULE__) |> Keyword.fetch!(unquote(key))
    end
  end

  def handle_env_option(_client, key, {:runtime_env, app}) do
    quote do
      def unquote(key)(), do: Application.fetch_env!(unquote(app), unquote(key))
    end
  end

  def handle_env_option(client, key, :compile_env) do
    value = Application.fetch_env!(:wechat, client) |> Keyword.fetch!(key)

    quote do
      def unquote(key)(), do: unquote(value)
    end
  end

  def handle_env_option(client, key, {:compile_env, app}) do
    value = Application.fetch_env!(app, client) |> Keyword.fetch!(key)

    quote do
      def unquote(key)(), do: unquote(value)
    end
  end

  def handle_env_option(_, _, _), do: :not_handle

  def warn_unknown_option(options, known_keys, client) when is_list(options) do
    do_warn_unknown_option(Keyword.keys(options) -- known_keys, client)
  end

  def warn_unknown_option(options, known_keys, client) when is_map(options) do
    do_warn_unknown_option(Map.keys(options) -- known_keys, client)
  end

  defp do_warn_unknown_option(unknown_keys, client) do
    Enum.each(unknown_keys, fn key ->
      Logger.warning("Found unknown option: #{key} for #{client}")
    end)
  end
end
