defmodule BooleanAlgebra.QMCTest do
  use ExUnit.Case

  alias BooleanAlgebra.QMC

  test "int_to_bits produces correct bit list" do
    assert QMC.int_to_bits(0b0101, 4) == [false, true, false, true]
    assert QMC.int_to_bits(0b1110, 4) == [true, true, true, false]
  end

  test "count_ones calculates correct number of set bits" do
    assert QMC.count_ones(0b0101, 4) == 2
    assert QMC.count_ones(0b1111, 4) == 4
    assert QMC.count_ones(0b0000, 4) == 0
  end

  test "group_minterms groups correctly" do
    minterms = [0, 1, 3, 7, 8, 9]
    grouped = QMC.group_minterms(minterms, 4)
    assert Map.keys(grouped) == [0, 1, 2, 3]
    assert grouped[0] == [0]
    assert Enum.sort(grouped[1]) == Enum.sort([1, 8])
    assert Enum.sort(grouped[2]) == Enum.sort([3, 9])
    assert grouped[3] == [7]
  end

  test "combine_implicants merges correctly for single bit difference" do
    # "1-0" + "1-1" -> "1--"
    assert QMC.combine_implicants(
             [true, :dont_care, false],
             [true, :dont_care, true]
           ) == {:ok, [true, :dont_care, :dont_care]}

    # "000" + "100" -> "-00"
    assert QMC.combine_implicants(
             [false, false, false],
             [true, false, false]
           ) == {:ok, [:dont_care, false, false]}

    # "010" + "110" -> "-10"
    assert QMC.combine_implicants(
             [false, true, false],
             [true, true, false]
           ) == {:ok, [:dont_care, true, false]}
  end

  test "combine_implicants returns error for multiple bit differences" do
    # "110" + "001" (3 differences)
    assert QMC.combine_implicants(
             [true, true, false],
             [false, false, true]
           ) == :error

    # "0-0" + "1-1" (2 differences)
    assert QMC.combine_implicants(
             [false, :dont_care, false],
             [true, :dont_care, true]
           ) == :error
  end

  test "find_prime_implicants finds prime implicants correctly" do
    minterms = [0, 1, 2, 5, 6, 7]
    grouped = QMC.group_minterms(minterms, 3)
    {primes, _} = QMC.find_prime_implicants(grouped, 3)

    # Expected prime implicants: [0, :dont_care, 0], [1, :dont_care, 1], [:dont_care, 1, 1]
    # assert Enum.member?(primes, [false, :dont_care, false])
    # assert Enum.member?(primes, [true, :dont_care, true]) or
    #        Enum.member?(primes, [:dont_care, true, true])
    assert Enum.member?(primes, [false, false, :dont_care])
    assert Enum.member?(primes, [:dont_care, true, false])
    assert Enum.member?(primes, [true, :dont_care, true])
  end

  test "coverage_table associates minterms with covering implicants" do
    # "1-0" = [true, :dont_care, false]
    # "0-1" = [false, :dont_care, true]
    # "--1" = [:dont_care, :dont_care, true]
    prime_implicants = [
      [true, :dont_care, false],
      [false, :dont_care, true],
      [:dont_care, :dont_care, true]
    ]

    minterms = [2, 3]
    coverage = QMC.coverage_table(prime_implicants, minterms, 3)

    # minterm 2 = "010" = [false, true, false] - not covered by any
    assert coverage[2] == []

    # minterm 3 = "011" = [false, true, true] - covered by "0-1" and "--1"
    assert coverage[3] == [
             [false, :dont_care, true],
             [:dont_care, :dont_care, true]
           ]
  end

  test "minimize returns prime implicants for non-empty minterms" do
    minterms = [1, 3, 5, 7]
    primes = QMC.minimize(minterms, 3)
    assert is_list(primes)
    assert length(primes) > 0
    assert Enum.all?(primes, &is_list/1)
  end

  test "minimize returns empty list for empty minterms" do
    assert QMC.minimize([], 3) == []
  end
end
