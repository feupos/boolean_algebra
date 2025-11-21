defmodule BooleanAlgebra do
  @moduledoc """
  A library for boolean algebra operations
  """

  alias BooleanAlgebra.{AST, Simplifier, Lexer, Parser, Formatter, TruthTable}

  @spec parse(String.t()) :: {:ok, AST.t()} | {:error, String.t()}
  def parse(input) when is_binary(input) do
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
        {simplified_ast, _details} = Simplifier.simplify(ast)
        Formatter.to_string(simplified_ast)
    end
  end

  @doc """
  Simplifies a boolean expression and returns detailed steps.
  Returns `{:ok, simplified_string, details}` or `{:error, reason}`.
  Accepts options for formatting: `operators: :symbolic | :word`.
  """
  def simplify_with_details(input, opts \\ []) when is_binary(input) do
    input
    |> parse()
    |> case do
      {:error, reason} ->
        {:error, reason}

      {:ok, ast} ->
        {simplified_ast, details} = Simplifier.simplify(ast)

        {:ok, Formatter.to_string(simplified_ast, opts), details}
    end
  end

  @doc """
  Processes a boolean expression and returns requested outputs.
  Always returns simplification, details, and truth table.

  ## Options
    * `operators` - Formatting options for the output string.

  ## Returns
    * `{:ok, result_map}` where result_map contains keys: `:simplification`, `:details`, `:truth_table`.
    * `{:error, reason}`
  """
  def process(input, opts \\ []) when is_binary(input) do
    input
    |> parse()
    |> case do
      {:error, reason} ->
        {:error, reason}

      {:ok, ast} ->
        {simplified_ast, details} = Simplifier.simplify(ast)
        simplification = Formatter.to_string(simplified_ast, opts)
        truth_table = TruthTable.from_ast(ast)

        result = %{
          simplification: simplification,
          details: details,
          truth_table: truth_table
        }

        {:ok, result}
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
