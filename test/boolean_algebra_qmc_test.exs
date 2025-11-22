defmodule BooleanAlgebra.QMCTest do
  use ExUnit.Case

  alias BooleanAlgebra.QMC

  test "minterm_to_implicant produces correct bit list" do
    assert QMC.minterm_to_implicant(0b0101, 4) == [false, true, false, true]
    assert QMC.minterm_to_implicant(0b1110, 4) == [true, true, true, false]
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

  describe "Wikipedia QMC example" do
    # Reference: https://en.wikipedia.org/wiki/Quine%E2%80%93McCluskey_algorithm
    # Minterms: [4, 8, 10, 11, 12, 15], Don't cares: [9, 14]
    test "finds correct prime implicants and minimal covers with don't cares" do
      # Including don't cares as minterms: [4, 8, 9, 10, 11, 12, 14, 15]
      minterms = [4, 8, 9, 10, 11, 12, 14, 15]
      num_vars = 4

      {prime_implicants, qmc_steps} = QMC.prime_implicants(minterms, num_vars)

      # Verify we have QMC steps
      assert length(qmc_steps) > 0
      assert List.first(qmc_steps).type == :initial_grouping

      # Expected prime implicants (in binary ABCD format):
      # 10-- = A&!B (covers 8, 9, 10, 11)
      # 1-1- = A&C (covers 10, 11, 14, 15)
      # -100 = B&!C&!D (covers 4, 12)
      # Plus others...

      # Verify key prime implicants exist
      assert [true, false, :dont_care, :dont_care] in prime_implicants  # 10-- = A&!B
      assert [true, :dont_care, true, :dont_care] in prime_implicants   # 1-1- = A&C
      assert [:dont_care, true, false, false] in prime_implicants       # -100 = B&!C&!D

      # Build coverage table
      coverage_map = QMC.coverage_table(prime_implicants, minterms, num_vars)

      # Verify all minterms are covered
      assert Map.keys(coverage_map) |> Enum.sort() == Enum.sort(minterms)

      # Find minimal covers using Petrick's method
      minimal_covers = BooleanAlgebra.Petrick.minimal_cover(coverage_map)

      # Should find multiple minimal covers
      assert length(minimal_covers) > 0

      # Find the best cover (minimum literals)
      best_cover = Enum.min_by(minimal_covers, fn cover ->
        cover_list = MapSet.to_list(cover)
        Enum.reduce(cover_list, 0, fn pi, acc ->
          acc + Enum.count(pi, &(&1 != :dont_care))
        end)
      end)

      best_cover_list = MapSet.to_list(best_cover)
      total_literals = Enum.reduce(best_cover_list, 0, fn pi, acc ->
        acc + Enum.count(pi, &(&1 != :dont_care))
      end)

      # The minimal solution should have 7 literals total
      # One valid solution: A&!B (2) + A&C (2) + B&!C&!D (3) = 7 literals
      assert total_literals == 7

      # Verify the best cover contains exactly 3 implicants
      assert length(best_cover_list) == 3

      # Verify it includes the key implicants
      assert [true, false, :dont_care, :dont_care] in best_cover_list or  # A&!B
             [true, :dont_care, true, :dont_care] in best_cover_list       # A&C
      assert [:dont_care, true, false, false] in best_cover_list           # B&!C&!D
    end
  end
end
