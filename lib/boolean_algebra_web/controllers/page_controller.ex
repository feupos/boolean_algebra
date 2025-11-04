defmodule BooleanAlgebraWeb.PageController do
  use BooleanAlgebraWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
