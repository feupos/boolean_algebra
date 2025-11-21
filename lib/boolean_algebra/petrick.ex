defmodule BooleanAlgebra.Petrick do
  @moduledoc """
  Petrick's method for selecting minimal prime implicant covers.

  References:
  - https://www.allaboutcircuits.com/technical-articles/prime-implicant-simplification-using-petricks-method/
  - https://en.wikipedia.org/wiki/Petrick%27s_method
  """

  @doc """
  Finds minimal covers given a prime implicant coverage table.

  Returns a list of minimal sets where each set is a list of implicants that together cover all minterms.
  """
  def minimal_cover(prime_implicant_table) when is_map(prime_implicant_table) do
    # Convert coverage table to Product of Sums (POS) representation
    product_of_sums =
      prime_implicant_table
      |> Map.values()
      |> Enum.map(fn implicants_list ->
        Enum.map(implicants_list, &MapSet.new([&1]))
      end)

    # Expand POS into Sum of Products (SOP)
    all_covers = expand_pos_to_sop(product_of_sums)

    # Remove supersets to find minimal covers
    minimal_covers = remove_supersets(all_covers)

    Enum.map(minimal_covers, &MapSet.to_list/1)
  end

  # Recursively multiplies sum terms
  # [[{A}, {B}], [{C}, {D}]] -> [{A,C}, {A,D}, {B,C}, {B,D}]
  defp expand_pos_to_sop([first_sum | rest_sums]) do
    Enum.reduce(rest_sums, first_sum, fn sum, acc ->
      acc
      |> multiply_two_sums(sum)
      |> remove_supersets()
    end)
  end

  defp expand_pos_to_sop([]), do: []

  # Distributes two sums: (A | B) & (C | D) = (A & C) | (A & D) | (B & C) | (B & D)
  defp multiply_two_sums(sum1, sum2) do
    for term1 <- sum1, term2 <- sum2 do
      MapSet.union(term1, term2)
    end
  end

  # Removes non-minimal covers (supersets)
  defp remove_supersets(covers) do
    sorted_covers = Enum.sort_by(covers, &MapSet.size/1)

    Enum.reduce(sorted_covers, [], fn candidate, kept_covers ->
      is_redundant =
        Enum.any?(kept_covers, fn existing -> MapSet.subset?(existing, candidate) end)

      if is_redundant do
        kept_covers
      else
        [candidate | kept_covers]
      end
    end)
    |> Enum.reverse()
  end
end
