
defmodule BooleanAlgebra.Lexer do
  @moduledoc """
  Parser for boolean expressions from string format.

  Supported syntax:
  - Variables: a, b, x, y, etc. (single letters or alphanumeric)
  - Constants: true, false, 1, 0
  - NOT: !, ~, NOT
  - AND: &, &&, AND, *
  - OR: |, ||, OR, +
  - XOR: ^, XOR
  - Parentheses: ()
  """
  @doc """
  Parses a boolean expression from string.
  """
  def parse_text(input) when is_binary(input) do
    input
    |> tokenize()
  end

  # Tokenization
  defp tokenize(input) do
    input
    # Sanitize input by removing whitespace
    |> String.replace(~r/\s+/, "")
    # Convert to list of characters
    |> String.graphemes()
    # Start tokenization
    |> do_tokenize([])
    # Reverse the accumulated tokens
    |> Enum.reverse()
  end

  defp do_tokenize([], acc), do: acc

  defp do_tokenize(["(" | rest], acc), do: do_tokenize(rest, [:lparen | acc])
  defp do_tokenize([")" | rest], acc), do: do_tokenize(rest, [:rparen | acc])

  defp do_tokenize(["!" | rest], acc), do: do_tokenize(rest, [:not | acc])
  defp do_tokenize(["~" | rest], acc), do: do_tokenize(rest, [:not | acc])

  defp do_tokenize(["&", "&" | rest], acc), do: do_tokenize(rest, [:and | acc])
  defp do_tokenize(["&" | rest], acc), do: do_tokenize(rest, [:and | acc])
  defp do_tokenize(["*" | rest], acc), do: do_tokenize(rest, [:and | acc])

  defp do_tokenize(["|", "|" | rest], acc), do: do_tokenize(rest, [:or | acc])
  defp do_tokenize(["|" | rest], acc), do: do_tokenize(rest, [:or | acc])
  defp do_tokenize(["+" | rest], acc), do: do_tokenize(rest, [:or | acc])

  defp do_tokenize(["^" | rest], acc), do: do_tokenize(rest, [:xor | acc])

  defp do_tokenize([c | rest], acc) when c in ["0", "1"] do
    value = if c == "1", do: true, else: false
    do_tokenize(rest, [{:const, value} | acc])
  end

  defp do_tokenize([c | rest], acc) do
    case parse_identifier([c | rest]) do
      {id, remaining} -> do_tokenize(remaining, [id | acc])
      nil -> do_tokenize(rest, acc)
    end
  end

  defp parse_identifier(chars) do
    {id_chars, rest} = Enum.split_while(chars, &(&1 =~ ~r/[a-zA-Z0-9]/))

    case Enum.join(id_chars) do
      "" -> nil
      "true" -> {{:const, true}, rest}
      "false" -> {{:const, false}, rest}
      "TRUE" -> {{:const, true}, rest}
      "FALSE" -> {{:const, false}, rest}
      "NOT" -> {:not, rest}
      "AND" -> {:and, rest}
      "OR" -> {:or, rest}
      "XOR" -> {:xor, rest}
      id -> {{:var, id}, rest}
    end
  end

end
