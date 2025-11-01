defmodule BooleanAlgebraParserTest do
  use ExUnit.Case
  doctest BooleanAlgebra

  alias BooleanAlgebra.AST
  alias BooleanAlgebra.Parser

  describe "test parsing of tokens into expressions" do
    test "parses simple constants" do
      assert {:ok, AST.const_node(true)} == Parser.parse_tokens([{:const, true}])
      assert {:ok, AST.const_node(false)} == Parser.parse_tokens([{:const, false}])
    end

    test "parses simple variables" do
      assert {:ok, AST.var_node("x")} == Parser.parse_tokens([{:var, "x"}])
    end

    test "parses NOT expressions" do
      assert {:ok, AST.not_node(AST.var_node("x"))} ==
               Parser.parse_tokens([:not, {:var, "x"}])
    end

    test "parses AND expressions" do
      assert {:ok, AST.and_node(AST.var_node("x"), AST.var_node("y"))} ==
               Parser.parse_tokens([{:var, "x"}, :and, {:var, "y"}])
    end

    test "parses OR expressions" do
      assert {:ok, AST.or_node(AST.var_node("x"), AST.var_node("y"))} ==
               Parser.parse_tokens([{:var, "x"}, :or, {:var, "y"}])
    end

    test "parses XOR expressions" do
      assert {:ok, AST.xor_node(AST.var_node("x"), AST.var_node("y"))} ==
               Parser.parse_tokens([{:var, "x"}, :xor, {:var, "y"}])
    end

    test "handles parentheses" do
      assert {:ok, AST.and_node(AST.var_node("x"), AST.var_node("y"))} ==
               Parser.parse_tokens([:lparen, {:var, "x"}, :and, {:var, "y"}, :rparen])

      assert {:ok,
              AST.or_node(AST.and_node(AST.var_node("x"), AST.var_node("y")), AST.var_node("z"))} ==
               Parser.parse_tokens([
                 :lparen,
                 {:var, "x"},
                 :and,
                 {:var, "y"},
                 :rparen,
                 :or,
                 {:var, "z"}
               ])

      assert {:ok,
              AST.and_node(AST.var_node("x"), AST.or_node(AST.var_node("y"), AST.var_node("z")))} ==
               Parser.parse_tokens([
                 {:var, "x"},
                 :and,
                 :lparen,
                 {:var, "y"},
                 :or,
                 {:var, "z"},
                 :rparen
               ])

      assert {:ok,
              AST.and_node(AST.or_node(AST.var_node("x"), AST.var_node("y")), AST.var_node("z"))} ==
               Parser.parse_tokens([
                 :lparen,
                 {:var, "x"},
                 :or,
                 {:var, "y"},
                 :rparen,
                 :and,
                 {:var, "z"}
               ])

      assert {:ok,
              AST.or_node(AST.var_node("x"), AST.and_node(AST.var_node("y"), AST.var_node("z")))} ==
               Parser.parse_tokens([
                 {:var, "x"},
                 :or,
                 :lparen,
                 {:var, "y"},
                 :and,
                 {:var, "z"},
                 :rparen
               ])
    end

    test "handles precedence in expressions" do
      assert {:ok,
              AST.or_node(AST.and_node(AST.var_node("x"), AST.var_node("y")), AST.var_node("z"))} ==
               Parser.parse_tokens([{:var, "x"}, :and, {:var, "y"}, :or, {:var, "z"}])
    end

    test "returns error for invalid expressions" do
      assert {:error, "Missing closing parenthesis"} =
               Parser.parse_tokens([:lparen, {:var, "x"}])

      assert {:error, "Unexpected end of expression"} =
               Parser.parse_tokens([{:var, "x"}, :and])

      assert {:error, "Unexpected tokens at end"} =
               Parser.parse_tokens([{:var, "x"}, :invalid_token])
    end
  end
end
