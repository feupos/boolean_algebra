defmodule BooleanAlgebra.PetrickTest do
  use ExUnit.Case
  alias BooleanAlgebra.Petrick

  test "minimal_cover returns minimal covers for prime implicant table" do
    table = %{
      0 => [[false, false], [false, true]],
      1 => [[false, false], [true, false]],
      2 => [[false, true], [true, false]]
    }

    result = Petrick.minimal_cover(table)

    # Expected minimal covers: {P1, P2}, {P1, P3}, {P2, P3}
    # P1=[F,F], P2=[F,T], P3=[T,F]
    expected = [
      [[false, false], [false, true]],
      [[false, false], [true, false]],
      [[false, true], [true, false]]
    ]

    assert sort_covers(result) == sort_covers(expected)
  end

  test "minimal_cover handles single implicant per minterm" do
    table = %{
      0 => [[true, false, false]],
      1 => [[false, true, false]],
      2 => [[false, false, true]]
    }

    result = Petrick.minimal_cover(table)

    expected = [
      [[false, false, true], [false, true, false], [true, false, false]]
    ]

    assert sort_covers(result) == sort_covers(expected)
  end

  test "minimal_cover handles full coverage by single implicant" do
    table = %{
      0 => [[:dont_care, :dont_care]],
      1 => [[:dont_care, :dont_care]],
      2 => [[:dont_care, :dont_care]]
    }

    result = Petrick.minimal_cover(table)

    expected = [[[:dont_care, :dont_care]]]

    assert sort_covers(result) == sort_covers(expected)
  end

  test "minimal_cover with realistic QMC output" do
    table = %{
      0 => [[false, :dont_care, false]],
      1 => [[:dont_care, false, true]],
      2 => [[false, :dont_care, false]],
      5 => [[:dont_care, false, true]]
    }

    result = Petrick.minimal_cover(table)

    expected = [
      [[:dont_care, false, true], [false, :dont_care, false]]
    ]

    assert sort_covers(result) == sort_covers(expected)
  end
  
  test "minimal_cover handles empty map" do
    assert Petrick.minimal_cover(%{}) == []
  end

  defp sort_covers(covers) do
    covers
    |> Enum.map(fn cover -> Enum.sort(cover) end)
    |> Enum.sort()
  end
end
