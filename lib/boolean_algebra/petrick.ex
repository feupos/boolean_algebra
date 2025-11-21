defmodule BooleanAlgebra.Petrick do
  @moduledoc """
  Petrick's method for selecting minimal prime implicant covers.

  Petrick's method is a technique used for determining all minimum sum-of-products solutions from a prime implicant chart.
  It is particularly useful when the chart is cyclic or complex.

  References:
  - https://www.allaboutcircuits.com/technical-articles/prime-implicant-simplification-using-petricks-method/
  - https://en.wikipedia.org/wiki/Petrick%27s_method

  The algorithm steps are:
  1. Reduce the Prime Implicant Chart by eliminating essential prime implicants (handled before this or part of the input).
  2. Label the rows of the reduced prime implicant chart (minterms).
  3. Form a logic function P which is the product of the sums of the prime implicants covering each minterm.
     P = (PI_a | PI_b) & (PI_c | PI_d) ...
     where (PI_a | PI_b) means minterm 1 is covered by PI_a OR PI_b.
  4. Expand P into a Sum of Products (SOP) form using the distributive law: (X | Y)(Z | W) = XZ | XW | YZ | YW.
  5. Simplify the result using X | (X & Y) = X (Absorption Law) to remove supersets.
  6. Each resulting product term represents a valid cover. Choose the one with the fewest prime implicants.
  """

  @doc """
  Finds the minimal covers of a Boolean function given a prime implicant coverage table.

  The `prime_implicant_table` parameter should be a map where keys are minterm integers,
  and values are lists of prime implicants that cover the minterm.

  Returns a list of minimal sets. Each set is a list of implicants (e.g. `[true, false, :dont_care]`) that together cover all minterms.
  """
  def minimal_cover(prime_implicant_table) when is_map(prime_implicant_table) do
    # Step 1: Convert the coverage table to a Product of Sums (POS) representation.
    # Each value in the map is a list of PIs covering a specific minterm.
    # We treat this list as a Sum (OR) of PIs.
    # The whole table implies we need to cover minterm1 AND minterm2 AND ...
    # So we have Product (AND) of these Sums.
    product_of_sums =
      prime_implicant_table
      |> Map.values()
      |> Enum.map(fn implicants_list ->
        # Convert each PI list to a list of MapSets (each MapSet containing one PI)
        # This prepares it for the multiplication process where we union these sets.
        Enum.map(implicants_list, &MapSet.new([&1]))
      end)

    # Step 2: Expand the POS into a Sum of Products (SOP).
    # Result is a list of MapSets, where each MapSet is a valid cover (set of PIs).
    all_covers = expand_pos_to_sop(product_of_sums)

    # Step 3: Simplify by removing supersets (finding minimal covers).
    minimal_covers = remove_supersets(all_covers)

    # Convert back to list of lists for the return value
    Enum.map(minimal_covers, &MapSet.to_list/1)
  end

  # Recursively multiplies the sum terms.
  # Input: List of lists of MapSets. [[{A}, {B}], [{C}, {D}]] representing (A | B) & (C | D)
  # Output: List of MapSets. [{A,C}, {A,D}, {B,C}, {B,D}] representing (A & C) | (A & D) | (B & C) | (B & D)
  defp expand_pos_to_sop([first_sum | rest_sums]) do
    Enum.reduce(rest_sums, first_sum, fn sum, acc ->
      acc
      |> multiply_two_sums(sum)
      |> remove_supersets()
    end)
  end

  defp expand_pos_to_sop([]), do: []

  # Multiplies two sums (distributes).
  # (A | B) & (C | D) = (A & C) | (A & D) | (B & C) | (B & D)
  # In our structure:
  # sum1 = [{A}, {B}]
  # sum2 = [{C}, {D}]
  # Result = [{A,C}, {A,D}, {B,C}, {B,D}] (where {X,Y} is the union of sets)
  defp multiply_two_sums(sum1, sum2) do
    for term1 <- sum1, term2 <- sum2 do
      MapSet.union(term1, term2)
    end
  end

  # Removes non-minimal covers.
  # If we have covers {A, B} and {A, B, C}, then {A, B, C} is redundant because {A, B} is sufficient.
  # We keep only the sets that are not supersets of any other set in the list.
  defp remove_supersets(covers) do
    # Sort by size to optimize: smaller sets can eliminate larger sets, but larger sets can't eliminate smaller ones.
    # (Optimization not strictly necessary for correctness but good for performance)
    sorted_covers = Enum.sort_by(covers, &MapSet.size/1)

    Enum.reduce(sorted_covers, [], fn candidate, kept_covers ->
      # Check if 'candidate' is a superset of any already 'kept_covers'
      is_redundant =
        Enum.any?(kept_covers, fn existing -> MapSet.subset?(existing, candidate) end)

      if is_redundant do
        kept_covers
      else
        # If it's not redundant based on what we've seen (smaller sets), we keep it.
        # Note: Since we sorted by size, we don't need to check if 'candidate' eliminates any 'kept_covers'
        # because 'candidate' is >= size of any 'kept'.
        [candidate | kept_covers]
      end
    end)
    |> Enum.reverse()
  end
end
