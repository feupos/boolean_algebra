defmodule BooleanAlgebra.Simplifier do
  @moduledoc """
  Simplifies boolean expressions using boolean algebra laws.
  """

  alias BooleanAlgebra.AST

  @doc """
  Simplifies a boolean expression.
  """
  @spec simplify(AST.t()) :: AST.t()
  def simplify(expr) do
    expr
    |> apply_rules()  # Apply simplification rules to the expression
    |> case do
      ^expr -> expr  # If the expression hasn't changed, return it
      simplified -> simplify(simplified)  # Recursively simplify the new expression
    end
  end

  # Apply simplification rules bottom-up
  defp apply_rules({:not, expr}) do
    simplified = apply_rules(expr)
    simplify_not(simplified)
  end

  defp apply_rules({:and, left, right}) do
    left = apply_rules(left)
    right = apply_rules(right)
    simplify_and(left, right)
  end

  defp apply_rules({:or, left, right}) do
    left = apply_rules(left)
    right = apply_rules(right)
    simplify_or(left, right)
  end

  defp apply_rules({:xor, left, right}) do
    left = apply_rules(left)
    right = apply_rules(right)
    simplify_xor(left, right)
  end

  defp apply_rules(expr), do: expr

  # NOT simplification
  defp simplify_not({:const, value}), do: {:const, not value}
  defp simplify_not({:not, expr}), do: expr  # Double negation

  # De Morgan's laws
  defp simplify_not({:and, left, right}) do
    {:or, {:not, left}, {:not, right}}
  end

  defp simplify_not({:or, left, right}) do
    {:and, {:not, left}, {:not, right}}
  end

  defp simplify_not(expr), do: {:not, expr}

  # AND simplification
  defp simplify_and({:const, false}, _), do: {:const, false}  # 0 && a = 0
  defp simplify_and(_, {:const, false}), do: {:const, false}  # a && 0 = 0
  defp simplify_and({:const, true}, right), do: right  # 1 && a = a
  defp simplify_and(left, {:const, true}), do: left  # a && 1 = a
  defp simplify_and(left, right) when left == right, do: left  # a && a = a

  # a && !a = 0
  defp simplify_and(left, {:not, right}) when left == right, do: {:const, false}
  defp simplify_and({:not, left}, right) when left == right, do: {:const, false}

  # Absorption: a && (a || b) = a
  defp simplify_and(a, {:or, b, _c}) when a == b, do: a
  defp simplify_and(a, {:or, _b, c}) when a == c, do: a
  defp simplify_and({:or, b, _c}, a) when a == b, do: a
  defp simplify_and({:or, _b, c}, a) when a == c, do: a

  defp simplify_and(left, right), do: {:and, left, right}

  # OR simplification
  defp simplify_or({:const, true}, _), do: {:const, true}  # 1 || a = 1
  defp simplify_or(_, {:const, true}), do: {:const, true}  # a || 1 = 1
  defp simplify_or({:const, false}, right), do: right  # 0 || a = a
  defp simplify_or(left, {:const, false}), do: left  # a || 0 = a
  defp simplify_or(left, right) when left == right, do: left  # a || a = a

  # a || !a = 1
  defp simplify_or(left, {:not, right}) when left == right, do: {:const, true}
  defp simplify_or({:not, left}, right) when left == right, do: {:const, true}

  # Absorption: a || (a && b) = a
  defp simplify_or(a, {:and, b, _c}) when a == b, do: a
  defp simplify_or(a, {:and, _b, c}) when a == c, do: a
  defp simplify_or({:and, b, _c}, a) when a == b, do: a
  defp simplify_or({:and, _b, c}, a) when a == c, do: a

  defp simplify_or(left, right), do: {:or, left, right}

  # XOR simplification
  defp simplify_xor({:const, false}, right), do: right  # 0 XOR a = a
  defp simplify_xor(left, {:const, false}), do: left  # a XOR 0 = a
  defp simplify_xor({:const, true}, right), do: {:not, right}  # 1 XOR a = !a
  defp simplify_xor(left, {:const, true}), do: {:not, left}  # a XOR 1 = !a
  defp simplify_xor(left, right) when left == right, do: {:const, false}  # a XOR a = 0
end
