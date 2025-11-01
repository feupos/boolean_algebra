defmodule BooleanAlgebraTest do
  use ExUnit.Case
  doctest BooleanAlgebra

  alias BooleanAlgebra.AST

  test "simple evaluation of var_nodeiables" do
    assert BooleanAlgebra.eval(AST.var_node(:a), %{a: false}) == false
    assert BooleanAlgebra.eval(AST.var_node(:a), %{a: true}) == true
    assert BooleanAlgebra.eval(AST.var_node(:b), %{b: true}) == true
  end

  test "eval or" do
    assert BooleanAlgebra.eval(AST.or_node(AST.var_node(:a), AST.var_node(:b)), %{
             a: false,
             b: false
           }) == false

    assert BooleanAlgebra.eval(AST.or_node(AST.var_node(:a), AST.var_node(:b)), %{
             a: true,
             b: false
           }) == true

    assert BooleanAlgebra.eval(AST.or_node(AST.var_node(:a), AST.var_node(:b)), %{
             a: false,
             b: true
           }) == true

    assert BooleanAlgebra.eval(AST.or_node(AST.var_node(:a), AST.var_node(:b)), %{
             a: true,
             b: true
           }) == true
  end

  test "eval and" do
    assert BooleanAlgebra.eval(AST.and_node(AST.var_node(:a), AST.var_node(:b)), %{
             a: false,
             b: false
           }) == false

    assert BooleanAlgebra.eval(AST.and_node(AST.var_node(:a), AST.var_node(:b)), %{
             a: true,
             b: false
           }) == false

    assert BooleanAlgebra.eval(AST.and_node(AST.var_node(:a), AST.var_node(:b)), %{
             a: false,
             b: true
           }) == false

    assert BooleanAlgebra.eval(AST.and_node(AST.var_node(:a), AST.var_node(:b)), %{
             a: true,
             b: true
           }) == true
  end

  test "eval not" do
    assert BooleanAlgebra.eval(AST.not_node(AST.var_node(:a)), %{a: false}) == true
    assert BooleanAlgebra.eval(AST.not_node(AST.var_node(:a)), %{a: true}) == false
  end

  test "eval xor" do
    assert BooleanAlgebra.eval(AST.xor_node(AST.var_node(:a), AST.var_node(:b)), %{
             a: false,
             b: false
           }) == false

    assert BooleanAlgebra.eval(AST.xor_node(AST.var_node(:a), AST.var_node(:b)), %{
             a: true,
             b: false
           }) == true

    assert BooleanAlgebra.eval(AST.xor_node(AST.var_node(:a), AST.var_node(:b)), %{
             a: false,
             b: true
           }) == true

    assert BooleanAlgebra.eval(AST.xor_node(AST.var_node(:a), AST.var_node(:b)), %{
             a: true,
             b: true
           }) == false
  end

  test "eval constant nodes" do
    assert BooleanAlgebra.eval(AST.const_node(true), %{}) == true
    assert BooleanAlgebra.eval(AST.const_node(false), %{}) == false
  end

  test "complex nested expressions" do
    expr =
      AST.and_node(
        AST.or_node(AST.var_node(:a), AST.var_node(:b)),
        AST.not_node(AST.var_node(:c))
      )

    assert BooleanAlgebra.eval(expr, %{a: true, b: false, c: false}) == true
    assert BooleanAlgebra.eval(expr, %{a: false, b: true, c: false}) == true
    assert BooleanAlgebra.eval(expr, %{a: true, b: true, c: true}) == false
  end

  test "missing var_nodeiable in context raises error" do
    assert_raise ArgumentError, fn ->
      BooleanAlgebra.eval(AST.var_node(:missing), %{a: true})
    end
  end
end
