defmodule BooleanAlgebra do
  @moduledoc """
  A library for boolean algebra operations
  """

  alias BooleanAlgebra.{AST, Simplifier, Lexer, Parser, Formatter}

  defp parse(input) when is_binary(input) do
    input
    |> Lexer.parse_text()
    |> Parser.parse_tokens()
  end

  @doc """
  Simplifies a boolean expression.
  """
  def simplify(input) when is_binary(input) do
    input
    |> parse()
    |> case do
      {:error, reason} ->
        raise ArgumentError, message: reason

      {:ok, ast} ->
        Simplifier.simplify(ast)
        |> Formatter.to_string()
    end
  end

  @doc """
  Evaluates a boolean expression with given variable assignments.
  """
  def eval(input, vars \\ %{}) when is_binary(input) do
    input
    |> parse()
    |> case do
      {:error, reason} -> raise ArgumentError, message: reason
      {:ok, ast} -> {:ok, AST.eval(ast, vars)}
    end
  end
end
