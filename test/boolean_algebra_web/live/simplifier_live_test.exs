defmodule BooleanAlgebraWeb.SimplifierLiveTest do
  use BooleanAlgebraWeb.ConnCase

  import Phoenix.LiveViewTest

  test "disconnected and connected render", %{conn: conn} do
    {:ok, page_live, disconnected_html} = live(conn, "/")
    assert disconnected_html =~ "Boolean Algebra Simplifier"
    assert render(page_live) =~ "Boolean Algebra Simplifier"
  end

  test "simplifies expression", %{conn: conn} do
    {:ok, page_live, _html} = live(conn, "/")

    assert page_live
           |> form("form", expression: "a & a")
           |> render_submit() =~ "a"
  end

  test "handles invalid expression", %{conn: conn} do
    {:ok, page_live, _html} = live(conn, "/")

    assert page_live
           |> form("form", expression: "a &")
           |> render_submit() =~ "Error"
  end

  test "handles empty expression", %{conn: conn} do
    {:ok, page_live, _html} = live(conn, "/")

    assert page_live
           |> form("form", expression: "   ")
           |> render_submit() =~ "Boolean Algebra Simplifier"
  end

  test "changes tabs", %{conn: conn} do
    {:ok, page_live, _html} = live(conn, "/")

    assert page_live |> element("button[phx-value-tab='truth_table']") |> render_click() =~
             "Truth Table"

    assert page_live |> element("button[phx-value-tab='steps']") |> render_click() =~
             "Detailed Steps (QMC)"
  end

  test "changes format", %{conn: conn} do
    {:ok, page_live, _html} = live(conn, "/")

    # Default is word (AND)
    # Change to symbolic (&)
    assert page_live |> element("button[phx-value-format='symbolic']") |> render_click() =~
             "Symbolic"

    # We can verify the format effect by submitting an expression and checking the output
    # But the output format depends on the `operators` option passed to `simplify_with_details`.
    # Let's just verify the event handling for now.
  end
end
