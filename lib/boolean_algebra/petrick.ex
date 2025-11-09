defmodule BooleanAlgebra.Petrick do
  @moduledoc """
  Petrick's method for selecting minimal prime implicant covers.
  This method finds the minimal combination of prime implicants that covers
  all minterms given a prime implicant coverage table.

  https://www.allaboutcircuits.com/technical-articles/prime-implicant-simplification-using-petricks-method/
  """

  @doc """
  Finds the minimal covers of a Boolean function given a prime implicant coverage table.

  The `prime_implicant_table` parameter should be a map where keys are minterm integers,
  and values are lists of prime implicant identifiers (strings) that cover the minterm.

  Returns a list of minimal sets (each set is a list of implicants) covering all minterms.
  """
  def minimal_cover(prime_implicant_table) when is_map(prime_implicant_table) do
    prime_implicant_table
    |> Map.values()
    |> Enum.map(fn implicants -> Enum.map(implicants, &MapSet.new([&1])) end)
    |> combine_products()
    |> simplify()
    |> Enum.map(&MapSet.to_list/1)
  end

  # Combine product-of-sums expressions pairwise until one product remains
  defp combine_products([first | rest]) do
    Enum.reduce(rest, first, &multiply_sums/2)
  end

  defp combine_products([]), do: []

  # Multiply two sums (lists of MapSets) to produce new sum of products expression
  defp multiply_sums(sum1, sum2) do
    for p1 <- sum1, p2 <- sum2, do: MapSet.union(p1, p2)
  end

  # Simplify: remove supersets (non-minimal solutions)
  defp simplify(products) do
    Enum.reject(products, fn set1 ->
      Enum.any?(products, fn set2 ->
        set1 != set2 && MapSet.subset?(set2, set1)
      end)
    end)
  end
end
