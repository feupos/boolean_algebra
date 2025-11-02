defmodule BooleanAlgebra.FormatterTest do
  use ExUnit.Case
  alias BooleanAlgebra.Formatter

  test "constants and variables" do
    assert Formatter.to_string({:const, true}) == "true"
    assert Formatter.to_string({:const, false}) == "false"
    assert Formatter.to_string({:var, :X}) == "X"
  end

  test "unary not" do
    expr = {:not, {:var, :a}}
    assert Formatter.to_string(expr) == "!a"
    assert Formatter.to_string(expr, operators: :word) == "NOT a"
  end

  test "not binds tighter than binary and uses parentheses" do
    expr = {:not, {:and, {:var, :a}, {:var, :b}}}
    assert Formatter.to_string(expr) == "!(a & b)"
    assert Formatter.to_string(expr, operators: :word) == "NOT (a AND b)"
  end

  test "minimal parentheses according to precedence" do
    expr = {:and, {:or, {:var, :a}, {:var, :b}}, {:var, :c}}
    assert Formatter.to_string(expr) == "(a | b) & c"
    assert Formatter.to_string(expr, operators: :word) == "(a OR b) AND c"
  end

  test "full parentheses option wraps every binary expression" do
    expr = {:and, {:or, {:var, :a}, {:var, :b}}, {:var, :c}}
    assert Formatter.to_string(expr, parentheses: :full) == "((a | b) & c)"
    assert Formatter.to_string(expr, operators: :word, parentheses: :full) == "((a OR b) AND c)"
  end

  test "mixed operators and precedence combination" do
    expr = {:or, {:and, {:var, :a}, {:var, :b}}, {:xor, {:var, :c}, {:const, false}}}
    assert Formatter.to_string(expr) == "a & b | c ^ false"
    assert Formatter.to_string(expr, operators: :word) == "a AND b OR c XOR false"
  end
end
