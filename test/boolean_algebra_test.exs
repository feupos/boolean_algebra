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
      {:ok, val_original} = BooleanAlgebra.eval(input, vars)
      {:ok, val_simplified} = BooleanAlgebra.eval(BooleanAlgebra.simplify(input), vars)

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
    end
  end
end
