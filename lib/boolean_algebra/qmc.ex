defmodule BooleanAlgebra.QMC do
  @moduledoc """
  Quine-McCluskey implementation for Boolean minimization.

  The Quine-McCluskey algorithm (or the method of prime implicants) is a method used for minimization of boolean functions.
  It is functionally identical to Karnaugh mapping, but the tabular form makes it more efficient for use in computer algorithms.

  References:
  - https://www.geeksforgeeks.org/digital-logic/quine-mccluskey-method/
  - https://en.wikipedia.org/wiki/Quine%E2%80%93McCluskey_algorithm

  The process involves two main steps:
  1. Finding all prime implicants of the function.
  2. Using those prime implicants in a prime implicant chart to find the essential prime implicants (and other necessary prime implicants) to cover the function.
  """

  import Bitwise

  @type minterm :: integer()
  @type implicant :: [boolean() | :dont_care]
  @type group_id :: integer()
  @type grouped_implicants :: %{group_id() => [implicant()]}

  @doc """
  Finds all prime implicants for the given minterms.
  Returns `{prime_implicants, steps}` where steps is a list of maps describing each pass.
  """
  @spec prime_implicants([minterm()], integer()) :: {[implicant()], [map()]}
  def prime_implicants(minterms, num_vars) do
    # Convert minterms to implicants
    implicants = Enum.map(minterms, &minterm_to_implicant(&1, num_vars))

    # Find all prime implicants by iteratively merging groups
    {prime_implicants, steps} = find_prime_implicants_with_steps(implicants, num_vars)

    {prime_implicants, steps}
  end

  defp find_prime_implicants_with_steps(implicants, num_vars, acc_steps \\ []) do
    # Group implicants by number of 1s on first call or regroup after merging
    grouped_implicants = group_by_ones(implicants)

    initial_step = %{type: :grouping, groups: grouped_implicants}

    group_keys = Map.keys(grouped_implicants) |> Enum.sort()

    # Iterate through groups and try to merge adjacent groups
    {next_generation_groups, unmerged_from_current_pass, merge_details} =
      Enum.reduce(group_keys, {%{}, [], []}, fn key,
                                                {acc_next_groups, acc_unmerged, acc_merges} ->
        current_group = Map.get(grouped_implicants, key, [])
        next_group = Map.get(grouped_implicants, key + 1, [])

        {merged_implicants, unmerged_in_this_step} =
          merge_adjacent_groups(current_group, next_group)

        new_next_groups =
          if merged_implicants != [] do
            Map.update(acc_next_groups, key, merged_implicants, &(merged_implicants ++ &1))
          else
            acc_next_groups
          end

        # Record merge details for this pair of groups
        merge_info = %{
          group: key,
          next_group: key + 1,
          merged: merged_implicants,
          unmerged: unmerged_in_this_step
        }

        {new_next_groups, acc_unmerged ++ unmerged_in_this_step, [merge_info | acc_merges]}
      end)

    merge_step = %{
      type: :merge_pass,
      groups_before: grouped_implicants,
      groups_after: next_generation_groups,
      merges: Enum.reverse(merge_details),
      unmerged: unmerged_from_current_pass
    }

    if map_size(next_generation_groups) > 0 do
      # Flatten for next iteration
      next_implicants = next_generation_groups |> Map.values() |> Enum.concat()

      {primes_from_recursion, steps_from_recursion} =
        find_prime_implicants_with_steps(next_implicants, num_vars, [
          merge_step,
          initial_step | acc_steps
        ])

      all_primes = Enum.uniq(unmerged_from_current_pass ++ primes_from_recursion)

      {all_primes, steps_from_recursion}
    else
      # Base case: No more merges possible.
      all_primes =
        grouped_implicants
        |> Map.values()
        |> Enum.concat()
        |> Enum.uniq()

      {all_primes, Enum.reverse([merge_step, initial_step | acc_steps])}
    end
  end

  # Merges two groups of implicants (e.g. group with N ones and group with N+1 ones)
  # Returns {merged_implicants, unmerged_from_group1}
  defp merge_adjacent_groups(group1, group2) do
    indexed_group1 = Enum.with_index(group1)

    {merged_list, merged_indices} =
      Enum.reduce(indexed_group1, {[], MapSet.new()}, fn {imp1, idx1},
                                                         {acc_merged, acc_indices} ->
        matches = Enum.filter(group2, &can_merge?(imp1, &1))

        if matches != [] do
          new_merges = Enum.map(matches, &merge(imp1, &1))
          {acc_merged ++ new_merges, MapSet.put(acc_indices, idx1)}
        else
          {acc_merged, acc_indices}
        end
      end)

    unmerged_from_group1 =
      indexed_group1
      |> Enum.reject(fn {_imp, idx} -> MapSet.member?(merged_indices, idx) end)
      |> Enum.map(fn {imp, _} -> imp end)

    {merged_list, unmerged_from_group1}
  end

  # Checks if two implicants can merge (differ by exactly one bit)
  defp can_merge?(imp1, imp2) do
    diff_count =
      Enum.zip(imp1, imp2)
      |> Enum.count(fn {b1, b2} -> b1 != b2 end)

    diff_count == 1
  end

  # Merge two implicants
  defp merge(imp1, imp2) do
    Enum.zip(imp1, imp2)
    |> Enum.map(fn
      {b, b} -> b
      {_b1, _b2} -> :dont_care
    end)
  end

  # Groups implicants by number of 1s (ignoring :dont_care bits)
  defp group_by_ones(implicants) when is_list(implicants) do
    Enum.group_by(implicants, &count_ones_in_implicant/1)
  end

  defp count_ones_in_implicant(implicant_list) do
    Enum.count(implicant_list, fn c -> c == true end)
  end

  @doc """
  Converts an minterm (integer) to an implicant (list of bits) of length n.
  Most significant bit first.
  """
  def minterm_to_implicant(num, n) do
    Enum.map((n - 1)..0//-1, fn i ->
      (num >>> i &&& 1) == 1
    end)
  end

  @doc """
  Given prime implicants and a list of minterms,
  build a coverage map from minterms to implicants covering them.

  Returns a map: %{minterm => [implicants_that_cover_it]}
  """
  def coverage_table(prime_implicants, minterms, num_vars) do
    Enum.reduce(minterms, %{}, fn minterm, acc ->
      Map.put(
        acc,
        minterm,
        Enum.filter(prime_implicants, &covers_minterm?(&1, minterm, num_vars))
      )
    end)
  end

  # Checks if a specific implicant covers a minterm
  defp covers_minterm?(implicant, minterm, num_vars) do
    minterm_bits = minterm_to_implicant(minterm, num_vars)

    Enum.zip(implicant, minterm_bits)
    |> Enum.all?(fn
      {:dont_care, _bit} -> true
      {val, bit} -> val == bit
    end)
  end
end
