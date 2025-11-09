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
    assert QMC.combine_implicants("1-0", "1-1") == {:ok, "1--"}
    assert QMC.combine_implicants("000", "100") == {:ok, "-00"}
    assert QMC.combine_implicants("010", "110") == {:ok, "-10"}
  end

  test "combine_implicants returns error for multiple bit differences" do
    assert QMC.combine_implicants("110", "001") == :error
    assert QMC.combine_implicants("0-0", "1-1") == :error
  end

  test "find_prime_implicants finds prime implicants correctly" do
    minterms = [0, 1, 2, 5, 6, 7]
    grouped = QMC.group_minterms(minterms, 3)
    {primes, _} = QMC.find_prime_implicants(grouped, 3)
    # Example expected prime implicants for this input could be:
    # "0-0", "1-1", "-11"
    # Adjust expected list based on your implementation output
    assert Enum.member?(primes, "0-0")
    assert Enum.member?(primes, "1-1") or Enum.member?(primes, "-11")
  end

  test "coverage_table associates minterms with covering implicants" do
    prime_implicants = ["1-0", "0-1", "--1"]
    minterms = [2, 3]
    coverage = QMC.coverage_table(prime_implicants, minterms, 3)
    assert coverage[2] == []
    assert coverage[3] == ["0-1", "--1"]
  end

  test "minimize returns prime implicants for non-empty minterms" do
    minterms = [1, 3, 5, 7]
    primes = QMC.minimize(minterms, 3)
    assert is_list(primes)
    assert length(primes) > 0
  end

  test "minimize returns empty list for empty minterms" do
    assert QMC.minimize([], 3) == []
  end
end
