ExUnit.start()

defmodule BooleanAlgebraTest do
  use ExUnit.Case, async: true

  @valid_samples [
    "a",
    "!a",
    "a & b",
    "a | b",
    "(a | b) & !c"
  ]

  @invalid_samples [
    "",
    "a & ",
    "!(a | b",
    "a & b |"
  ]

  test "simplify returns a binary and is idempotent" do
    for input <- @valid_samples do
      simplified = BooleanAlgebra.simplify(input)
      assert is_binary(simplified)
      assert BooleanAlgebra.simplify(simplified) == simplified
    end
  end

  test "eval returns a boolean and agrees with simplified input" do
    vars = %{a: true, b: false, c: true}

    for input <- @valid_samples do
      val_original = BooleanAlgebra.eval(input, vars)
      val_simplified = BooleanAlgebra.eval(BooleanAlgebra.simplify(input), vars)

      assert val_original in [true, false]
      assert val_original == val_simplified
    end
  end

  test "handle invalid inputs gracefully" do
    for input <- @invalid_samples do
      assert_raise ArgumentError, fn ->
        BooleanAlgebra.simplify(input)
      end

      assert_raise ArgumentError, fn ->
        BooleanAlgebra.eval(input, {})
      end

      assert_raise ArgumentError, fn ->
        BooleanAlgebra.eval(input)
      end

      assert_raise ArgumentError, fn ->
        BooleanAlgebra.truth_table(input)
      end
    end
  end

  test "truth_table returns a list of maps with correct keys" do
    input = "(a & b) | c"
    table = BooleanAlgebra.truth_table(input)

    assert is_list(table)
    assert length(table) == 8

    for row <- table do
      assert is_map(row)
      assert Map.keys(row) |> Enum.sort() == [:a, :b, :c, :result]
      assert row.result in [true, false]
    end
  end

  test "simplify_with_details returns steps for valid expression" do
    input = "a AND b OR a AND c"
    assert {:ok, simplified, details} = BooleanAlgebra.simplify_with_details(input)

    assert is_binary(simplified)
    assert is_map(details)
    assert Map.has_key?(details, :qmc_steps)
    assert Map.has_key?(details, :prime_implicants)

    qmc_steps = details.qmc_steps
    assert is_list(qmc_steps)
    assert length(qmc_steps) > 0

    first_step = List.first(qmc_steps)
    assert first_step.type == :grouping
  end

  test "simplify_with_details returns error for invalid expression" do
    input = "a AND OR b"
    assert {:error, reason} = BooleanAlgebra.simplify_with_details(input)
    assert is_binary(reason)
  end
end
