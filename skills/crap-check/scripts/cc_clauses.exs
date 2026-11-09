# Prints one tab-separated line per def clause of an Elixir file:
# module, name/arity, start line, end line, cyclomatic complexity (Credo's own count).
# Usage: elixir -pa <credo ebin> cc_clauses.exs <file.ex>
alias Credo.Check.Refactor.CyclomaticComplexity

defmodule CcClauses do
  @defs [:def, :defp, :defmacro, :defmacrop]

  def run(path) do
    ast =
      case Code.string_to_quoted(File.read!(path), token_metadata: true, columns: true) do
        {:ok, ast} ->
          ast

        {:error, {meta, msg, token}} ->
          IO.puts(:stderr, "cannot parse #{path}: line #{inspect(meta)} #{inspect(msg)}#{inspect(token)}")
          System.halt(3)
      end

    ast |> walk([], []) |> Enum.reverse() |> Enum.each(&IO.puts(Enum.join(&1, "\t")))
  end

  defp walk({:defmodule, _, [name, [do: body]]}, mods, acc), do: walk(body, mods ++ [mod_name(name)], acc)

  defp walk({op, meta, [head | _]} = node, mods, acc) when op in @defs do
    case signature(head) do
      nil -> acc
      sig -> [[Enum.join(mods, "."), sig, meta[:line], last_line(node), round(CyclomaticComplexity.complexity_for(node))] | acc]
    end
  end

  defp walk({_, _, args}, mods, acc) when is_list(args), do: Enum.reduce(args, acc, &walk(&1, mods, &2))
  defp walk(list, mods, acc) when is_list(list), do: Enum.reduce(list, acc, &walk(&1, mods, &2))
  defp walk({_, value}, mods, acc), do: walk(value, mods, acc)
  defp walk(_, _, acc), do: acc

  defp mod_name({:__aliases__, _, parts}), do: Enum.map_join(parts, ".", &to_string/1)
  defp mod_name(other), do: Macro.to_string(other)

  defp signature({:when, _, [call | _]}), do: signature(call)
  defp signature({name, _, args}) when is_atom(name) and is_list(args), do: "#{name}/#{length(args)}"
  defp signature({name, _, nil}) when is_atom(name), do: "#{name}/0"
  defp signature(_), do: nil

  defp last_line(node) do
    {_, max} =
      Macro.prewalk(node, 0, fn
        {_, meta, _} = n, acc when is_list(meta) ->
          lines = [meta[:line], meta[:end][:line], meta[:closing][:line]]
          {n, Enum.max([acc | Enum.filter(lines, &is_integer/1)])}

        n, acc ->
          {n, acc}
      end)

    max
  end
end

CcClauses.run(hd(System.argv()))
