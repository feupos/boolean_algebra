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

  @doc """
  Given a Boolean AST, find the minimal expression using QMC and Petrick's method
  """
  @spec minimize(AST.t()) :: AST.t()
  def minimize(expr) do
    vars = AST.variables(expr)

    minterms =
      expr
      |> TruthTable.from_ast()
      |> Enum.with_index()
      |> Enum.filter(fn {row, _idx} -> Map.get(row, :result) end)
      |> Enum.map(fn {_row, idx} -> idx end)

    # Handle empty minterms (expression always false)
    if minterms == [] do
      AST.const_node(false)
    else
      # Use optimized QMC without step tracking
      prime_implicants = QMC.minimize(minterms, length(vars))
      coverage_map = QMC.coverage_table(prime_implicants, minterms, length(vars))

      minimal_covers = Petrick.minimal_cover(coverage_map)

      best_cover =
        case minimal_covers do
          [] ->
            raise "No minimal covers found"

          covers ->
            Enum.min_by(covers, fn cover ->
              Enum.reduce(cover, 0, fn pi, acc ->
                acc + Enum.count(pi, &(&1 != :dont_care))
              end)
            end)
        end

      best_cover
      # Convert implicants back to AST
      |> Enum.map(&implicant_to_ast(&1, vars))
      # Sort by variables to ensure deterministic order (e.g. A before B)
      |> Enum.sort_by(&AST.variables/1)
      # Combine implicants with OR (left-associative to match expected structure)
      |> Enum.reduce(fn element, acc -> AST.or_node(acc, element) end)
    end
  end

  @doc """
  Same as minimize/1 but returns details about the minimization process.
  """
  def minimize_with_details(expr) do
    vars = AST.variables(expr)

    minterms =
      expr
      |> TruthTable.from_ast()
      |> Enum.with_index()
      |> Enum.filter(fn {row, _idx} -> Map.get(row, :result) end)
      |> Enum.map(fn {_row, idx} -> idx end)

    # Handle empty minterms (expression always false)
    if minterms == [] do
      {{:const, false}, %{qmc_steps: [], prime_implicants: []}}
    else
      {prime_implicants, qmc_steps} = QMC.minimize_with_steps(minterms, length(vars))
      coverage_map = QMC.coverage_table(prime_implicants, minterms, length(vars))

      minimal_covers = Petrick.minimal_cover(coverage_map)

      # Select the first minimal cover (could be multiple)
      final_ast =
        case minimal_covers do
          [first_set | _] -> first_set
          [] -> raise "No minimal covers found"
        end
        # Convert implicants back to AST
        |> Enum.map(&implicant_to_ast(&1, vars))
        # Combine implicants with OR
        |> Enum.reduce(fn ast1, ast2 -> {:or, ast1, ast2} end)

      {final_ast, %{qmc_steps: qmc_steps, prime_implicants: prime_implicants}}
    end
  end

  @doc """
  Simplifies a boolean expression and returns details.
  """
  def simplify_with_details(expr) do
    {minimized_ast, details} = minimize_with_details(expr)
    simplified_ast = apply_rules(minimized_ast)
    {simplified_ast, details}
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

  # ============================================================================
  # ABSORPTION LAW WITH NEGATION: X | (!X & Y) = X | Y
  # ============================================================================

  # Pattern: !A | (A & B) = !A | B
  defp apply_rules({:or, {:not, a1}, {:and, a2, b}}) when a1 == a2 do
    apply_rules({:or, {:not, a1}, b})
  end

  defp apply_rules({:or, {:not, a1}, {:and, b, a2}}) when a1 == a2 do
    apply_rules({:or, {:not, a1}, b})
  end

  # Pattern: (A & B) | !A = !A | B (commutative)
  defp apply_rules({:or, {:and, a1, b}, {:not, a2}}) when a1 == a2 do
    apply_rules({:or, {:not, a2}, b})
  end

  defp apply_rules({:or, {:and, b, a1}, {:not, a2}}) when a1 == a2 do
    apply_rules({:or, {:not, a2}, b})
  end

  # Pattern: A | (!A & B) = A | B
  defp apply_rules({:or, a1, {:and, {:not, a2}, b}}) when a1 == a2 do
    apply_rules({:or, a1, b})
  end

  defp apply_rules({:or, a1, {:and, b, {:not, a2}}}) when a1 == a2 do
    apply_rules({:or, a1, b})
  end

  # Pattern: (!A & B) | A = A | B (commutative)
  defp apply_rules({:or, {:and, {:not, a1}, b}, a2}) when a1 == a2 do
    apply_rules({:or, a2, b})
  end

  defp apply_rules({:or, {:and, b, {:not, a1}}, a2}) when a1 == a2 do
    apply_rules({:or, a2, b})
  end

  # ============================================================================
  # NESTED OR PATTERNS: Handle (A & B) | ((A & C) | !A)
  # ============================================================================

  # Pattern: (A & B) | ((A & C) | !A) - flatten and simplify
  defp apply_rules({:or, {:and, a1, b}, {:or, {:and, a2, c}, {:not, a3}}})
       when a1 == a2 and a2 == a3 do
    # This is: (A & B) | (A & C) | !A
    # Factor: A(B | C) | !A = !A | (B | C)
    apply_rules({:or, {:not, a3}, {:or, b, c}})
  end

  # Pattern: (A & B) | (!A | (A & C)) - different nesting order
  defp apply_rules({:or, {:and, a1, b}, {:or, {:not, a2}, {:and, a3, c}}})
       when a1 == a2 and a2 == a3 do
    apply_rules({:or, {:not, a2}, {:or, b, c}})
  end

  # ============================================================================
  # STANDARD ABSORPTION LAW: X | (X & Y) = X
  # ============================================================================

  # Pattern: A | (A & B) = A
  defp apply_rules({:or, a1, {:and, a2, _b}}) when a1 == a2 do
    apply_rules(a1)
  end

  defp apply_rules({:or, a1, {:and, _b, a2}}) when a1 == a2 do
    apply_rules(a1)
  end

  # Pattern: (A & B) | A = A (commutative)
  defp apply_rules({:or, {:and, a1, _b}, a2}) when a1 == a2 do
    apply_rules(a2)
  end

  defp apply_rules({:or, {:and, _b, a1}, a2}) when a1 == a2 do
    apply_rules(a2)
  end

  # Pattern: A & (A | B) = A
  defp apply_rules({:and, a1, {:or, a2, _b}}) when a1 == a2 do
    apply_rules(a1)
  end

  defp apply_rules({:and, a1, {:or, _b, a2}}) when a1 == a2 do
    apply_rules(a1)
  end

  # Pattern: (A | B) & A = A (commutative)
  defp apply_rules({:and, {:or, a1, _b}, a2}) when a1 == a2 do
    apply_rules(a2)
  end

  defp apply_rules({:and, {:or, _b, a1}, a2}) when a1 == a2 do
    apply_rules(a2)
  end

  # ============================================================================
  # XOR SIMPLIFICATION
  # ============================================================================

  # Simplify XOR expressed as OR of ANDs
  defp apply_rules({:or, {:and, {:not, a}, b}, {:and, {:not, b}, a}}),
    do: apply_rules({:xor, a, b})

  defp apply_rules({:or, {:and, {:not, a}, b}, {:and, a, {:not, b}}}),
    do: apply_rules({:xor, a, b})

  defp apply_rules({:or, {:and, a, {:not, b}}, {:and, {:not, a}, b}}),
    do: apply_rules({:xor, a, b})

  defp apply_rules({:or, {:and, a, {:not, b}}, {:and, b, {:not, a}}}),
    do: apply_rules({:xor, a, b})

  # ============================================================================
  # RECURSIVE APPLICATION
  # ============================================================================

  defp apply_rules({op, left, right}) when op in [:and, :or, :xor] do
    {op, apply_rules(left), apply_rules(right)}
  end

  defp apply_rules({:not, expr}), do: {:not, apply_rules(expr)}
  defp apply_rules(expr), do: expr

  @doc """
  Calculates the complexity of the expression based on the number of segments (literals).
  """
  def complexity({:var, _}), do: 1
  def complexity({:const, _}), do: 1
  def complexity({:not, expr}), do: complexity(expr)
  def complexity({_op, left, right}), do: complexity(left) + complexity(right)
end
