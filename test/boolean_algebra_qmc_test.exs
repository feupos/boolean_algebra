defmodule BooleanAlgebra.QMCTest do
  use ExUnit.Case

  alias BooleanAlgebra.QMC

  test "int_to_bits produces correct bit list" do
    assert QMC.int_to_bits(0b0101, 4) == [false, true, false, true]
    assert QMC.int_to_bits(0b1110, 4) == [true, true, true, false]
  end

  test "group_minterms groups correctly" do
    minterms = [0, 1, 3, 7, 8, 9]
    grouped = QMC.group_minterms(minterms, 4)
    assert Map.keys(grouped) == [0, 1, 2, 3]

    # Check group 0 (minterm 0 -> [0,0,0,0])
    assert grouped[0] == [[false, false, false, false]]

    # Check group 1 (minterms 1, 8)
    # 1 -> [0,0,0,1], 8 -> [1,0,0,0]
    expected_group_1 = [
      [false, false, false, true],
      [true, false, false, false]
    ]

    # Sort to compare ignoring order
    assert Enum.sort(grouped[1]) == Enum.sort(expected_group_1)
  end

  test "find_prime_implicants finds prime implicants correctly" do
    minterms = [0, 1, 2, 5, 6, 7]
    {primes, _steps} = QMC.prime_implicants(minterms, 3)

    # Expected prime implicants:
    # 0 (000), 1 (001) -> 00- (0,1) -> [false, false, :dont_care]
    # 0 (000), 2 (010) -> 0-0 (0,2) -> [false, :dont_care, false]
    # 1 (001), 5 (101) -> -01 (1,5) -> [:dont_care, false, true]
    # 2 (010), 6 (110) -> -10 (2,6) -> [:dont_care, true, false]
    # 5 (101), 7 (111) -> 1-1 (5,7) -> [true, :dont_care, true]
    # 6 (110), 7 (111) -> 11- (6,7) -> [true, true, :dont_care]

    assert Enum.member?(primes, [false, false, :dont_care])
    assert Enum.member?(primes, [false, :dont_care, false])
    assert Enum.member?(primes, [:dont_care, false, true])
    assert Enum.member?(primes, [:dont_care, true, false])
    assert Enum.member?(primes, [true, :dont_care, true])
    assert Enum.member?(primes, [true, true, :dont_care])
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
    {primes, _steps} = QMC.prime_implicants(minterms, 3)
    assert is_list(primes)
    assert length(primes) > 0
    assert Enum.all?(primes, &is_list/1)
  end

  test "minimize returns empty list for empty minterms" do
    {primes, _steps} = QMC.prime_implicants([], 3)
    assert primes == []
  end
end
