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
  Returns `{simplified_ast, details}`.
  """
  @spec simplify(AST.t()) :: {AST.t(), map()}
  def simplify(expr) do
    {minimized_ast, details} = minimize(expr)
    simplified_ast = apply_rules(minimized_ast)
    {simplified_ast, details}
  end

  @doc """
  Given a Boolean AST, find the minimal expression using QMC and Petrick's method.
  Returns `{minimized_ast, details}`.
  """
  @spec minimize(AST.t()) :: {AST.t(), map()}
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
      {{:const, false}, %{
        qmc_steps: [],
        prime_implicants: [],
        minterms: [],
        variables: vars,
        coverage_map: %{},
        minimal_covers: [],
        selected_cover: MapSet.new()
      }}
    else
      # Use QMC with step tracking as we always want details now
      {prime_implicants, qmc_steps} = QMC.prime_implicants(minterms, length(vars))
      coverage_map = QMC.coverage_table(prime_implicants, minterms, length(vars))

      minimal_covers = Petrick.minimal_cover(coverage_map)

      # Select the minimal cover with the lowest complexity
      best_cover =
        case minimal_covers do
          [] ->
            raise "No minimal covers found"

          covers ->
            Enum.min_by(covers, fn cover ->
              cover_list = MapSet.to_list(cover)
              Enum.reduce(cover_list, 0, fn pi, acc ->
                acc + Enum.count(pi, &(&1 != :dont_care))
              end)
            end)
        end

      # Convert best_cover to list for AST generation
      best_cover_list = MapSet.to_list(best_cover)

      final_ast =
        best_cover_list
        # Convert implicants back to AST
        |> Enum.map(&implicant_to_ast(&1, vars))
        # Sort by variables to ensure deterministic order
        |> Enum.sort_by(&AST.variables/1)
        # Combine implicants with OR (left-associative)
        |> Enum.reduce(fn element, acc -> AST.or_node(acc, element) end)

      {final_ast, %{
        qmc_steps: qmc_steps,
        prime_implicants: prime_implicants,
        minterms: minterms,
        variables: vars,
        coverage_map: coverage_map,
        minimal_covers: minimal_covers,
        selected_cover: best_cover
      }}
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

  # Recursive application of rules
  defp apply_rules({op, left, right}) when op in [:and, :or, :xor] do
    {op, apply_rules(left), apply_rules(right)}
  end
  defp apply_rules({:not, expr}), do: {:not, apply_rules(expr)}
  defp apply_rules(expr), do: expr
end
