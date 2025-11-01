defmodule BooleanAlgebraASTTest do
  use ExUnit.Case
  doctest BooleanAlgebra

  alias BooleanAlgebra.AST

  test "simple evaluation of var_nodeiables" do
    assert AST.eval(AST.var_node(:a), %{a: false}) == false
    assert AST.eval(AST.var_node(:a), %{a: true}) == true
    assert AST.eval(AST.var_node(:b), %{b: true}) == true
  end

  test "eval or" do
    assert AST.eval(AST.or_node(AST.var_node(:a), AST.var_node(:b)), %{
             a: false,
             b: false
           }) == false

    assert AST.eval(AST.or_node(AST.var_node(:a), AST.var_node(:b)), %{
             a: true,
             b: false
           }) == true

    assert AST.eval(AST.or_node(AST.var_node(:a), AST.var_node(:b)), %{
             a: false,
             b: true
           }) == true

    assert AST.eval(AST.or_node(AST.var_node(:a), AST.var_node(:b)), %{
             a: true,
             b: true
           }) == true
  end

  test "eval and" do
    assert AST.eval(AST.and_node(AST.var_node(:a), AST.var_node(:b)), %{
             a: false,
             b: false
           }) == false

    assert AST.eval(AST.and_node(AST.var_node(:a), AST.var_node(:b)), %{
             a: true,
             b: false
           }) == false

    assert AST.eval(AST.and_node(AST.var_node(:a), AST.var_node(:b)), %{
             a: false,
             b: true
           }) == false

    assert AST.eval(AST.and_node(AST.var_node(:a), AST.var_node(:b)), %{
             a: true,
             b: true
           }) == true
  end

  test "eval not" do
    assert AST.eval(AST.not_node(AST.var_node(:a)), %{a: false}) == true
    assert AST.eval(AST.not_node(AST.var_node(:a)), %{a: true}) == false
  end

  test "eval xor" do
    assert AST.eval(AST.xor_node(AST.var_node(:a), AST.var_node(:b)), %{
             a: false,
             b: false
           }) == false

    assert AST.eval(AST.xor_node(AST.var_node(:a), AST.var_node(:b)), %{
             a: true,
             b: false
           }) == true

    assert AST.eval(AST.xor_node(AST.var_node(:a), AST.var_node(:b)), %{
             a: false,
             b: true
           }) == true

    assert AST.eval(AST.xor_node(AST.var_node(:a), AST.var_node(:b)), %{
             a: true,
             b: true
           }) == false
  end

  test "eval constant nodes" do
    assert AST.eval(AST.const_node(true)) == true
    assert AST.eval(AST.const_node(false)) == false
  end

  test "complex nested expressions" do
    expr =
      AST.and_node(
        AST.or_node(AST.var_node(:a), AST.var_node(:b)),
        AST.not_node(AST.var_node(:c))
      )

    assert AST.eval(expr, %{a: true, b: false, c: false}) == true
    assert AST.eval(expr, %{a: false, b: true, c: false}) == true
    assert AST.eval(expr, %{a: true, b: true, c: true}) == false
  end

  test "missing var_node variable in context raises error" do
    assert_raise ArgumentError, fn ->
      AST.eval(AST.var_node(:missing))
    end
  end
end
