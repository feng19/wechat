defmodule WeChat.Builder.Utils do
  @moduledoc false

  def gen_sub_modules(sub_modules, parent_module, drop_amount \\ 1) do
    client_module =
      parent_module
      |> Module.split()
      |> List.last()
      |> String.to_atom()

    {sub_module_ast_list, files} =
      sub_modules
      |> Enum.uniq()
      |> Enum.map_reduce([], fn module, acc ->
        {file, ast} = _gen_sub_module(module, parent_module, client_module, drop_amount)
        {ast, [quote(do: @external_resource(unquote(file))) | acc]}
      end)

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
