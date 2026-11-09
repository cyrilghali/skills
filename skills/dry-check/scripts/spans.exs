# Line spans for Credo DuplicatedCode findings. Plain `elixir`, no mix, no compile.
# stdin: "<file>\t<start line>\t<mass>" per side.
# stdout: "<file>\t<start line>\t<mass>\t<first>\t<last>\t<node|def|line>" per side.
defmodule Spans do
  # Same count as Credo's DuplicatedCode.mass/1: every tuple Macro.prewalk visits.
  def mass(ast) do
    {_, n} = Macro.prewalk(ast, 0, fn node, acc -> {node, if(is_tuple(node), do: acc + 1, else: acc)} end)
    n
  end

  # Same start line Credo reports for a node (DuplicatedCode.line_no_for/1).
  def line_no({:__block__, _, args}), do: line_no(args)
  def line_no({:do, args}), do: line_no(args)
  def line_no({a, meta, _}) when is_atom(a), do: meta[:line]
  def line_no(list) when is_list(list), do: Enum.find_value(list, &line_no/1)
  def line_no(nil), do: nil
  def line_no(other), do: other |> do_block() |> line_no()

  defp do_block({_, _, args}) when is_list(args), do: do_block(args)
  defp do_block([{:do, block} | _]), do: block
  defp do_block(args) when is_list(args), do: Enum.find_value(args, fn {:do, b} -> b; _ -> nil end)
  defp do_block(_), do: nil

  def lines(ast) do
    {_, acc} =
      Macro.prewalk(ast, [], fn
        {_, meta, _} = node, acc when is_list(meta) ->
          ls = for k <- [:line, :end, :closing], l = meta_line(meta[k]), do: l
          {node, ls ++ acc}

        node, acc ->
          {node, acc}
      end)

    acc
  end

  defp meta_line(n) when is_integer(n), do: n
  defp meta_line(kw) when is_list(kw), do: kw[:line]
  defp meta_line(_), do: nil

  def span(ast) do
    case lines(ast) do
      [] -> nil
      ls -> {Enum.min(ls), Enum.max(ls)}
    end
  end

  def nodes(ast) do
    {_, acc} = Macro.prewalk(ast, [], fn node, acc -> {node, if(is_tuple(node), do: [node | acc], else: acc)} end)
    Enum.reverse(acc)
  end

  def find_node(ast, line, mass) do
    Enum.find(nodes(ast), fn node ->
      mass(node) == mass and (safe_line_no(node) == line or own_line(node) == line)
    end)
  end

  defp safe_line_no(node), do: line_no(node)
  defp own_line({_, meta, _}) when is_list(meta), do: meta[:line]
  defp own_line(_), do: nil

  def enclosing_def(ast, line) do
    ast
    |> nodes()
    |> Enum.filter(fn
      {k, _, [_ | _]} when k in [:def, :defp, :defmacro, :defmacrop] -> true
      _ -> false
    end)
    |> Enum.map(&span/1)
    |> Enum.filter(fn
      {a, b} -> a <= line and line <= b
      _ -> false
    end)
    |> Enum.sort_by(fn {a, b} -> b - a end)
    |> List.first()
  end
end

asts = %{}

lines = IO.stream(:stdio, :line) |> Enum.map(&String.trim_trailing(&1, "\n")) |> Enum.reject(&(&1 == ""))

Enum.reduce(lines, asts, fn row, cache ->
  [file, line, mass] = String.split(row, "\t")
  {line, mass} = {String.to_integer(line), String.to_integer(mass)}

  {ast, cache} =
    case cache do
      %{^file => ast} -> {ast, cache}
      _ ->
        ast = file |> File.read!() |> Code.string_to_quoted!(token_metadata: true, columns: true)
        {ast, Map.put(cache, file, ast)}
    end

  {first, last, kind} =
    with node when not is_nil(node) <- Spans.find_node(ast, line, mass),
         {a, b} <- Spans.span(node) do
      {a, b, "node"}
    else
      _ ->
        case Spans.enclosing_def(ast, line) do
          {a, b} -> {a, b, "def"}
          nil -> {line, line, "line"}
        end
    end

  IO.puts(Enum.join([file, line, mass, first, last, kind], "\t"))
  cache
end)
