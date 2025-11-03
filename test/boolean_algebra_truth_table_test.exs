defmodule BooleanAlgebra.TruthTableTest do
  use ExUnit.Case
  alias BooleanAlgebra.TruthTable
  alias BooleanAlgebra.AST

  @doc """
  Test the truth table generation for a simple expression.
  """
  test "truth table for simple expression" do
    ast = AST.or_node(AST.var_node("A"), AST.var_node("B"))

    expected_result = [
      %{"A" => false, "B" => false, result: false},
      %{"A" => false, "B" => true, result: true},
      %{"A" => true, "B" => false, result: true},
      %{"A" => true, "B" => true, result: true}
    ]

    assert TruthTable.from_ast(ast) == expected_result
  end

  @doc """
  Test the truth table generation for a more complex expression.
  """
  test "truth table for complex expression" do
    ast =
      AST.or_node(
        AST.var_node("A"),
        AST.and_node(AST.var_node("B"), AST.var_node("C"))
      )

    expected_result = [
      %{"A" => false, "B" => false, "C" => false, result: false},
      %{"A" => false, "B" => false, "C" => true, result: false},
      %{"A" => false, "B" => true, "C" => false, result: false},
      %{"A" => false, "B" => true, "C" => true, result: true},
      %{"A" => true, "B" => false, "C" => false, result: true},
      %{"A" => true, "B" => false, "C" => true, result: true},
      %{"A" => true, "B" => true, "C" => false, result: true},
      %{"A" => true, "B" => true, "C" => true, result: true}
    ]

    assert TruthTable.from_ast(ast) == expected_result
  end
end
