defmodule WeChat.ServerMessage.XmlParser do
  @moduledoc false

  @behaviour Saxy.Handler

  @spec parse(xml :: String.t()) :: {:ok, map()}
  def parse(xml) do
    Saxy.parse_string(xml, __MODULE__, [])
  end

  @impl true
  def handle_event(:start_document, _prolog, stack) do
    {:ok, stack}
  end

  def handle_event(:start_element, {element, _attributes}, stack) do
    {:ok, [{element, []} | stack]}
  end

  def handle_event(:characters, chars, [{element, content} | stack] = old) do
    case String.trim(chars) do
      "" ->
        {:ok, old}

      chars ->
        {:ok, [{element, [chars | content]} | stack]}
    end
  end

  def handle_event(:end_element, tag_name, stack) do
    [{^tag_name, content} | stack] = stack
    current = {tag_name, Enum.reverse(content)}

    case stack do
      [] ->
        {:ok, [current]}

      [{parent_tag_name, parent_content} | rest] ->
        parent = {parent_tag_name, [current | parent_content]}
        {:ok, [parent | rest]}
    end
  end

  def handle_event(:end_document, _data, stack) do
    state =
      stack
      |> stack_to_map()
      |> Map.get("xml")

    {:ok, state}
  end

  defp stack_to_map(stack) do
    Map.new(stack, fn
      {name, [content]} when is_binary(content) ->
        {name, content}

      {name, content} ->
        with [{"item", _}] <- Enum.uniq_by(content, &elem(&1, 0)) do
          content =
            content
            |> Stream.map(&elem(&1, 1))
            |> Enum.map(&stack_to_map/1)

          {name, content}
        else
          _ ->
            {name, stack_to_map(content)}
        end
    end)
  end
end
