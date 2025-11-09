defmodule BooleanAlgebra.QMC do
  @moduledoc """
  Quine-McCluskey implementation for Boolean minimization.

  The main function `minimize/2` takes a list of minterms as integers and the number of boolean variables.
  It returns a list of prime implicants expressed as strings using '1', '0', and '-' to represent don't-care bits.
  """

  import Bitwise

  @doc """
  Minimize the boolean function represented by the given minterms and number of variables.

  Returns a list of prime implicant strings (e.g. ["1-0", "0-1"]).
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

  # Converts bits list to string representation ('1', '0', '-')
  defp bits_to_string(bits) do
    Enum.map_join(bits, fn
      true -> "1"
      false -> "0"
      :dash -> "-"
    end)
  end

  # Combines two implicants if they differ in exactly one bit, marking that bit as '-'
  def combine_implicants(imp1, imp2) do
    bits1 = String.graphemes(imp1)
    bits2 = String.graphemes(imp2)

    {diff_count, combined_bits} =
      Enum.zip(bits1, bits2)
      |> Enum.reduce({0, []}, fn
        {b, b}, {count, acc} -> {count, acc ++ [b]}
        {_b1, _b2}, {0, acc} -> {1, acc ++ ["-"]}
        {_b1, _b2}, {count, acc} -> {count + 10, acc}
      end)

    if diff_count == 1 do
      {:ok, Enum.join(combined_bits)}
    else
      :error
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
    group_keys = Map.keys(grouped) |> Enum.sort()

    {next_groups, merged_any, unused_implicants} =
      Enum.reduce(group_keys, {%{}, false, []}, fn key, {acc_groups, merged_acc, unused_acc} ->
        current_group = Map.get(grouped, key, [])
        next_group = Map.get(grouped, key + 1, [])

        {merged_group, merged_flag, unmerged} =
          compare_and_merge_groups(current_group, next_group, num_vars)

        new_groups = Map.update(acc_groups, key, merged_group, &(merged_group ++ &1))
        {new_groups, merged_acc || merged_flag, unused_acc ++ unmerged}
      end)

    last_group = Map.get(grouped, Enum.max(group_keys), [])
    unused_implicants = unused_implicants ++ last_group

    if merged_any do
      regrouped = regroup_by_ones(next_groups)
      find_prime_implicants(regrouped, num_vars)
    else
      prime_implicants =
        unused_implicants
        |> Enum.uniq()

      {prime_implicants, []}
    end
  end

  # Compare and merge two groups of implicants
  # Returns {merged group, whether any merge occurred, unmerged implicants}
  # Added num_vars for proper string conversion
  defp compare_and_merge_groups(group1, group2, num_vars) do
    Enum.reduce(group1, {[], false, []}, fn implicant1, {merged_acc, merged_flag, unmerged_acc} ->
      {found_merge, new_mergeds} =
        Enum.reduce(group2, {false, []}, fn implicant2, {found, acc} ->
          case combine_implicants(
                 to_implicant_string(implicant1, num_vars),
                 to_implicant_string(implicant2, num_vars)
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

  defp to_implicant_string(implicant, num_vars) when is_integer(implicant),
    do: bits_to_string(int_to_bits(implicant, num_vars))

  defp to_implicant_string(implicant, _num_vars) when is_binary(implicant), do: implicant

  # Regroup merged implicants by number of 1s (ignoring '-' bits)
  defp regroup_by_ones(implicants_map) do
    implicants_map
    |> Map.values()
    |> List.flatten()
    |> Enum.group_by(&count_ones_in_string/1)
  end

  defp count_ones_in_string(implicant_str) do
    String.graphemes(implicant_str)
    |> Enum.count(fn c -> c == "1" end)
  end

  @doc """
  Given prime implicants (strings) and a list of minterms,
  build a coverage map from minterms to implicants covering them.
  """
  def coverage_table(prime_implicants, minterms, num_vars) do
    prime_implicants_str =
      Enum.map(prime_implicants, fn
        s when is_binary(s) -> s
        n when is_integer(n) -> bits_to_string(int_to_bits(n, num_vars))
      end)

    Enum.reduce(minterms, %{}, fn minterm, acc ->
      implicants_covering =
        Enum.filter(prime_implicants_str, fn implicant -> covers_minterm?(implicant, minterm) end)

      Map.put(acc, minterm, implicants_covering)
    end)
  end

  # Check if implicant covers the minterm; implicant is string like "1-0",
  # minterm is integer, convert minterm to bitstring for comparison
  defp covers_minterm?(implicant, minterm) do
    bits = bits_to_string(int_to_bits(minterm, String.length(implicant)))

    Enum.zip(String.graphemes(implicant), String.graphemes(bits))
    |> Enum.all?(fn
      {"-", _bit} -> true
      {char, bit} -> char == bit
    end)
  end
end
