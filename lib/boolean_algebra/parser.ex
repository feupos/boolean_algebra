defmodule BooleanAlgebra.Parser do
  @moduledoc """
  Parser for boolean expressions from tokens.
  """

  alias BooleanAlgebra.AST

  # Parsing with precedence climbing
  def parse_tokens(tokens) do
    case parse_precedence(tokens, 0) do
      {:error, _} = error -> error
      {expr, []} -> {:ok, expr}
      {_expr, _rest} -> {:error, "Unexpected tokens at end"}
    end
  end

  defp parse_precedence(tokens, min_prec) do
    with {left, rest} <- parse_unary(tokens) do
      parse_binary(left, rest, min_prec)
    end
  end

  defp parse_binary(left, tokens, min_prec) do
    case tokens do
      [op | rest] when op in [:and, :or, :xor] ->
        prec = precedence(op)

        if prec >= min_prec do
          case parse_precedence(rest, prec + 1) do
            {:error, _} = error ->
              error

            {right, rest2} ->
              expr = {op, left, right}
              parse_binary(expr, rest2, min_prec)
          end
        else
          {left, tokens}
        end

      _ ->
        {left, tokens}
    end
  end

  defp parse_unary([:lparen | rest]) do
    case parse_precedence(rest, 0) do
      {expr, [:rparen | rest2]} -> {expr, rest2}
      {_expr, _} -> {:error, "Missing closing parenthesis"}
    end
  end

  defp parse_unary([{:const, value} | rest]), do: {AST.const_node(value), rest}
  defp parse_unary([{:var, name} | rest]), do: {AST.var_node(name), rest}

  defp parse_unary([:not | rest]) do
    case parse_unary(rest) do
      {:error, _} = error -> error
      {expr, new_rest} -> {AST.not_node(expr), new_rest}
    end
  end

  defp parse_unary([]), do: {:error, "Unexpected end of expression"}

  # Operator precedence (higher = tighter binding)
  defp precedence(:or), do: 1
  defp precedence(:xor), do: 2
  defp precedence(:and), do: 3
end
