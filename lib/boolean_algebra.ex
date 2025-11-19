defmodule BooleanAlgebra do
  @moduledoc """
  A library for boolean algebra operations
  """

  alias BooleanAlgebra.{AST, Simplifier, Lexer, Parser, Formatter, TruthTable}

  @spec parse(String.t()) :: {:ok, AST.t()} | {:error, String.t()}
  defp parse(input) when is_binary(input) do
    input
    |> Lexer.tokenize()
    |> Parser.parse()
  end

  @doc """
  Simplifies a boolean expression.
  """
  @spec simplify(String.t()) :: String.t()
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
      {:ok, ast} -> AST.eval(ast, vars)
    end
  end

  @doc """
  Generates a truth table for the given expression.

  Returns a list of maps with variable assignments and results.
  """
  def truth_table(input) do
    input
    |> parse()
    |> case do
      {:error, reason} ->
        raise ArgumentError, message: reason

      {:ok, ast} ->
        TruthTable.from_ast(ast)
    end
  end
end
