defmodule BooleanAlgebraProcessTest do
  use ExUnit.Case
  alias BooleanAlgebra

  describe "process/2" do
    test "returns only simplification by default" do
      input = "a | (a & b)"
      assert {:ok, result} = BooleanAlgebra.process(input)
      assert Map.keys(result) == [:simplification]
      assert result.simplification == "a"
    end

    test "returns truth table when requested" do
      input = "a & b"
      assert {:ok, result} = BooleanAlgebra.process(input, output: [:truth_table])
      assert Map.keys(result) == [:truth_table]
      assert is_list(result.truth_table)
    end

    test "returns details when requested" do
      input = "a | (a & b)"
      assert {:ok, result} = BooleanAlgebra.process(input, output: [:details, :simplification])
      assert :details in Map.keys(result)
      assert :simplification in Map.keys(result)
      assert is_map(result.details)
    end

    test "returns multiple outputs" do
      input = "a | b"

      assert {:ok, result} =
               BooleanAlgebra.process(input, output: [:simplification, :truth_table])

      assert :simplification in Map.keys(result)
      assert :truth_table in Map.keys(result)
      refute :details in Map.keys(result)
    end

    test "handles errors" do
      input = "a &"
      assert {:error, _} = BooleanAlgebra.process(input)
    end
  end
end
