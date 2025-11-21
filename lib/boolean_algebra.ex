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
        Simplifier.simplify(ast)
        |> Formatter.to_string()
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
        original_complexity = Simplifier.complexity(ast)
        {simplified_ast, details} = Simplifier.simplify_with_details(ast)
        complexity = Simplifier.complexity(simplified_ast)

        details =
          details
          |> Map.put(:complexity, complexity)
          |> Map.put(:original_complexity, original_complexity)

        {:ok, Formatter.to_string(simplified_ast, opts), details}
    end
  end

  @doc """
  Processes a boolean expression and returns requested outputs.

  ## Options
    * `:output` - List of desired outputs: `:simplification`, `:truth_table`, `:details`.
      Defaults to `[:simplification]`.

  ## Returns
    * `{:ok, result_map}` where result_map contains keys for requested outputs.
    * `{:error, reason}`
  """
  def process(input, opts \\ []) when is_binary(input) do
    output_opts = Keyword.get(opts, :output, [:simplification])

    input
    |> parse()
    |> case do
      {:error, reason} ->
        {:error, reason}

      {:ok, ast} ->
        result = %{}

        # 1. Truth Table (if requested)
        result =
          if :truth_table in output_opts do
            Map.put(result, :truth_table, TruthTable.from_ast(ast))
          else
            result
          end

        # 2. Simplification and Details
        # If details are requested, we must run the full simplification with details.
        # If only simplification is requested, we run the optimized version.
        result =
          cond do
            :details in output_opts ->
              {simplified_ast, details} = Simplifier.simplify_with_details(ast)

              result
              |> Map.put(:details, details)
              |> Map.put(:simplification, Formatter.to_string(simplified_ast, opts))

            :simplification in output_opts ->
              simplified_ast = Simplifier.simplify(ast)
              Map.put(result, :simplification, Formatter.to_string(simplified_ast, opts))

            true ->
              result
          end

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
