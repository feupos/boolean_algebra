defmodule BooleanAlgebraWeb.RouterTest do
  use BooleanAlgebraWeb.ConnCase

  test "browser pipeline is covered", %{conn: conn} do
    # We can't easily test the pipeline plugs directly without a route,
    # but accessing the root route exercises the browser pipeline.
    conn = get(conn, ~p"/")
    assert html_response(conn, 200)
  end
end
