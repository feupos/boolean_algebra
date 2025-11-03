defmodule BooleanAlgebra.TruthTable do
  @moduledoc """
  Generates truth tables for boolean expressions.
  """

  alias BooleanAlgebra.AST

  import Bitwise

  @doc """
  Generates a truth table for the given boolean expression AST.

  The truth table lists all possible combinations of variable assignments and the resulting expression value.

  ### Variable Ordering

  - Variables are extracted from the AST in a fixed order (e.g., alphabetical or as returned by `AST.variables/1`).
  - In the generated table, the leftmost variable corresponds to the **most significant bit** in the binary counting,
    and the rightmost variable corresponds to the **least significant bit**.
  - The function iterates through integers from 0 to \(2^n - 1\) (where \(n\) is the number of variables),
    and each integer encodes a unique assignment of true/false values to variables:
    - The highest-order variable's value flips every half of the table rows (like the leftmost binary digit).
    - The lowest-order variable's value flips every single row (like the rightmost binary digit).

  ### Example

  Given `vars = ["a", "b", "c"]`, the truth table rows will be generated as follows (showing variable assignments only):

  | a     | b     | c     |
  |-------|-------|-------|
  | false | false | false |  # Corresponds to i = 0 (binary 000)
  | false | false | true  |  # i = 1 (binary 001)
  | false | true  | false |  # i = 2 (binary 010)
  | false | true  | true  |  # i = 3 (binary 011)
  | true  | false | false |  # i = 4 (binary 100)
  | true  | false | true  |  # i = 5 (binary 101)
  | true  | true  | false |  # i = 6 (binary 110)
  | true  | true  | true  |  # i = 7 (binary 111)

  Each row is a map with variable names as keys and their boolean values. The expression result will be included as the value of the `:result` key.

  """
  @spec from_ast(AST.t()) :: list(%{optional(String.t()) => boolean()})
  def from_ast(ast) do
    vars = AST.variables(ast)
    n = length(vars)

    # Generate all combinations of variable assignments.
    # The order of variables is fixed by AST.variables/1.
    # For i from 0 to 2^n - 1, interpret i as a binary number where
    #   - The leftmost variable corresponds to the most significant bit.
    #   - The rightmost variable corresponds to the least significant bit.
    for i <- 0..(Integer.pow(2, n) - 1) do
      assignment =
        vars
        |> Enum.with_index()
        |> Enum.map(fn {var, idx} ->
          # Extract the bit at position (n - 1 - idx), so leftmost var maps to highest bit.
          bit = i >>> (n - 1 - idx) &&& 1
          {var, bit == 1}
        end)
        |> Map.new()

      result = AST.eval(ast, assignment)
      Map.put(assignment, :result, result)
    end
  end
end
