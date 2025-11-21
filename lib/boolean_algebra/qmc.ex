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
  Minimize the boolean function represented by the given minterms and number of variables.
  Returns a list of prime implicants. Each prime implicant is a list of booleans and `:dont_care` atoms.
  """
  @spec minimize([minterm()], integer()) :: [implicant()]
  def minimize(minterms, num_vars) when is_list(minterms) and is_integer(num_vars) do
    # Step 1: Group minterms by number of 1s
    initial_groups = group_minterms(minterms, num_vars)

    # Step 2: Find all prime implicants by iteratively merging groups
    # We use the version with steps to avoid code duplication, even if we discard the steps.
    {prime_implicants, _steps} = find_prime_implicants_with_steps(initial_groups, num_vars)
    prime_implicants
  end

  @doc """
  Same as minimize/2 but returns the steps taken during the Quine-McCluskey algorithm.
  Returns `{prime_implicants, steps}` where steps is a list of maps describing each pass.
  """
  def minimize_with_steps(minterms, num_vars) do
    # Step 1: Group minterms by number of 1s
    initial_groups = group_minterms(minterms, num_vars)

    # Step 2: Find all prime implicants by iteratively merging groups
    {prime_implicants, steps} = find_prime_implicants_with_steps(initial_groups, num_vars)

    {prime_implicants, [%{type: :initial_grouping, groups: initial_groups} | steps]}
  end

  @doc """
  Groups minterms by the number of 1-bits they contain.
  Returns a map where keys are the count of 1s and values are lists of implicants (as bit lists).
  """
  @spec group_minterms([minterm()], integer()) :: grouped_implicants()
  def group_minterms(minterms, num_vars) do
    minterms
    |> Enum.map(&int_to_bits(&1, num_vars))
    |> Enum.group_by(&count_ones_in_list/1)
  end

  defp find_prime_implicants_with_steps(grouped_implicants, num_vars, acc_steps \\ []) do
    group_keys = Map.keys(grouped_implicants) |> Enum.sort()

    # Iterate through groups and try to merge adjacent groups
    {next_generation_groups, unmerged_from_current_pass, merge_details} =
      Enum.reduce(group_keys, {%{}, [], []}, fn key,
                                                {acc_next_groups, acc_unmerged, acc_merges} ->
        current_group = Map.get(grouped_implicants, key, [])
        next_group = Map.get(grouped_implicants, key + 1, [])

        {merged_implicants, _merged_flag, unmerged_in_this_step} =
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

    current_step = %{
      type: :merge_pass,
      groups_before: grouped_implicants,
      groups_after: next_generation_groups,
      merges: Enum.reverse(merge_details),
      unmerged: unmerged_from_current_pass
    }

    if map_size(next_generation_groups) > 0 do
      regrouped = regroup_by_ones(next_generation_groups)

      {primes_from_recursion, steps_from_recursion} =
        find_prime_implicants_with_steps(regrouped, num_vars, [current_step | acc_steps])

      current_pass_primes = Enum.uniq(unmerged_from_current_pass)
      all_primes = Enum.uniq(current_pass_primes ++ primes_from_recursion)

      {all_primes, steps_from_recursion}
    else
      # Base case: No more merges possible.
      all_primes =
        grouped_implicants
        |> Map.values()
        |> Enum.concat()
        |> Enum.uniq()

      {all_primes, Enum.reverse([current_step | acc_steps])}
    end
  end

  # Merges two groups of implicants (e.g. group with N ones and group with N+1 ones).
  # Returns {merged_implicants, any_merge_happened?, unmerged_from_group1}
  defp merge_adjacent_groups(group1, group2) do
    # 1. Find all merges
    {merged_list, merged_indices_1} =
      Enum.reduce(Enum.with_index(group1), {[], MapSet.new()}, fn {imp1, idx1},
                                                                  {acc_merged, acc_indices} ->
        # Try to find matches in group2
        matches =
          Enum.filter(group2, fn imp2 -> can_merge?(imp1, imp2) end)

        if matches != [] do
          new_merges = Enum.map(matches, fn imp2 -> merge(imp1, imp2) end)
          {acc_merged ++ new_merges, MapSet.put(acc_indices, idx1)}
        else
          {acc_merged, acc_indices}
        end
      end)

    # 2. Identify unmerged items from group1
    unmerged_from_group1 =
      group1
      |> Enum.with_index()
      |> Enum.reject(fn {_imp, idx} -> MapSet.member?(merged_indices_1, idx) end)
      |> Enum.map(fn {imp, _} -> imp end)

    {merged_list, MapSet.size(merged_indices_1) > 0, unmerged_from_group1}
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

  # Regroup merged implicants by number of 1s (ignoring :dont_care bits)
  defp regroup_by_ones(implicants_map) do
    implicants_map
    |> Map.values()
    |> Enum.concat()
    |> Enum.group_by(&count_ones_in_list/1)
  end

  defp count_ones_in_list(implicant_list) do
    Enum.count(implicant_list, fn c -> c == true end)
  end

  @doc """
  Converts an integer to a list of bits of length n.
  Most significant bit first.
  """
  def int_to_bits(num, n) do
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
      implicants_covering =
        Enum.filter(prime_implicants, fn implicant ->
          covers_minterm?(implicant, minterm, num_vars)
        end)

      Map.put(acc, minterm, implicants_covering)
    end)
  end

  # Checks if a specific implicant covers a minterm
  defp covers_minterm?(implicant, minterm, num_vars) do
    minterm_bits = int_to_bits(minterm, num_vars)

    Enum.zip(implicant, minterm_bits)
    |> Enum.all?(fn
      {:dont_care, _bit} -> true
      {val, bit} -> val == bit
    end)
  end
end
