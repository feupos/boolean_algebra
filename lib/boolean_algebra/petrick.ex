defmodule BooleanAlgebra.Petrick do
  @moduledoc """
  Petrick's method for selecting minimal prime implicant covers.

  References:
  - https://www.allaboutcircuits.com/technical-articles/prime-implicant-simplification-using-petricks-method/
  - https://en.wikipedia.org/wiki/Petrick%27s_method
  """

  @type implicant :: [boolean() | :dont_care]
  @type coverage_table :: %{integer() => [implicant()]}

  @doc """
  Finds minimal covers given a prime implicant coverage table.

  Returns a list of minimal sets where each set is a list of implicants that together cover all minterms.
  """
  @spec minimal_cover(coverage_table()) :: [[implicant()]]
  def minimal_cover(prime_implicant_table) when is_map(prime_implicant_table) do
    prime_implicant_table
    |> Map.values()
    # Convert coverage table to Product of Sums (POS) representation using MapSet to ensure unique implicants later
    |> Enum.map(&Enum.map(&1, fn implicant -> MapSet.new([implicant]) end))
    |> expand_and_minimize()
  end

  # Expands POS to SOP while removing supersets at each step
  # [[{A}, {B}], [{C}, {D}]] -> [{A,C}, {A,D}, {B,C}, {B,D}]
  defp expand_and_minimize([first_sum | rest_sums]) do
    Enum.reduce(rest_sums, first_sum, fn sum, acc ->
      acc
      |> distribute_sums(sum)
      |> keep_minimal()
    end)
  end

  defp expand_and_minimize([]), do: []

  # distribute_sums two sums: (A | B) & (C | D) = (A & C) | (A & D) | (B & C) | (B & D)
  defp distribute_sums(sum1, sum2) do
    for term1 <- sum1, term2 <- sum2 do
      MapSet.union(term1, term2)
    end
  end

  # Keeps only minimal covers by removing supersets
  defp keep_minimal(covers) do
    # Sort covers by size to ensure minimal covers are kept first
    # making the algorithm more efficient
    sorted_covers = Enum.sort_by(covers, &MapSet.size/1)

    Enum.reduce(sorted_covers, [], fn candidate, kept_covers ->
      is_redundant =
        Enum.any?(kept_covers, &MapSet.subset?(&1, candidate))

      if is_redundant do
        kept_covers
      else
        [candidate | kept_covers]
      end
    end)
  end
end
