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

  test "sets example expression", %{conn: conn} do
    {:ok, page_live, _html} = live(conn, "/")

    assert page_live
           |> element("button[phx-click='set_example'][phx-value-example='!(A & B)']")
           |> render_click() =~ "!(A &amp; B)"
  end
end
