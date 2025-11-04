defmodule BooleanAlgebraWeb.SimplifierLive do
  use BooleanAlgebraWeb, :live_view
  alias BooleanAlgebra

  def mount(_params, _session, socket) do
    {:ok, assign(socket, input: "", simplified: "", truth_table: [])}
  end

  def handle_event("update_input", %{"expression" => expr}, socket) do
    try do
      {:noreply,
       assign(socket,
         input: expr,
         simplified: BooleanAlgebra.simplify(expr),
         truth_table: BooleanAlgebra.truth_table(expr)
       )}
    rescue
      _ ->
        {:noreply, assign(socket, input: expr, simplified: "Invalid expression", truth_table: [])}
    end
  end
end
