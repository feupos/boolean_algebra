defmodule BooleanAlgebra.AST do
  @moduledoc """
  Abstract Syntax Tree representation for boolean expressions.
  """

  @type t ::
          {:var, String.t()}
          | {:const, boolean()}
          | {:not, t()}
          | {:and, t(), t()}
          | {:or, t(), t()}
          | {:xor, t(), t()}

  @doc """
  Creates a variable node.
  """
  @spec var_node(String.t()) :: {:var, String.t()}
  def var_node(name), do: {:var, name}

  @doc """
  Creates a constant node (true/false).
  """
  @spec const_node(boolean()) :: {:const, boolean()}
  def const_node(value) when is_boolean(value), do: {:const, value}

  @doc """
  Creates a NOT node.
  """
  @spec not_node(t()) :: {:not, t()}
  def not_node(expr), do: {:not, expr}

  @doc """
  Creates an AND node.
  """
  @spec and_node(t(), t()) :: {:and, t(), t()}
  def and_node(left, right), do: {:and, left, right}

  @doc """
  Creates an OR node.
  """
  @spec or_node(t(), t()) :: {:or, t(), t()}
  def or_node(left, right), do: {:or, left, right}

  @doc """
  Creates an XOR node.
  """
  @spec xor_node(t(), t()) :: {:xor, t(), t()}
  def xor_node(left, right), do: {:xor, left, right}

  @doc """
  Evaluates the boolean expression with given variable assignments.
  """
  @spec eval(t(), %{String.t() => boolean()}) :: boolean()
  # Exclude default for coverage
  # def eval(expr, vars \\ %{})
  def eval({:const, value}, _vars), do: value
  def eval({:var, name}, vars) do
    case Map.fetch(vars, name) do
      {:ok, value} -> value
      :error -> raise ArgumentError, "Variable #{inspect(name)} not found in vars map"
    end
  end
  def eval({:not, expr}, vars), do: not eval(expr, vars)
  def eval({:and, left, right}, vars), do: eval(left, vars) and eval(right, vars)
  def eval({:or, left, right}, vars), do: eval(left, vars) or eval(right, vars)
  def eval({:xor, left, right}, vars), do: eval(left, vars) != eval(right, vars)
end
