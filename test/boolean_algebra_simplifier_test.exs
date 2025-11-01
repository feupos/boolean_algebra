defmodule BooleanAlgebraSimplifierTest do
  use ExUnit.Case
  doctest BooleanAlgebra

  alias BooleanAlgebra.AST

  describe "basic expression simplification" do
    test "simplifies OR expressions" do
      assert BooleanAlgebra.simplify(AST.or_node(AST.var_node(:a), AST.const_node(false))) ==
               AST.var_node(:a)

      assert BooleanAlgebra.simplify(AST.or_node(AST.var_node(:a), AST.const_node(true))) ==
               AST.const_node(true)

      assert BooleanAlgebra.simplify(AST.or_node(AST.const_node(false), AST.const_node(false))) ==
               AST.const_node(false)

      assert BooleanAlgebra.simplify(AST.or_node(AST.const_node(true), AST.const_node(false))) ==
               AST.const_node(true)
    end

    test "simplifies AND expressions" do
      assert BooleanAlgebra.simplify(AST.and_node(AST.var_node(:a), AST.const_node(false))) ==
               AST.const_node(false)

      assert BooleanAlgebra.simplify(AST.and_node(AST.var_node(:a), AST.const_node(true))) ==
               AST.var_node(:a)

      assert BooleanAlgebra.simplify(AST.and_node(AST.const_node(true), AST.const_node(true))) ==
               AST.const_node(true)

      assert BooleanAlgebra.simplify(AST.and_node(AST.const_node(false), AST.const_node(true))) ==
               AST.const_node(false)
    end

    test "simplifies NOT expressions" do
      assert BooleanAlgebra.simplify(AST.not_node(AST.const_node(true))) == AST.const_node(false)
      assert BooleanAlgebra.simplify(AST.not_node(AST.const_node(false))) == AST.const_node(true)

      assert BooleanAlgebra.simplify(AST.not_node(AST.var_node(:a))) ==
               AST.not_node(AST.var_node(:a))
    end

    test "simplifies XOR expressions" do
      assert BooleanAlgebra.simplify(AST.xor_node(AST.var_node(:a), AST.const_node(false))) ==
               AST.var_node(:a)

      assert BooleanAlgebra.simplify(AST.xor_node(AST.var_node(:a), AST.const_node(true))) ==
               AST.not_node(AST.var_node(:a))

      assert BooleanAlgebra.simplify(AST.xor_node(AST.const_node(false), AST.const_node(false))) ==
               AST.const_node(false)

      assert BooleanAlgebra.simplify(AST.xor_node(AST.const_node(true), AST.const_node(true))) ==
               AST.const_node(false)

      assert BooleanAlgebra.simplify(AST.xor_node(AST.var_node(:a), AST.var_node(:a))) ==
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

      assert BooleanAlgebra.simplify(complex_expr) == AST.var_node(:a)
    end

    test "simplifies expressions with double negation" do
      double_not = AST.not_node(AST.not_node(AST.var_node(:a)))
      assert BooleanAlgebra.simplify(double_not) == AST.var_node(:a)
    end

    test "simplifies complex expressions with multiple operations" do
      complex_expr =
        AST.and_node(
          AST.or_node(AST.var_node(:a), AST.const_node(false)),
          AST.not_node(AST.const_node(false))
        )

      assert BooleanAlgebra.simplify(complex_expr) == AST.var_node(:a)
    end
  end

  describe "identity and absorption laws" do
    test "applies OR identity law" do
      expr = AST.or_node(AST.var_node(:a), AST.var_node(:a))
      assert BooleanAlgebra.simplify(expr) == AST.var_node(:a)
    end

    test "applies AND identity law" do
      expr = AST.and_node(AST.var_node(:a), AST.var_node(:a))
      assert BooleanAlgebra.simplify(expr) == AST.var_node(:a)
    end
  end

  describe "de morgan's laws" do
    test "NOT (a AND b) = NOT a OR NOT b" do
      expr = AST.not_node(AST.and_node(AST.var_node(:a), AST.var_node(:b)))
      expected = AST.or_node(AST.not_node(AST.var_node(:a)), AST.not_node(AST.var_node(:b)))
      assert BooleanAlgebra.simplify(expr) == BooleanAlgebra.simplify(expected)
    end

    test "NOT (a OR b) = NOT a AND NOT b" do
      expr = AST.not_node(AST.or_node(AST.var_node(:a), AST.var_node(:b)))
      expected = AST.and_node(AST.not_node(AST.var_node(:a)), AST.not_node(AST.var_node(:b)))
      assert BooleanAlgebra.simplify(expr) == BooleanAlgebra.simplify(expected)
    end

    test "de morgan's laws with constants" do
      expr1 = AST.not_node(AST.and_node(AST.var_node(:a), AST.const_node(true)))
      expr2 = AST.not_node(AST.or_node(AST.var_node(:a), AST.const_node(false)))

      assert BooleanAlgebra.simplify(expr1) == AST.not_node(AST.var_node(:a))
      assert BooleanAlgebra.simplify(expr2) == AST.not_node(AST.var_node(:a))
    end
  end

  describe "absorption rules" do
    test "OR absorption: a OR (a AND b) = a" do
      expr =
        AST.or_node(
          AST.var_node(:a),
          AST.and_node(AST.var_node(:a), AST.var_node(:b))
        )

      assert BooleanAlgebra.simplify(expr) == AST.var_node(:a)
    end

    test "AND absorption: a AND (a OR b) = a" do
      expr =
        AST.and_node(
          AST.var_node(:a),
          AST.or_node(AST.var_node(:a), AST.var_node(:b))
        )

      assert BooleanAlgebra.simplify(expr) == AST.var_node(:a)
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

      assert BooleanAlgebra.simplify(expr1) == AST.var_node(:a)
      assert BooleanAlgebra.simplify(expr2) == AST.var_node(:a)
    end
  end

  describe "test contradictions and permutation absorption" do
    test "a AND NOT a = 0 (both orders)" do
      assert BooleanAlgebra.simplify(
               AST.and_node(AST.var_node(:a), AST.not_node(AST.var_node(:a)))
             ) == AST.const_node(false)

      assert BooleanAlgebra.simplify(
               AST.and_node(AST.not_node(AST.var_node(:a)), AST.var_node(:a))
             ) == AST.const_node(false)
    end

    test "a OR NOT a = 1 (both orders)" do
      assert BooleanAlgebra.simplify(
               AST.or_node(AST.var_node(:a), AST.not_node(AST.var_node(:a)))
             ) == AST.const_node(true)

      assert BooleanAlgebra.simplify(
               AST.or_node(AST.not_node(AST.var_node(:a)), AST.var_node(:a))
             ) == AST.const_node(true)
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

      assert BooleanAlgebra.simplify(expr1) == AST.var_node(:a)
      assert BooleanAlgebra.simplify(expr2) == AST.var_node(:a)
      assert BooleanAlgebra.simplify(expr3) == AST.var_node(:b)
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

      assert BooleanAlgebra.simplify(expr1) == AST.var_node(:a)
      assert BooleanAlgebra.simplify(expr2) == AST.var_node(:a)
      assert BooleanAlgebra.simplify(expr3) == AST.var_node(:b)
    end
  end
end
