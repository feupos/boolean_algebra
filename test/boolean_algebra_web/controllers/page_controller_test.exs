defmodule BooleanAlgebraWeb.SimplifierLiveTest do
  use BooleanAlgebraWeb.ConnCase
  import Phoenix.LiveViewTest

  test "mounts with default assigns", %{conn: conn} do
    {:ok, _view, html} = live(conn, "/")

    assert html =~ "Boolean Expression Simplifier"
  end

  test "updates simplification and truth table on valid input", %{conn: conn} do
    {:ok, view, _html} = live(conn, "/")

    expr = "a AND b"
    # Trigger the update_input event, simulating form submission
    view
    |> form("form", expression: expr)
    |> render_submit()

    assert render(view) =~ ~r/a\s*&amp;\s*b/
  end

  test "shows invalid expression message on error", %{conn: conn} do
    {:ok, view, _html} = live(conn, "/")
    invalid_expr = "and or ||"

    view
    |> form("form", expression: invalid_expr)
    |> render_submit()

    assert render(view) =~ "Invalid expression"
  end
end
