defmodule BooleanAlgebra.Lexer do
  @moduledoc """
  Lexer for boolean expressions from string format.

  Supported syntax:
  - Variables: a, b, x, y, etc. (single letters or alphanumeric)
  - Constants: true, false, 1, 0
  - NOT: !, ~, NOT
  - AND: &, AND, *
  - OR: |, OR, +
  - XOR: ^, XOR
  - Parentheses: ()
  """

  @doc """
  Parses a boolean expression string into tokens.
  """
  def tokenize(input) when is_binary(input) do
    input
    |> prepare_input()
  end

  # Tokenize input preserving spacing and splitting operators/parentheses
  defp prepare_input(input) do
    input
    |> String.trim()
    # Add spaces around operators and parentheses for splitting
    # regex matches: ( ) + * ^ & | ! ~
    |> String.replace(~r/([()\+\*\^\&\|\!\~])/u, " \\1 ")
    # Replace multiple spaces with single space
    # regex matches whitespace sequences
    |> String.split(~r/\s+/, trim: true)
    |> tokenize_tokens([])
  end

  defp tokenize_tokens([], accumulated_tokens), do: Enum.reverse(accumulated_tokens)

  defp tokenize_tokens([token | rest], accumulated_tokens) do
    token =
      case String.upcase(token) do
        "(" -> :lparen
        ")" -> :rparen
        "NOT" -> :not
        "!" -> :not
        "~" -> :not
        "AND" -> :and
        "&" -> :and
        "*" -> :and
        "OR" -> :or
        "|" -> :or
        "+" -> :or
        "XOR" -> :xor
        "^" -> :xor
        "TRUE" -> {:const, true}
        "FALSE" -> {:const, false}
        "0" -> {:const, false}
        "1" -> {:const, true}
        _ -> {:var, String.to_atom(token)}
      end

    tokenize_tokens(rest, [token | accumulated_tokens])
  end
end
