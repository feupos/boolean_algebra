defmodule BooleanAlgebra.Formatter do
  @moduledoc """
  Formats boolean expressions to string representation in infix notation only,
  with configurable operator style and parentheses policy.
  """

  @type format_opts :: [
          operators: :symbolic | :word,
          parentheses: :minimal | :full
        ]

  @doc """
  Converts a boolean expression to infix string format.
  ## Options
  - `:operators` - :symbolic (default, &|!) or :word (AND, OR, NOT)
  - `:parentheses` - :minimal (default) or :full
  """
  def to_string(expr, opts \\ []) do
    operators = Keyword.get(opts, :operators, :symbolic)
    parentheses = Keyword.get(opts, :parentheses, :minimal)

    format(expr, operators, parentheses, 0)
  end

  # Infix notation only
  defp format({:const, true}, _operators, _parentheses, _), do: "true"
  defp format({:const, false}, _operators, _parentheses, _), do: "false"
  defp format({:var, name}, _operators, _parentheses, _), do: Atom.to_string(name)

  defp format({:not, expr}, operators, parentheses, _parent_prec) do
    op = not_op(operators)
    inner = format(expr, operators, parentheses, 6)
    "#{op}#{inner}"
  end

  defp format({op, left, right}, operators, parentheses, parent_prec) do
    prec = precedence(op)
    op_str = binary_op(op, operators)

    left_str = format(left, operators, parentheses, prec)
    right_str = format(right, operators, parentheses, prec)

    result = "#{left_str} #{op_str} #{right_str}"

    if parentheses == :full or (parentheses == :minimal and prec < parent_prec) do
      "(#{result})"
    else
      result
    end
  end

  # Helper functions
  defp not_op(:symbolic), do: "!"
  defp not_op(:word), do: "NOT "

  defp binary_op(:and, :symbolic), do: "&"
  defp binary_op(:or, :symbolic), do: "|"
  defp binary_op(:xor, :symbolic), do: "^"

  defp binary_op(:and, :word), do: "AND"
  defp binary_op(:or, :word), do: "OR"
  defp binary_op(:xor, :word), do: "XOR"

  defp precedence(:or), do: 1
  defp precedence(:xor), do: 2
  defp precedence(:and), do: 3
end
