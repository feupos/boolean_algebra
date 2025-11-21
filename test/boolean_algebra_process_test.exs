defmodule BooleanAlgebraProcessTest do
  use ExUnit.Case
  alias BooleanAlgebra

  describe "process/2" do
    test "returns all outputs by default" do
      input = "a | (a & b)"
      assert {:ok, result} = BooleanAlgebra.process(input)
      assert Map.keys(result) |> Enum.sort() == [:details, :simplification, :truth_table]
      assert result.simplification == "a"
      assert is_list(result.truth_table)
      assert is_map(result.details)
    end

    test "ignores output options and returns everything" do
      input = "a & b"
      assert {:ok, result} = BooleanAlgebra.process(input, output: [:truth_table])
      assert Map.keys(result) |> Enum.sort() == [:details, :simplification, :truth_table]
    end

    test "handles errors" do
      input = "a &"
      assert {:error, _} = BooleanAlgebra.process(input)
    end
  end
end
