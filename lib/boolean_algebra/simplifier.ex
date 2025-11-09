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
  def simplify_old(expr) do
    expr
    |> canonicalize()
    |> apply_rules()
    |> case do
      ^expr -> expr
      simplified -> simplify(simplified)
    end
  end

  def simplify(expr), do: simplify_recurse(minimize(expr))

  def simplify_recurse(expr) do
    expr
    |> factor_common_terms()
    |> apply_rules()
    |> case do
      ^expr -> expr
      simplified -> simplify_recurse(simplified)
    end
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

  # Convert an implicant pattern (e.g., "1-0") back to AST
  defp implicant_to_ast(implicant, vars) do
    literals =
      String.graphemes(implicant)
      |> Enum.with_index()
      |> Enum.reduce([], fn
        {"1", i}, acc -> [{:var, Enum.at(vars, i)} | acc]
        {"0", i}, acc -> [{:not, {:var, Enum.at(vars, i)}} | acc]
        {"-", _i}, acc -> acc
      end)

    case literals do
      [] -> {:const, true}
      [single] -> single
      _ -> Enum.reduce(literals, fn lit, acc -> {:and, acc, lit} end)
    end
  end

  # Canonicalization flattens and sorts associative nodes
  defp canonicalize({:and, left, right}),
    do: rebuild_op(:and, flatten(:and, left) ++ flatten(:and, right))

  defp canonicalize({:or, left, right}),
    do: rebuild_op(:or, flatten(:or, left) ++ flatten(:or, right))

  defp canonicalize(expr), do: expr

  # Flatten nested associative nodes and canonicalize operands
  defp flatten(op, {operator, left, right}) when operator == op do
    flatten(op, left) ++ flatten(op, right)
  end

  defp flatten(_op, expr), do: [canonicalize(expr)]

  # Remove duplicates and sort operands for commutative ops
  defp rebuild_op(op, operands) do
    norm = operands |> Enum.uniq() |> Enum.sort()

    case norm do
      [single] -> single
      _ -> Enum.reduce(norm, fn x, acc -> {op, acc, x} end)
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

  # Simplify XOR expressed as OR of ANDs
  defp apply_rules({:or, {:and, {:not, a}, b}, {:and, {:not, b}, a}}) do
    simplify_xor(a, b)
  end

  defp apply_rules({:or, {:and, {:not, a}, b}, {:and, {:not, b}, a}}) do
    simplify_xor(a, b)
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
  # Double negation
  defp simplify_not({:not, expr}), do: expr

  # De Morgan's laws
  defp simplify_not({:and, left, right}) do
    {:or, {:not, left}, {:not, right}}
  end

  defp simplify_not({:or, left, right}) do
    {:and, {:not, left}, {:not, right}}
  end

  defp simplify_not(expr), do: {:not, expr}

  # AND simplification
  # 0 && a = 0
  defp simplify_and({:const, false}, _), do: {:const, false}
  # a && 0 = 0
  defp simplify_and(_, {:const, false}), do: {:const, false}
  # 1 && a = a
  defp simplify_and({:const, true}, right), do: right
  # a && 1 = a
  defp simplify_and(left, {:const, true}), do: left
  # a && a = a
  defp simplify_and(left, right) when left == right, do: left

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

  defp simplify_or({:and, a, b}, {:xor, c, d})
       when (a == c and b == d) or (a == d and b == c),
       do: simplify_or(a, b)

  defp simplify_or({:xor, a, b}, {:and, c, d})
       when (a == c and b == d) or (a == d and b == c),
       do: simplify_or(a, b)

  # 1 || a = 1
  defp simplify_or({:const, true}, _), do: {:const, true}
  # a || 1 = 1
  defp simplify_or(_, {:const, true}), do: {:const, true}
  # 0 || a = a
  defp simplify_or({:const, false}, right), do: right
  # a || 0 = a
  defp simplify_or(left, {:const, false}), do: left
  # a || a = a
  defp simplify_or(left, right) when left == right, do: left

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
  # 0 XOR a = a
  defp simplify_xor({:const, false}, right), do: right
  # a XOR 0 = a
  defp simplify_xor(left, {:const, false}), do: left
  # 1 XOR a = !a
  defp simplify_xor({:const, true}, right), do: {:not, right}
  # a XOR 1 = !a
  defp simplify_xor(left, {:const, true}), do: {:not, left}
  # a XOR a = 0
  defp simplify_xor(left, right) when left == right, do: {:const, false}

  defp simplify_xor(left, right), do: {:xor, left, right}

  # Factor common terms from OR expressions like a OR (a AND b) = a
  defp factor_common_terms({:or, left, right}) do
    # Fully flatten nested OR operands recursively and canonicalize them
    operands =
      flatten(:or, {:or, left, right})
      |> Enum.flat_map(fn
        {:or, l, r} -> flatten(:or, {:or, l, r})
        other -> [canonicalize(other)]
      end)
      |> Enum.map(&canonicalize/1)

    # Map operands to sets of conjunctive factors
    conjunctive_sets =
      Enum.map(operands, fn
        {:and, _, _} = and_expr -> MapSet.new(flatten(:and, and_expr))
        operand -> MapSet.new([operand])
      end)

    # Find common factors among ALL operands
    common_factors = Enum.reduce(conjunctive_sets, hd(conjunctive_sets), &MapSet.intersection/2)

    if MapSet.size(common_factors) > 0 do
      # Remove common factors from operands
      reduced_sets = Enum.map(conjunctive_sets, &MapSet.difference(&1, common_factors))

      # Convert common factors to AST node
      common_factor_ast = factors_to_ast(common_factors)

      # Convert reduced sets back to AST and rebuild OR expression
      reduced_ast_operands =
        Enum.map(reduced_sets, &factors_to_ast/1)
        |> List.wrap()

      # Factor out common factor and recurse for further factoring
      {:and, common_factor_ast, rebuild_op(:or, reduced_ast_operands)}
      |> factor_common_terms()
    else
      rebuild_op(:or, operands)
    end
  end

  # Recursively factor inside AND nodes and other nodes
  defp factor_common_terms({:and, left, right}) do
    left = factor_common_terms(left)
    right = factor_common_terms(right)
    rebuild_op(:and, [left, right])
  end

  defp factor_common_terms(other), do: other

  # Convert MapSet of factors to AST node
  defp factors_to_ast(factors) do
    case MapSet.to_list(factors) do
      [] -> {:const, true}
      [single] -> single
      list -> rebuild_op(:and, list)
    end
  end
end
