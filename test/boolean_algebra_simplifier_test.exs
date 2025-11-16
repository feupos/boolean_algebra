defmodule BooleanAlgebraSimplifierTest do
  use ExUnit.Case
  doctest BooleanAlgebra

  # , QMC, Petrick}
  alias BooleanAlgebra.{AST, Simplifier, TruthTable}

  describe "basic expression simplification" do
    test "simplifies OR expressions" do
      assert Simplifier.simplify(
               AST.or_node(AST.var_node(:a), AST.or_node(AST.var_node(:b), AST.var_node(:a)))
             ) ==
               AST.or_node(AST.var_node(:a), AST.var_node(:b))

      assert Simplifier.simplify(AST.or_node(AST.var_node(:a), AST.var_node(:b))) ==
               AST.or_node(AST.var_node(:a), AST.var_node(:b))

      assert Simplifier.simplify(AST.or_node(AST.var_node(:a), AST.const_node(false))) ==
               AST.var_node(:a)

      assert Simplifier.simplify(AST.or_node(AST.var_node(:a), AST.const_node(true))) ==
               AST.const_node(true)

      assert Simplifier.simplify(AST.or_node(AST.const_node(false), AST.const_node(false))) ==
               AST.const_node(false)

      assert Simplifier.simplify(AST.or_node(AST.const_node(true), AST.const_node(false))) ==
               AST.const_node(true)
    end

    test "simplifies AND expressions" do
      assert Simplifier.simplify(AST.and_node(AST.var_node(:a), AST.var_node(:b))) ==
               AST.and_node(AST.var_node(:a), AST.var_node(:b))

      assert Simplifier.simplify(AST.and_node(AST.var_node(:a), AST.const_node(false))) ==
               AST.const_node(false)

      assert Simplifier.simplify(AST.and_node(AST.var_node(:a), AST.const_node(true))) ==
               AST.var_node(:a)

      assert Simplifier.simplify(AST.and_node(AST.const_node(true), AST.const_node(true))) ==
               AST.const_node(true)

      assert Simplifier.simplify(AST.and_node(AST.const_node(false), AST.const_node(true))) ==
               AST.const_node(false)
    end

    test "simplifies NOT expressions" do
      assert Simplifier.simplify(AST.not_node(AST.const_node(true))) == AST.const_node(false)
      assert Simplifier.simplify(AST.not_node(AST.const_node(false))) == AST.const_node(true)

      assert Simplifier.simplify(AST.not_node(AST.var_node(:a))) ==
               AST.not_node(AST.var_node(:a))
    end

    test "simplifies XOR expressions" do
      assert Simplifier.simplify(AST.xor_node(AST.var_node(:a), AST.var_node(:b))) ==
               AST.xor_node(AST.var_node(:a), AST.var_node(:b))

      assert Simplifier.simplify(AST.xor_node(AST.var_node(:a), AST.const_node(false))) ==
               AST.var_node(:a)

      assert Simplifier.simplify(AST.xor_node(AST.var_node(:a), AST.const_node(true))) ==
               AST.not_node(AST.var_node(:a))

      assert Simplifier.simplify(AST.xor_node(AST.const_node(false), AST.const_node(false))) ==
               AST.const_node(false)

      assert Simplifier.simplify(AST.xor_node(AST.const_node(true), AST.const_node(true))) ==
               AST.const_node(false)

      assert Simplifier.simplify(AST.xor_node(AST.var_node(:a), AST.var_node(:a))) ==
               AST.const_node(false)
    end
  end

  describe "complex expression simplification" do
    test "simplifies nested expressions" do
      complex_expr =
        AST.or_node(
          AST.and_node(AST.var_node(:a), AST.const_node(true)),
          AST.const_node(false)
        )

      assert Simplifier.simplify(complex_expr) == AST.var_node(:a)
    end

    test "simplifies expressions with double negation" do
      double_not = AST.not_node(AST.not_node(AST.var_node(:a)))
      assert Simplifier.simplify(double_not) == AST.var_node(:a)
    end

    test "simplifies complex expressions with multiple operations" do
      complex_expr =
        AST.and_node(
          AST.or_node(AST.var_node(:a), AST.const_node(false)),
          AST.not_node(AST.const_node(false))
        )

      assert Simplifier.simplify(complex_expr) == AST.var_node(:a)
    end
  end

  describe "identity and absorption laws" do
    test "applies OR identity law" do
      expr = AST.or_node(AST.var_node(:a), AST.var_node(:a))
      assert Simplifier.simplify(expr) == AST.var_node(:a)
    end

    test "applies AND identity law" do
      expr = AST.and_node(AST.var_node(:a), AST.var_node(:a))
      assert Simplifier.simplify(expr) == AST.var_node(:a)
    end
  end

  describe "de morgan's laws" do
    test "NOT (a AND b) = NOT a OR NOT b" do
      expr = AST.not_node(AST.and_node(AST.var_node(:a), AST.var_node(:b)))
      expected = AST.or_node(AST.not_node(AST.var_node(:a)), AST.not_node(AST.var_node(:b)))
      assert Simplifier.simplify(expr) == Simplifier.simplify(expected)
    end

    test "NOT (a OR b) = NOT a AND NOT b" do
      expr = AST.not_node(AST.or_node(AST.var_node(:a), AST.var_node(:b)))
      expected = AST.and_node(AST.not_node(AST.var_node(:a)), AST.not_node(AST.var_node(:b)))
      assert Simplifier.simplify(expr) == Simplifier.simplify(expected)
    end

    test "de morgan's laws with constants" do
      expr1 = AST.not_node(AST.and_node(AST.var_node(:a), AST.const_node(true)))
      expr2 = AST.not_node(AST.or_node(AST.var_node(:a), AST.const_node(false)))

      assert Simplifier.simplify(expr1) == AST.not_node(AST.var_node(:a))
      assert Simplifier.simplify(expr2) == AST.not_node(AST.var_node(:a))
    end
  end

  describe "absorption rules" do
    test "OR absorption: a OR (a AND b) = a" do
      expr =
        AST.or_node(
          AST.var_node(:a),
          AST.and_node(AST.var_node(:a), AST.var_node(:b))
        )

      assert Simplifier.simplify(expr) == AST.var_node(:a)
    end

    test "AND absorption: a AND (a OR b) = a" do
      expr =
        AST.and_node(
          AST.var_node(:a),
          AST.or_node(AST.var_node(:a), AST.var_node(:b))
        )

      assert Simplifier.simplify(expr) == AST.var_node(:a)
    end

    test "absorption rules with constants" do
      expr1 =
        AST.or_node(
          AST.var_node(:a),
          AST.and_node(AST.var_node(:a), AST.const_node(true))
        )

      expr2 =
        AST.and_node(
          AST.var_node(:a),
          AST.or_node(AST.var_node(:a), AST.const_node(false))
        )

      assert Simplifier.simplify(expr1) == AST.var_node(:a)
      assert Simplifier.simplify(expr2) == AST.var_node(:a)
    end
  end

  describe "test contradictions and permutation absorption" do
    test "a AND NOT a = 0 (both orders)" do
      assert Simplifier.simplify(AST.and_node(AST.var_node(:a), AST.not_node(AST.var_node(:a)))) ==
               AST.const_node(false)

      assert Simplifier.simplify(AST.and_node(AST.not_node(AST.var_node(:a)), AST.var_node(:a))) ==
               AST.const_node(false)
    end

    test "a OR NOT a = 1 (both orders)" do
      assert Simplifier.simplify(AST.or_node(AST.var_node(:a), AST.not_node(AST.var_node(:a)))) ==
               AST.const_node(true)

      assert Simplifier.simplify(AST.or_node(AST.not_node(AST.var_node(:a)), AST.var_node(:a))) ==
               AST.const_node(true)
    end

    test "AND absorption with OR where common term is in different positions" do
      expr1 =
        AST.and_node(
          AST.var_node(:a),
          AST.or_node(AST.var_node(:b), AST.var_node(:a))
        )

      expr2 =
        AST.and_node(
          AST.or_node(AST.var_node(:b), AST.var_node(:a)),
          AST.var_node(:a)
        )

      expr3 =
        AST.and_node(
          AST.or_node(AST.var_node(:b), AST.var_node(:a)),
          AST.var_node(:b)
        )

      assert Simplifier.simplify(expr1) == AST.var_node(:a)
      assert Simplifier.simplify(expr2) == AST.var_node(:a)
      assert Simplifier.simplify(expr3) == AST.var_node(:b)
    end

    test "OR absorption with AND where common term is in different positions" do
      expr1 =
        AST.or_node(
          AST.var_node(:a),
          AST.and_node(AST.var_node(:b), AST.var_node(:a))
        )

      expr2 =
        AST.or_node(
          AST.and_node(AST.var_node(:b), AST.var_node(:a)),
          AST.var_node(:a)
        )

      expr3 =
        AST.or_node(
          AST.and_node(AST.var_node(:b), AST.var_node(:a)),
          AST.var_node(:b)
        )

      assert Simplifier.simplify(expr1) == AST.var_node(:a)
      assert Simplifier.simplify(expr2) == AST.var_node(:a)
      assert Simplifier.simplify(expr3) == AST.var_node(:b)
    end
  end

  describe "advanced expression simplification" do
    test "removes duplicates in multiple nested OR expressions" do
      expr =
        AST.or_node(
          AST.var_node(:a),
          AST.or_node(
            AST.var_node(:b),
            AST.or_node(AST.var_node(:a), AST.var_node(:c))
          )
        )

      expected =
        AST.or_node(
          AST.var_node(:a),
          AST.or_node(AST.var_node(:b), AST.var_node(:c))
        )

      assert Simplifier.simplify(expr) == expected
      assert TruthTable.from_ast(expr) == TruthTable.from_ast(expected)
    end

    test "removes duplicates in multiple nested AND expressions" do
      expr =
        AST.and_node(
          AST.var_node(:a),
          AST.and_node(
            AST.var_node(:b),
            AST.and_node(AST.var_node(:a), AST.var_node(:c))
          )
        )

      expected =
        AST.and_node(
          AST.var_node(:a),
          AST.and_node(AST.var_node(:b), AST.var_node(:c))
        )

      assert Simplifier.simplify(expr) == Simplifier.simplify(expected)
      assert TruthTable.from_ast(expr) == TruthTable.from_ast(expected)
    end

    test "associative flattening and simplification in mixed expressions" do
      expr =
        AST.or_node(
          AST.var_node(:a),
          AST.or_node(
            AST.and_node(AST.var_node(:b), AST.const_node(true)),
            AST.or_node(AST.var_node(:a), AST.const_node(false))
          )
        )

      expected =
        AST.or_node(
          AST.var_node(:a),
          AST.var_node(:b)
        )

      assert Simplifier.simplify(expr) == expected
      assert TruthTable.from_ast(expr) == TruthTable.from_ast(expected)
    end

    test "de morgan's law nested with absorption and duplicates" do
      expr =
        AST.not_node(
          AST.and_node(
            AST.or_node(AST.var_node(:a), AST.const_node(false)),
            AST.var_node(:a)
          )
        )

      expected =
        AST.or_node(
          AST.not_node(AST.var_node(:a)),
          AST.not_node(AST.var_node(:a))
        )
        |> Simplifier.simplify()

      assert Simplifier.simplify(expr) == expected
      assert TruthTable.from_ast(expr) == TruthTable.from_ast(expected)
    end

    test "complex nested negations with absorption and identity" do
      expr =
        AST.not_node(
          AST.or_node(
            AST.and_node(AST.var_node(:a), AST.var_node(:b)),
            AST.and_node(AST.var_node(:a), AST.var_node(:b))
          )
        )

      expected =
        AST.or_node(AST.not_node(AST.var_node(:a)), AST.not_node(AST.var_node(:b)))

      assert Simplifier.simplify(expr) == expected
      assert TruthTable.from_ast(expr) == TruthTable.from_ast(expected)
    end
  end

  describe "absorption and complex expression tests" do
    test "simplifies NOT A OR (B OR C) OR (B AND C)" do
      expr =
        AST.or_node(
          AST.or_node(
            AST.not_node(AST.var_node(:a)),
            AST.or_node(AST.var_node(:b), AST.var_node(:c))
          ),
          AST.and_node(AST.var_node(:b), AST.var_node(:c))
        )

      # Expected simplification is:
      # NOT A OR B OR C (since (B AND C) absorbed by (B OR C))
      expected =
        AST.or_node(
          AST.not_node(AST.var_node(:a)),
          AST.or_node(AST.var_node(:b), AST.var_node(:c))
        )

      assert Simplifier.simplify(expr) == expected
    end

    test "absorption works regardless of operand order" do
      expr1 =
        AST.or_node(
          AST.and_node(AST.var_node(:b), AST.var_node(:c)),
          AST.or_node(AST.var_node(:b), AST.var_node(:c))
        )

      expr2 =
        AST.or_node(
          AST.or_node(AST.var_node(:b), AST.var_node(:c)),
          AST.and_node(AST.var_node(:b), AST.var_node(:c))
        )

      expected =
        AST.or_node(AST.var_node(:b), AST.var_node(:c))

      assert Simplifier.simplify(expr1) == expected
      assert Simplifier.simplify(expr2) == expected
    end

    test "distribution combined with absorption" do
      expr =
        AST.and_node(
          AST.var_node(:a),
          AST.or_node(AST.var_node(:a), AST.var_node(:b))
        )

      # By absorption: a AND (a OR b) = a
      expected = AST.var_node(:a)

      assert Simplifier.simplify(expr) == expected
    end

    test "double negation simplification in complex OR expressions" do
      expr =
        AST.or_node(
          AST.not_node(AST.not_node(AST.var_node(:a))),
          AST.and_node(AST.var_node(:b), AST.const_node(true))
        )

      expected =
        AST.or_node(
          AST.var_node(:a),
          AST.var_node(:b)
        )

      assert Simplifier.simplify(expr) == expected
    end
  end

  describe "5-variable simplification" do
    # Example from https://math.stackexchange.com/questions/412941/boolean-simplification-5-variables
    @tag :slow
    test "simplifies (xyz+uv)*((x+!y+!z)+uv) to xyz+uv" do
      x = AST.var_node(:x)
      y = AST.var_node(:y)
      z = AST.var_node(:z)
      u = AST.var_node(:u)
      v = AST.var_node(:v)
      xyz = AST.and_node(x, AST.and_node(y, z))
      uv = AST.and_node(u, v)
      left_term = AST.or_node(xyz, uv)
      not_y = AST.not_node(y)
      not_z = AST.not_node(z)
      x_or_not_y_or_not_z = AST.or_node(x, AST.or_node(not_y, not_z))
      right_term = AST.or_node(x_or_not_y_or_not_z, uv)
      expr = AST.and_node(left_term, right_term)

      # Debug: Check the truth table
      # truth_table = TruthTable.from_ast(expr)
      # vars = AST.variables(expr)
      # IO.puts("Variables: #{inspect(vars)}")
      # IO.puts("Number of variables: #{length(vars)}")

      # minterms =
      #   truth_table
      #     |> Enum.with_index()
      #     |> Enum.filter(fn {row, _idx} -> Map.get(row, :result) end)
      #     |> Enum.map(fn {_row, idx} -> idx end)

      # IO.puts("Minterms: #{inspect(minterms)}")
      # IO.puts("Number of minterms: #{length(minterms)}")

      # # Run QMC
      # prime_implicants = QMC.minimize(minterms, length(vars))
      # IO.puts("Prime implicants: #{inspect(prime_implicants)}")

      # # Build coverage table
      # coverage_map = QMC.coverage_table(prime_implicants, minterms, length(vars))
      # IO.puts("Coverage map: #{inspect(coverage_map)}")

      # # Try Petrick
      # minimal_covers = Petrick.minimal_cover(coverage_map)
      # IO.puts("Minimal covers: #{inspect(minimal_covers)}")

      # Now try the actual simplification
      expected = AST.or_node(uv, xyz)
      assert TruthTable.from_ast(expr) == TruthTable.from_ast(expected)
      assert Simplifier.simplify(expr) == expected
    end
  end
end
