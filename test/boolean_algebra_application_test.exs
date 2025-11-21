defmodule BooleanAlgebra.ApplicationTest do
  use ExUnit.Case
  alias BooleanAlgebra.Application

  test "config_change returns :ok" do
    assert Application.config_change([], [], []) == :ok
  end
end
