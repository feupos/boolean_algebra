defmodule BooleanAlgebraWeb.SimplifierLive do
  use BooleanAlgebraWeb, :live_view
  alias BooleanAlgebra

  def mount(_params, _session, socket) do
    {:ok,
     assign(socket,
       input: "",
       simplified: "",
       details: nil,
       truth_table: [],
       error: nil,
       active_tab: :simplification,
       format: :word,
       loading: false
     )}
  end

  def handle_event("update_input", %{"expression" => expr}, socket) do
    {:noreply, assign(socket, input: expr)}
  end

  def handle_event("simplify", %{"expression" => expr}, socket) do
    send(self(), {:run_simplification, expr, socket.assigns.format})
    {:noreply, assign(socket, loading: true, input: expr)}
  end

  def handle_event("set_tab", %{"tab" => tab}, socket) do
    {:noreply, assign(socket, active_tab: String.to_existing_atom(tab))}
  end

  def handle_event("set_format", %{"format" => format}, socket) do
    format_atom = String.to_existing_atom(format)
    {:noreply, assign(socket, format: format_atom)}
  end

  def handle_info({:run_simplification, expr, format}, socket) do
    simplify(socket, expr, format)
  end

  defp simplify(socket, expr, format) do
    # Clear error when input is empty
    if String.trim(expr) == "" do
      {:noreply,
       assign(socket,
         input: expr,
         simplified: "",
         details: nil,
         truth_table: [],
         error: nil,
         format: format,
         loading: false
       )}
    else
      case BooleanAlgebra.simplify_with_details(expr, operators: format) do
        {:ok, simplified, details} ->
          truth_table =
            try do
              BooleanAlgebra.truth_table(expr)
            rescue
              _ -> []
            end

          {:noreply,
           assign(socket,
             input: expr,
             simplified: simplified,
             details: details,
             truth_table: truth_table,
             error: nil,
             format: format,
             loading: false
           )}

        {:error, reason} ->
          {:noreply,
           assign(socket,
             input: expr,
             simplified: "",
             details: nil,
             truth_table: [],
             error: reason,
             format: format,
             loading: false
           )}
      end
    end
  end
end
