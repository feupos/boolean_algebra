ExUnit.start()

defmodule BooleanAlgebraLexerTest do
  use ExUnit.Case

  alias BooleanAlgebra.Lexer

  test "parentheses and simple variable" do
    assert Lexer.parse_text("(a)") == [:lparen, {:var, :a}, :rparen]
    assert Lexer.parse_text("(A)") == [:lparen, {:var, :A}, :rparen]
  end

  test "not variants: !, ~ and NOT keyword" do
    assert Lexer.parse_text("!a") == [:not, {:var, :a}]
    assert Lexer.parse_text("~a") == [:not, {:var, :a}]
    assert Lexer.parse_text("not a") == [:not, {:var, :a}]
  end

  test "and variants: &, &&, *, AND keyword" do
    assert Lexer.parse_text("a&b") == [{:var, :a}, :and, {:var, :b}]
    assert Lexer.parse_text("a*b") == [{:var, :a}, :and, {:var, :b}]
    assert Lexer.parse_text("a and b") == [{:var, :a}, :and, {:var, :b}]
  end

  test "or variants: |, ||, +, OR keyword" do
    assert Lexer.parse_text("a|b") == [{:var, :a}, :or, {:var, :b}]
    assert Lexer.parse_text("a+b") == [{:var, :a}, :or, {:var, :b}]
    assert Lexer.parse_text("a or b") == [{:var, :a}, :or, {:var, :b}]
  end

  test "xor variants: ^ and XOR keyword" do
    assert Lexer.parse_text("a^b") == [{:var, :a}, :xor, {:var, :b}]
    assert Lexer.parse_text("a XOR b") == [{:var, :a}, :xor, {:var, :b}]
  end

  test "constants: numeric and boolean (lower/upper case)" do
    assert Lexer.parse_text("1") == [{:const, true}]
    assert Lexer.parse_text("0") == [{:const, false}]
    assert Lexer.parse_text("true") == [{:const, true}]
    assert Lexer.parse_text("FALSE") == [{:const, false}]
  end

  test "multi-character variable names" do
    assert Lexer.parse_text("ab12") == [{:var, :ab12}]
    assert Lexer.parse_text("var123|x") == [{:var, :var123}, :or, {:var, :x}]
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

    assert Lexer.parse_text(input) == expected
  end
end
