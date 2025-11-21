defmodule BooleanAlgebraSimplifierTest do
  use ExUnit.Case
  doctest BooleanAlgebra

  alias BooleanAlgebra.{Simplifier, TruthTable}

  # Helper to parse string expressions into AST
  defp parse(expr) do
    {:ok, ast} = BooleanAlgebra.parse(expr)
    ast
  end

  # Helper to simplify string expressions directly
  defp simplify(expr) do
    expr
    |> parse()
    |> Simplifier.simplify()
    |> elem(0)
  end

  describe "basic expression simplification" do
    test "simplifies OR expressions" do
      assert simplify("a | (b | a)") == parse("a | b")
      assert simplify("a | b") == parse("a | b")
      assert simplify("a | 0") == parse("a")
      assert simplify("a | 1") == parse("1")
      assert simplify("0 | 0") == parse("0")
      assert simplify("1 | 0") == parse("1")
    end

    test "simplifies AND expressions" do
      assert simplify("a & b") == parse("a & b")
      assert simplify("a & 0") == parse("0")
      assert simplify("a & 1") == parse("a")
      assert simplify("1 & 1") == parse("1")
      assert simplify("0 & 1") == parse("0")
    end

    test "simplifies NOT expressions" do
      assert simplify("!1") == parse("0")
      assert simplify("!0") == parse("1")
      assert simplify("!a") == parse("!a")
    end

    test "simplifies XOR expressions" do
      assert simplify("a ^ b") == parse("a ^ b")
      assert simplify("a ^ 0") == parse("a")
      assert simplify("a ^ 1") == parse("!a")
      assert simplify("0 ^ 0") == parse("0")
      assert simplify("1 ^ 1") == parse("0")
      assert simplify("a ^ a") == parse("0")
    end
  end

  test "simplifies expressions with double negation" do
    assert simplify("!!a") == parse("a")
  end

  test "simplifies complex expressions with multiple operations" do
    assert simplify("(a | 0) & !0") == parse("a")
  end

  describe "identity and absorption laws" do
    test "applies OR identity law" do
      assert simplify("a | a") == parse("a")
    end

    test "applies AND identity law" do
      assert simplify("a & a") == parse("a")
    end
  end

  describe "de morgan's laws" do
    test "!(a & b) = !a | !b" do
      assert simplify("!(a & b)") == simplify("!a | !b")
    end

    test "!(a | b) = !a & !b" do
      assert simplify("!(a | b)") == simplify("!a & !b")
    end

    test "de morgan's laws with constants" do
      assert simplify("!(a & 1)") == parse("!a")
      assert simplify("!(a | 0)") == parse("!a")
    end
  end

  describe "absorption rules" do
    test "OR absorption: a | (a & b) = a" do
      assert simplify("a | (a & b)") == parse("a")
    end

    test "AND absorption: a & (a | b) = a" do
      assert simplify("a & (a | b)") == parse("a")
    end

    test "absorption rules with constants" do
      assert simplify("a | (a & 1)") == parse("a")
      assert simplify("a & (a | 0)") == parse("a")
    end
  end

  describe "test contradictions and permutation absorption" do
    test "a & !a = 0 (both orders)" do
      assert simplify("a & !a") == parse("0")
      assert simplify("!a & a") == parse("0")
    end

    test "a | !a = 1 (both orders)" do
      assert simplify("a | !a") == parse("1")
      assert simplify("!a | a") == parse("1")
    end

    test "AND absorption with OR where common term is in different positions" do
      assert simplify("a & (b | a)") == parse("a")
      assert simplify("(b | a) & a") == parse("a")
      assert simplify("(b | a) & b") == parse("b")
    end

    test "OR absorption with AND where common term is in different positions" do
      assert simplify("a | (b & a)") == parse("a")
      assert simplify("(b & a) | a") == parse("a")
      assert simplify("(b & a) | b") == parse("b")
    end
  end

  describe "advanced expression simplification" do
    test "removes duplicates in multiple nested OR expressions" do
      expr = "a | (b | (a | c))"
      expected = "a | b | c"

      simplified = simplify(expr)
      expected_ast = parse(expected)

      assert simplified == expected_ast
      assert TruthTable.from_ast(simplified) == TruthTable.from_ast(expected_ast)
    end

    test "removes duplicates in multiple nested AND expressions" do
      expr = "a & (b & (a & c))"
      expected = "a & (b & c)"

      simplified = simplify(expr)
      # simplify expected too as it might normalize
      expected_ast = simplify(expected)

      assert simplified == expected_ast
      assert TruthTable.from_ast(simplified) == TruthTable.from_ast(expected_ast)
    end

    test "associative flattening and simplification in mixed expressions" do
      expr = "a | ((b & 1) | (a | 0))"
      expected = "a | b"

      simplified = simplify(expr)
      expected_ast = parse(expected)

      assert simplified == expected_ast
      assert TruthTable.from_ast(simplified) == TruthTable.from_ast(expected_ast)
    end

    test "de morgan's law nested with absorption and duplicates" do
      expr = "!((a | 0) & a)"
      # !a | !a -> !a
      expected = "!a"

      simplified = simplify(expr)
      expected_ast = parse(expected)

      assert simplified == expected_ast
      assert TruthTable.from_ast(simplified) == TruthTable.from_ast(expected_ast)
    end

    test "complex nested negations with absorption and identity" do
      expr = "!((a & b) | (a & b))"
      expected = "!a | !b"

      simplified = simplify(expr)
      expected_ast = parse(expected)

      assert simplified == expected_ast
      assert TruthTable.from_ast(simplified) == TruthTable.from_ast(expected_ast)
    end
  end

  describe "absorption and complex expression tests" do
    test "simplifies !a | (b | c) | (b & c)" do
      # (b & c) absorbed by (b | c)
      assert simplify("(!a | (b | c)) | (b & c)") == parse("!a | b | c")
    end

    test "absorption works regardless of operand order" do
      expected = parse("b | c")
      assert simplify("(b & c) | (b | c)") == expected
      assert simplify("(b | c) | (b & c)") == expected
    end

    test "distribution combined with absorption" do
      # a & (a | b) = a
      assert simplify("a & (a | b)") == parse("a")
    end

    test "double negation simplification in complex OR expressions" do
      assert simplify("!!a | (b & 1)") == parse("a | b")
    end
  end

  describe "Standard Boolean Algebra Laws and Theorems" do
    test "Consensus Theorem: AB + !AC + BC = AB + !AC" do
      assert simplify("(a & b) | (!a & c) | (b & c)") == parse("(a & b) | (!a & c)")
    end

    test "Distributive Law (Reverse): (A + B)(A + C) = A + BC" do
      assert simplify("(a | b) & (a | c)") == parse("a | (b & c)")
    end

    test "Redundancy Law: A + !AB = A + B" do
      assert simplify("a | (!a & b)") == parse("a | b")
    end

    test "Redundancy Law (Dual): A(!A + B) = AB" do
      assert simplify("a & (!a | b)") == parse("a & b")
    end

    test "Absorption Law: A(A + B) = A" do
      assert simplify("a & (a | b)") == parse("a")
    end

    test "Simplification of (A + B)(A + !B) = A" do
      assert simplify("(a | b) & (a | !b)") == parse("a")
    end

    test "Dual Consensus Theorem: (A + B)(!A + C)(B + C) = (A + B)(!A + C)" do
      expr = "(a | b) & (!a | c) & (b | c)"
      expected = "(a | b) & (!a | c)"
      assert simplify(expr) == simplify(expected)
    end

    test "Transposition Theorem: AB + !AC = (A + C)(!A + B)" do
      # SOP form preference check
      assert simplify("(a | c) & (!a | b)") == parse("(a & b) | (!a & c)")
    end

    test "Complex Simplification: AB + A(B + C) + B(B + C) = B + AC" do
      expr = "(a & b) | (a & (b | c)) | (b & (b | c))"
      expected = "(a & c) | b"
      assert simplify(expr) == parse(expected)
    end
  end

  describe "5-variable simplification" do
    # https://math.stackexchange.com/questions/412941/boolean-simplification-5-variables
    test "simplifies (xyz+uv)*((x+!y+!z)+uv) to xyz+uv" do
      expr = "((x & y & z) | (u & v)) & ((x | !y | !z) | (u & v))"
      expected = "(u & v) | (x & (y & z))"

      simplified = simplify(expr)
      expected_ast = parse(expected)

      assert TruthTable.from_ast(simplified) == TruthTable.from_ast(expected_ast)
      assert simplified == expected_ast
    end

    # https://stackoverflow.com/questions/47214327/simplifying-5-var-boolean-sop-expression-using-the-laws-and-properties
    test "simplifies A&!B&E + !(B&C)&D&!E + !(C&D)&E+!A&D&!E + A&!(C&D)&E + A&E + A&B&!E + !(A&C) + B&C&!D to !A + B + !C + D + E" do
      expr =
        "A&!B&E | !(B&C)&D&!E | !(C&D)&E|!A&D&!E | A&!(C&D)&E | A&E | A&B&!E | !(A&C) | B&C&!D"

      expected = "!A | B | !C | D | E"

      simplified = simplify(expr)
      expected_ast = parse(expected)

      assert TruthTable.from_ast(simplified) == TruthTable.from_ast(expected_ast)
      assert simplified == expected_ast
    end
  end

  describe "XOR permutations" do
    test "simplifies (!A & B) | (!B & A) -> A ^ B" do
      assert simplify("(!a & b) | (!b & a)") == parse("a ^ b")
    end

    test "simplifies (!A & B) | (A & !B) -> A ^ B" do
      assert simplify("(!a & b) | (a & !b)") == parse("a ^ b")
    end

    test "simplifies (A & !B) | (!A & B) -> A ^ B" do
      assert simplify("(a & !b) | (!a & b)") == parse("a ^ b")
    end

    test "simplifies (A & !B) | (B & !A) -> A ^ B" do
      assert simplify("(a & !b) | (b & !a)") == parse("a ^ b")
    end
  end

  describe "nested OR patterns" do
    test "simplifies (A & B) | ((A & C) | !A)" do
      assert simplify("(a & b) | ((a & c) | !a)") == parse("!a | b | c")
    end

    test "simplifies (A & B) | (!A | (A & C))" do
      assert simplify("(a & b) | (!a | (a & c))") == parse("!a | b | c")
    end
  end

  describe "Systematic Rule Coverage" do
    # 1. Absorption with negation: !A | (A & B) = !A | B
    test "rule 1: !A | (A & B)" do
      assert simplify("!a | (a & b)") == parse("!a | b")
    end

    test "rule 2: !A | (B & A)" do
      assert simplify("!a | (b & a)") == parse("!a | b")
    end

    # 2. (A & B) | !A = !A | B
    test "rule 3: (A & B) | !A" do
      assert simplify("(a & b) | !a") == parse("!a | b")
    end

    test "rule 4: (B & A) | !A" do
      assert simplify("(b & a) | !a") == parse("!a | b")
    end

    # 3. A | (!A & B) = A | B
    test "rule 5: A | (!A & B)" do
      assert simplify("a | (!a & b)") == parse("a | b")
    end

    test "rule 6: A | (B & !A)" do
      assert simplify("a | (b & !a)") == parse("a | b")
    end

    # 4. (!A & B) | A = A | B
    test "rule 7: (!A & B) | A" do
      assert simplify("(!a & b) | a") == parse("a | b")
    end

    test "rule 8: (B & !A) | A" do
      assert simplify("(b & !a) | a") == parse("a | b")
    end

    # 5. Standard Absorption: A | (A & B) = A
    test "rule 9: A | (A & B)" do
      assert simplify("a | (a & b)") == parse("a")
    end

    test "rule 10: A | (B & A)" do
      assert simplify("a | (b & a)") == parse("a")
    end

    # 6. (A & B) | A = A
    test "rule 11: (A & B) | A" do
      assert simplify("(a & b) | a") == parse("a")
    end

    test "rule 12: (B & A) | A" do
      assert simplify("(b & a) | a") == parse("a")
    end

    # 7. A & (A | B) = A
    test "rule 13: A & (A | B)" do
      assert simplify("a & (a | b)") == parse("a")
    end

    test "rule 14: A & (B | A)" do
      assert simplify("a & (b | a)") == parse("a")
    end

    # 8. (A | B) & A = A
    test "rule 15: (A | B) & A" do
      assert simplify("(a | b) & a") == parse("a")
    end

    test "rule 16: (B | A) & A" do
      assert simplify("(b | a) & a") == parse("a")
    end
  end

  describe "details and edge cases" do
    test "minimize returns details" do
      expr = "a & b"
      assert {simplified, details} = Simplifier.minimize(parse(expr))
      assert simplified == parse("a & b")
      assert Map.has_key?(details, :qmc_steps)
      assert Map.has_key?(details, :prime_implicants)
    end

    test "minimize handles false expression" do
      expr = "a & !a"
      assert {simplified, details} = Simplifier.minimize(parse(expr))
      assert simplified == {:const, false}
      assert details.prime_implicants == []
    end

    test "simplify returns details and simplified AST" do
      expr = "a & (a | b)"
      assert {simplified, details} = Simplifier.simplify(parse(expr))
      assert simplified == parse("a")
      assert Map.has_key?(details, :qmc_steps)
    end
  end

  describe "apply_rules coverage" do
    # Pattern: (A & B) | !A = !A | B (commutative)
    test "rule 3 commutative: (B & A) | !A" do
      assert simplify("(b & a) | !a") == parse("!a | b")
    end

    # Pattern: A | (!A & B) = A | B
    test "rule 5: A | (!A & B)" do
      assert simplify("a | (!a & b)") == parse("a | b")
    end

    test "rule 6: A | (B & !A)" do
      assert simplify("a | (b & !a)") == parse("a | b")
    end

    # Pattern: (!A & B) | A = A | B
    test "rule 7: (!A & B) | a" do
      assert simplify("(!a & b) | a") == parse("a | b")
    end

    test "rule 8: (B & !A) | a" do
      assert simplify("(b & !a) | a") == parse("a | b")
    end

    # Pattern: A | (A & B) = A
    test "rule 9: A | (A & B)" do
      assert simplify("a | (a & b)") == parse("a")
    end

    test "rule 10: A | (B & A)" do
      assert simplify("a | (b & a)") == parse("a")
    end

    # Pattern: (A & B) | A = A
    test "rule 11: (A & B) | A" do
      assert simplify("(a & b) | a") == parse("a")
    end

    test "rule 12: (B & A) | A" do
      assert simplify("(b & a) | a") == parse("a")
    end

    # Pattern: A & (A | B) = A
    test "rule 13: A & (A | B)" do
      assert simplify("a & (a | b)") == parse("a")
    end

    test "rule 14: A & (B | A)" do
      assert simplify("a & (b | a)") == parse("a")
    end

    # Pattern: (A | B) & A = A
    test "rule 15: (A | B) & A" do
      assert simplify("(a | b) & a") == parse("a")
    end

    test "rule 16: (B | A) & A" do
      assert simplify("(b | a) & a") == parse("a")
    end

    # XOR patterns
    test "XOR pattern 1: (!A & B) | (!B & A)" do
      assert simplify("(!a & b) | (!b & a)") == parse("a ^ b")
    end

    test "XOR pattern 2: (!A & B) | (A & !B)" do
      assert simplify("(!a & b) | (a & !b)") == parse("a ^ b")
    end

    test "XOR pattern 3: (A & !B) | (!A & B)" do
      assert simplify("(a & !b) | (!a & b)") == parse("a ^ b")
    end

    test "XOR pattern 4: (A & !B) | (B & !A)" do
      assert simplify("(a & !b) | (b & !a)") == parse("a ^ b")
    end
  end

  describe "implicant_to_ast coverage" do
    test "handles all literal types" do
      # Constant true
      assert simplify("1") == parse("1")

      # Single literal
      assert simplify("a") == parse("a")

      # Multiple literals
      assert simplify("a & b") == parse("a & b")
    end
  end
end
