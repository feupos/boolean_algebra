defmodule BooleanAlgebra do
  @moduledoc """
  A library for boolean algebra operations
  """

  alias BooleanAlgebra.{AST, Simplifier, Lexer, Parser, Formatter}
  import Bitwise

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
        vars = AST.variables(ast)
        n = length(vars)

        for i <- 0..(Integer.pow(2, n) - 1) do
          assignment =
            vars
            |> Enum.with_index()
            |> Enum.map(fn {var, idx} ->
              bit = i >>> idx &&& 1
              {var, bit == 1}
            end)
            |> Map.new()

          result = AST.eval(ast, assignment)
          Map.put(assignment, :result, result)
        end
    end
  end
end
