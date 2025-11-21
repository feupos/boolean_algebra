defmodule BooleanAlgebraWeb.SimplifierLiveTest do
  use BooleanAlgebraWeb.ConnCase
  import Phoenix.LiveViewTest

  test "renders simplifier page", %{conn: conn} do
    {:ok, view, html} = live(conn, "/")
    assert html =~ "Boolean Algebra Simplifier"
    assert render(view) =~ "Boolean Expression"
  end

  test "simplifies valid expression", %{conn: conn} do
    {:ok, view, _html} = live(conn, "/")

    view
    |> form("form", %{"expression" => "a AND b"})
    |> render_submit()

    assert has_element?(view, "div", "Simplified Result")
    assert has_element?(view, "div", "a AND b")
  end

  test "shows error for invalid expression", %{conn: conn} do
    {:ok, view, _html} = live(conn, "/")

    view
    |> form("form", %{"expression" => "a AND OR b"})
    |> render_submit()

    assert has_element?(view, "h3", "Parsing Error")
  end

  test "switches tabs", %{conn: conn} do
    {:ok, view, _html} = live(conn, "/")

    # Submit valid expression first to populate data
    view
    |> form("form", %{"expression" => "a AND b"})
    |> render_submit()

    assert has_element?(view, "div", "Simplified Result")

    # Switch to Truth Table tab
    assert view
           |> element("button", "Truth Table")
           |> render_click() =~ "Result"

    # Switch to Steps tab
    assert view
           |> element("button", "Detailed Steps (QMC)")
           |> render_click() =~ "Initial Grouping"
  end

  test "changes output format", %{conn: conn} do
    {:ok, view, _html} = live(conn, "/")

    view
    |> form("form", %{"expression" => "a AND b"})
    |> render_submit()

    # Default is Word (AND)
    assert has_element?(view, "div", "a AND b")

    # Switch to Symbolic
    view
    |> element("button", "Symbolic (&)")
    |> render_click()

    # Must submit again to apply format
    view
    |> form("form", %{"expression" => "a AND b"})
    |> render_submit()

    assert has_element?(view, "div", "a & b")
  end
end
