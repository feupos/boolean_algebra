defmodule BooleanAlgebra do
  @moduledoc """
  A library for boolean algebra operations
  """

  alias BooleanAlgebra.{AST, Simplifier}

  @doc """
  Simplifies a boolean expression.
  """
  defdelegate simplify(expr), to: Simplifier


  @doc """
  Evaluates a boolean expression with given variable assignments.
  """
  defdelegate eval(expr, vars \\ %{}), to: AST

end
