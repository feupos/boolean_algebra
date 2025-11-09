defmodule BooleanAlgebra.PetrickTest do
  use ExUnit.Case
  alias BooleanAlgebra.Petrick

  test "minimal_cover returns minimal covers for prime implicant table" do
    # Example prime implicant table:
    # Minterm => [implicant1, implicant2, ...]
    table = %{
      0 => ["A", "B"],
      1 => ["A", "C"],
      2 => ["B", "C"]
    }

    minimal = Petrick.minimal_cover(table)
    # Minimal covers are sets that cover all minterms:
    # Possible covers are ["A", "B"], ["A", "C"], or ["B", "C"],
    # but minimal cover sets have minimal implicant count.
    assert Enum.any?(minimal, fn cover -> Enum.sort(cover) == ["A", "B"] end)
    assert Enum.any?(minimal, fn cover -> Enum.sort(cover) == ["A", "C"] end)
    assert Enum.any?(minimal, fn cover -> Enum.sort(cover) == ["B", "C"] end)
  end

  test "minimal_cover handles single implicant per minterm" do
    table = %{
      0 => ["X"],
      1 => ["Y"],
      2 => ["Z"]
    }

    minimal = Petrick.minimal_cover(table)
    # Only one solution which is all implicants combined
    assert minimal == [["X", "Y", "Z"]]
  end

  test "minimal_cover handles full coverage by single implicant" do
    table = %{
      0 => ["Q"],
      1 => ["Q"],
      2 => ["Q"]
    }

    minimal = Petrick.minimal_cover(table)
    # Single implicant covers all minterms
    assert minimal == [["Q"]]
  end
end
