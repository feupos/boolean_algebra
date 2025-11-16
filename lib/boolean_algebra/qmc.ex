defmodule BooleanAlgebra.QMC do
  @moduledoc """
  Quine-McCluskey implementation for Boolean minimization.

  https://www.geeksforgeeks.org/digital-logic/quine-mccluskey-method/
  https://www.youtube.com/watch?v=y1dtK9esyyM

  The main function `minimize/2` takes a list of minterms as integers and the number of boolean variables.
  It returns a list of prime implicants expressed as lists of bits using true, false and :dont_care to represent don't-care bits.
  """

  import Bitwise

  @doc """
  Minimize the boolean function represented by the given minterms and number of variables.

  Returns a list of prime implicants.
  """
  def minimize(minterms, num_vars) when is_list(minterms) and is_integer(num_vars) do
    grouped = group_minterms(minterms, num_vars)
    {prime_implicants, _unused} = find_prime_implicants(grouped, num_vars)
    prime_implicants
  end

  def minimize([], _num_vars), do: []

  @doc """
  Groups minterms by the number of 1-bits they contain.
  """
  def group_minterms(minterms, num_vars) do
    Enum.group_by(minterms, &count_ones(&1, num_vars))
  end

  @doc """
  Counts the number of 1 bits in the integer, interpreting it as an n-bit number.
  """
  def count_ones(minterm, num_vars) do
    int_to_bits(minterm, num_vars)
    |> Enum.count(&(&1 == true))
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

  # Combines two implicants if they differ in exactly one bit, marking that bit as :dont_care.
  def combine_implicants(imp1, imp2) when is_list(imp1) and is_list(imp2) do
    result =
      Enum.zip(imp1, imp2)
      |> Enum.reduce_while({:not_found, []}, fn
        # Both are exactly the same (including both :dont_care)
        {b, b}, {found, acc} ->
          {:cont, {found, acc ++ [b]}}

        # First bit difference (both must be concrete booleans)
        {b1, b2}, {:not_found, acc} when is_boolean(b1) and is_boolean(b2) ->
          {:cont, {:found, acc ++ [:dont_care]}}

        # Second bit difference - stop immediately
        {_b1, _b2}, {_count, _acc} ->
          {:halt, :too_many_diffs}
      end)

    case result do
      {:found, combined_bits} -> {:ok, combined_bits}
      _ -> :error
    end
  end

  @doc """
  Finds all prime implicants by iterative merging of grouped minterms.

  Returns {prime_implicants, unused}.
  """
  def find_prime_implicants(grouped, _num_vars) when map_size(grouped) == 0 do
    {[], []}
  end

  def find_prime_implicants(grouped, num_vars) do
    if map_size(grouped) == 0 do
      {[], []}
    else
      group_keys = Map.keys(grouped) |> Enum.sort()

      # Try to merge groups
      {next_groups, unused_from_this_iteration} =
        Enum.reduce(group_keys, {%{}, []}, fn key, {acc_groups, unused_acc} ->
          current_group = Map.get(grouped, key, [])
          next_group = Map.get(grouped, key + 1, [])

          {merged_group, _merged_flag, unmerged} =
            compare_and_merge_groups(current_group, next_group, num_vars)

          if merged_group != [] do
            # Store merged items for next iteration
            new_groups = Map.update(acc_groups, key, merged_group, &(merged_group ++ &1))
            # Convert unmerged to lists before adding
            converted_unmerged = Enum.map(unmerged, &to_implicant_list(&1, num_vars))
            {new_groups, unused_acc ++ converted_unmerged}
          else
            # No merges found, all current items are unused
            # Convert unmerged to lists before adding
            converted_unmerged = Enum.map(unmerged, &to_implicant_list(&1, num_vars))
            {acc_groups, unused_acc ++ converted_unmerged}
          end
        end)

      # Also add the last group if it wasn't processed
      last_key = Enum.max(group_keys)
      last_group_items = Map.get(grouped, last_key, [])

      # Check if last group had a next_group to compare with
      has_next = Map.has_key?(grouped, last_key + 1)

      unused_from_this_iteration =
        if has_next do
          unused_from_this_iteration
        else
          converted_last = Enum.map(last_group_items, &to_implicant_list(&1, num_vars))
          unused_from_this_iteration ++ converted_last
        end

      # If we generated new merged groups, recurse
      if map_size(next_groups) > 0 do
        regrouped = regroup_by_ones(next_groups)
        {prime_from_recursion, _} = find_prime_implicants(regrouped, num_vars)

        # Combine unused from this level with primes from recursion
        all_primes = (unused_from_this_iteration ++ prime_from_recursion) |> Enum.uniq()
        {all_primes, []}
      else
        # No merging happened at all, everything is a prime implicant
        all_primes =
          grouped
          |> Map.values()
          |> Enum.concat()
          |> Enum.map(&to_implicant_list(&1, num_vars))
          |> Enum.uniq()

        {all_primes, []}
      end
    end
  end

  # Compare and merge two groups of implicants
  # Returns {merged group, whether any merge occurred, unmerged implicants}
  defp compare_and_merge_groups(group1, group2, num_vars) do
    Enum.reduce(group1, {[], false, []}, fn implicant1, {merged_acc, merged_flag, unmerged_acc} ->
      {found_merge, new_mergeds} =
        Enum.reduce(group2, {false, []}, fn implicant2, {found, acc} ->
          case combine_implicants(
                 to_implicant_list(implicant1, num_vars),
                 to_implicant_list(implicant2, num_vars)
               ) do
            {:ok, combined} -> {true, [combined | acc]}
            :error -> {found, acc}
          end
        end)

      merged_acc_new = if found_merge, do: new_mergeds ++ merged_acc, else: merged_acc
      merged_flag_new = merged_flag || found_merge
      unmerged_acc_new = if found_merge, do: unmerged_acc, else: [implicant1 | unmerged_acc]

      {merged_acc_new, merged_flag_new, unmerged_acc_new}
    end)
  end

  defp to_implicant_list(implicant, num_vars) when is_integer(implicant),
    do: int_to_bits(implicant, num_vars)

  defp to_implicant_list(implicant, _num_vars) when is_list(implicant), do: implicant

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
  Given prime implicants and a list of minterms,
  build a coverage map from minterms to implicants covering them.
  """
  def coverage_table(prime_implicants, minterms, num_vars) do
    prime_implicants_list =
      Enum.map(prime_implicants, fn
        implicant when is_list(implicant) -> implicant
        n when is_integer(n) -> int_to_bits(n, num_vars)
      end)

    Enum.reduce(minterms, %{}, fn minterm, acc ->
      implicants_covering =
        Enum.filter(prime_implicants_list, fn implicant ->
          covers_minterm?(implicant, minterm, num_vars)
        end)

      Map.put(acc, minterm, implicants_covering)
    end)
  end

  defp covers_minterm?(implicant, minterm, num_vars) when is_list(implicant) do
    bits = int_to_bits(minterm, num_vars)

    Enum.zip(implicant, bits)
    |> Enum.all?(fn
      {:dont_care, _bit} -> true
      {val, bit} -> val == bit
    end)
  end
end
