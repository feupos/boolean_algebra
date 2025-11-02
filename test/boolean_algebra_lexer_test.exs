ExUnit.start()

defmodule BooleanAlgebraLexerTest do
  use ExUnit.Case

  alias BooleanAlgebra.Lexer

  defp lex(s), do: Lexer.parse_text(s)

  test "parentheses and simple variable" do
    assert lex("(a)") == [:lparen, {:var, :a}, :rparen]
  end

  test "not variants: !, ~ and NOT keyword" do
    assert lex("!a") == [:not, {:var, :a}]
    assert lex("~a") == [:not, {:var, :a}]
    # Keyword NOT must be followed by a non-alphanumeric to be recognized
    assert lex("NOT(a)") == [:not, :lparen, {:var, :a}, :rparen]
  end

  test "and variants: &, &&, *, AND keyword" do
    assert lex("a&b") == [{:var, :a}, :and, {:var, :b}]
    assert lex("a&&b") == [{:var, :a}, :and, {:var, :b}]
    assert lex("a*b") == [{:var, :a}, :and, {:var, :b}]
    assert lex("AND(a)") == [:and, :lparen, {:var, :a}, :rparen]
  end

  test "or variants: |, ||, +, OR keyword" do
    assert lex("a|b") == [{:var, :a}, :or, {:var, :b}]
    assert lex("a||b") == [{:var, :a}, :or, {:var, :b}]
    assert lex("a+b") == [{:var, :a}, :or, {:var, :b}]
    assert lex("OR(a)") == [:or, :lparen, {:var, :a}, :rparen]
  end

  test "xor variants: ^ and XOR keyword" do
    assert lex("a^b") == [{:var, :a}, :xor, {:var, :b}]
    assert lex("XOR(a)") == [:xor, :lparen, {:var, :a}, :rparen]
  end

  test "constants: numeric and boolean (lower/upper case)" do
    assert lex("1") == [{:const, true}]
    assert lex("0") == [{:const, false}]
    assert lex("true|FALSE") == [{:const, true}, :or, {:const, false}]
    assert lex("TRUE(a)") == [{:const, true}, :lparen, {:var, :a}, :rparen]
    assert lex("false(a)") == [{:const, false}, :lparen, {:var, :a}, :rparen]
  end

  test "multi-character variable names" do
    assert lex("ab12") == [{:var, :ab12}]
    assert lex("var123|x") == [{:var, :var123}, :or, {:var, :x}]
  end

  test "unknown characters are skipped" do
    # '$' is not recognized and should be skipped
    assert lex("a$b") == [{:var, :a}, {:var, :b}]
  end

  test "complex mixed expression" do
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

    assert lex(input) == expected
  end
end
