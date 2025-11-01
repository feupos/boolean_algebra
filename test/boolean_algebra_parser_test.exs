defmodule BooleanAlgebraParserTest do
  use ExUnit.Case
  doctest BooleanAlgebra

  alias BooleanAlgebra.AST

  describe "test parsing of tokens into expressions" do
    test "parses simple constants" do
      assert {:ok, AST.const_node(true)} == BooleanAlgebra.parse_expr([{:const, true}])
      assert {:ok, AST.const_node(false)} == BooleanAlgebra.parse_expr([{:const, false}])
    end

    test "parses simple variables" do
      assert {:ok, AST.var_node("x")} == BooleanAlgebra.parse_expr([{:var, "x"}])
    end

    test "parses NOT expressions" do
      assert {:ok, AST.not_node(AST.var_node("x"))} == BooleanAlgebra.parse_expr([:not, {:var, "x"}])
    end

    test "parses AND expressions" do
      assert {:ok, AST.and_node(AST.var_node("x"), AST.var_node("y"))} ==
        BooleanAlgebra.parse_expr([{:var, "x"}, :and, {:var, "y"}])
    end

    test "parses OR expressions" do
      assert {:ok, AST.or_node(AST.var_node("x"), AST.var_node("y"))} ==
        BooleanAlgebra.parse_expr([{:var, "x"}, :or, {:var, "y"}])
    end

    test "parses XOR expressions" do
      assert {:ok, AST.xor_node(AST.var_node("x"), AST.var_node("y"))} ==
        BooleanAlgebra.parse_expr([{:var, "x"}, :xor, {:var, "y"}])
    end

    test "handles parentheses" do
      assert {:ok, AST.and_node(AST.var_node("x"), AST.var_node("y"))} ==
        BooleanAlgebra.parse_expr([:lparen, {:var, "x"}, :and, {:var, "y"}, :rparen])

      assert {:ok, AST.or_node(AST.and_node(AST.var_node("x"), AST.var_node("y")), AST.var_node("z"))} ==
        BooleanAlgebra.parse_expr([:lparen, {:var, "x"}, :and, {:var, "y"}, :rparen, :or , {:var, "z"}])
      assert {:ok, AST.and_node(AST.var_node("x"), AST.or_node(AST.var_node("y"), AST.var_node("z")))} ==
        BooleanAlgebra.parse_expr([{:var, "x"}, :and, :lparen, {:var, "y"}, :or , {:var, "z"}, :rparen])

      assert {:ok, AST.and_node(AST.or_node(AST.var_node("x"), AST.var_node("y")), AST.var_node("z"))} ==
        BooleanAlgebra.parse_expr([:lparen, {:var, "x"}, :or, {:var, "y"}, :rparen, :and , {:var, "z"}])
      assert {:ok, AST.or_node(AST.var_node("x"), AST.and_node(AST.var_node("y"), AST.var_node("z")))} ==
        BooleanAlgebra.parse_expr([{:var, "x"}, :or, :lparen, {:var, "y"}, :and , {:var, "z"}, :rparen])

    end

    test "handles precedence in expressions" do
      assert {:ok, AST.or_node(AST.and_node(AST.var_node("x"), AST.var_node("y")), AST.var_node("z"))} ==
        BooleanAlgebra.parse_expr([{:var, "x"}, :and, {:var, "y"}, :or, {:var, "z"}])
    end

    test "returns error for invalid expressions" do
      assert {:error, "Missing closing parenthesis"} = BooleanAlgebra.parse_expr([:lparen, {:var, "x"}])
      assert {:error, "Unexpected end of expression"} = BooleanAlgebra.parse_expr([{:var, "x"}, :and])
      assert {:error, "Unexpected tokens at end"} = BooleanAlgebra.parse_expr([{:var, "x"}, :invalid_token])
    end
  end
end
