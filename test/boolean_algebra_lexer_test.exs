ExUnit.start()

defmodule BooleanAlgebraLexerTest do
  use ExUnit.Case

  alias BooleanAlgebra.Lexer

  test "parentheses and simple variable" do
    assert Lexer.tokenize("(a)") == [:lparen, {:var, :a}, :rparen]
    assert Lexer.tokenize("(A)") == [:lparen, {:var, :A}, :rparen]
  end

  test "not variants: !, ~ and NOT keyword" do
    assert Lexer.tokenize("!a") == [:not, {:var, :a}]
    assert Lexer.tokenize("~a") == [:not, {:var, :a}]
    assert Lexer.tokenize("not a") == [:not, {:var, :a}]
  end

  test "and variants: &, &&, *, AND keyword" do
    assert Lexer.tokenize("a&b") == [{:var, :a}, :and, {:var, :b}]
    assert Lexer.tokenize("a*b") == [{:var, :a}, :and, {:var, :b}]
    assert Lexer.tokenize("a and b") == [{:var, :a}, :and, {:var, :b}]
  end

  test "or variants: |, ||, +, OR keyword" do
    assert Lexer.tokenize("a|b") == [{:var, :a}, :or, {:var, :b}]
    assert Lexer.tokenize("a+b") == [{:var, :a}, :or, {:var, :b}]
    assert Lexer.tokenize("a or b") == [{:var, :a}, :or, {:var, :b}]
  end

  test "xor variants: ^ and XOR keyword" do
    assert Lexer.tokenize("a^b") == [{:var, :a}, :xor, {:var, :b}]
    assert Lexer.tokenize("a XOR b") == [{:var, :a}, :xor, {:var, :b}]
  end

  test "constants: numeric and boolean (lower/upper case)" do
    assert Lexer.tokenize("1") == [{:const, true}]
    assert Lexer.tokenize("0") == [{:const, false}]
    assert Lexer.tokenize("true") == [{:const, true}]
    assert Lexer.tokenize("FALSE") == [{:const, false}]
  end

  test "multi-character variable names" do
    assert Lexer.tokenize("ab12") == [{:var, :ab12}]
    assert Lexer.tokenize("var123|x") == [{:var, :var123}, :or, {:var, :x}]
  end

  test "mixed expression" do
    input = "!(a&b)|c"

    expected = [
      :not,
      :lparen,
      {:var, :a},
      :and,
      {:var, :b},
      :rparen,
      :or,
      {:var, :c}
    ]

    assert Lexer.tokenize(input) == expected
  end
end
