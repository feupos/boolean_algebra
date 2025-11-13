defmodule BooleanAlgebra.Simplifier do
  @moduledoc """
  Simplifies boolean expressions using boolean algebra laws.

  This minimization procedure is not unique because it lacks specific rules to predict the succeeding step in
  the manipulative process. So the simplifier applies a set of common simplification rules iteratively and the
  output will depend on the order of rule application.
  Although the truth table representation of a Boolean expression is unique, its algebraic
  expression may be represented by many different forms.
  """

  alias BooleanAlgebra.{AST, TruthTable, QMC, Petrick}

  @doc """
  Simplifies a boolean expression.
  """
  @spec simplify(AST.t()) :: AST.t()
  def simplify(expr) do
    expr
    |> minimize()
    |> apply_rules()
  end

  # Given a Boolean AST, find the minimal expression using QMC and Petrick's method
  def minimize(expr) do
    vars = AST.variables(expr)
    truth_table = TruthTable.from_ast(expr)

    minterms =
      truth_table
      |> Enum.with_index()
      |> Enum.filter(fn {row, _idx} -> Map.get(row, :result) end)
      |> Enum.map(fn {_row, idx} -> idx end)

    # Handle empty minterms (expression always false)
    if minterms == [] do
      {:const, false}
    else
      prime_implicants = QMC.minimize(minterms, length(vars))
      coverage_map = QMC.coverage_table(prime_implicants, minterms, length(vars))

      minimal_covers = Petrick.minimal_cover(coverage_map)

      implicant_set =
        case minimal_covers do
          [first_set | _] -> first_set
          [] -> raise "No minimal covers found"
        end

      implicant_set
      |> Enum.map(&implicant_to_ast(&1, vars))
      |> Enum.reduce(fn ast1, ast2 -> {:or, ast1, ast2} end)
    end
  end

  # Convert an implicant pattern (e.g., [true, :dont_care, false]) back to AST
  defp implicant_to_ast(implicant, vars) when is_list(implicant) do
    literals =
      implicant
      |> Enum.with_index()
      |> Enum.reduce([], fn
        {true, i}, acc -> [{:var, Enum.at(vars, i)} | acc]
        {false, i}, acc -> [{:not, {:var, Enum.at(vars, i)}} | acc]
        {:dont_care, _i}, acc -> acc
      end)

    case literals do
      [] -> {:const, true}
      [single] -> single
      _ -> Enum.reduce(literals, fn lit, acc -> {:and, lit, acc} end)
    end
  end

  # Simplify XOR expressed as OR of ANDs
  defp apply_rules({:or, {:and, {:not, a}, b}, {:and, {:not, b}, a}}),
    do: apply_rules({:xor, a, b})

  defp apply_rules({:or, {:and, {:not, a}, b}, {:and, a, {:not, b}}}),
    do: apply_rules({:xor, a, b})

  defp apply_rules({:or, {:and, a, {:not, b}}, {:and, {:not, a}, b}}),
    do: apply_rules({:xor, a, b})

  defp apply_rules({:or, {:and, a, {:not, b}}, {:and, b, {:not, a}}}),
    do: apply_rules({:xor, a, b})

  defp apply_rules({op, left, right}) when op in [:and, :or, :xor] do
    {op, apply_rules(left), apply_rules(right)}
  end

  defp apply_rules({:not, expr}), do: {:not, apply_rules(expr)}
  defp apply_rules(expr), do: expr
end
