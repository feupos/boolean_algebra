defmodule BooleanAlgebraWeb.SimplifierLive do
  use BooleanAlgebraWeb, :live_view
  alias BooleanAlgebra
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
       loading: false,
       contact_subject: "",
       contact_message: "",
       mailto_link: "mailto:fneves@alunos.utfpr.edu.br?subject=Boolean%20Algebra%20Support"
     )}
  end

  def handle_event("update_input", %{"expression" => expr}, socket) do
    {:noreply, assign(socket, input: expr)}
  end

  def handle_event("simplify", %{"expression" => expr}, socket) do
    send(self(), {:run_simplification, expr})
    {:noreply, assign(socket, loading: true, input: expr)}
  end

  def handle_event("set_tab", %{"tab" => tab}, socket) do
    {:noreply, assign(socket, active_tab: String.to_existing_atom(tab))}
  end

  def handle_event("set_example", %{"example" => example}, socket) do
    {:noreply, assign(socket, input: example, error: nil)}
  end

  def handle_event("update_contact_form", %{"subject" => subject, "message" => message}, socket) do
    subject_part = if subject == "", do: "Boolean Algebra Support", else: subject

    body = "Source: Boolean Algebra Website\n\n" <> message

    params = %{
      "subject" => subject_part,
      "body" => body
    }

    query = URI.encode_query(params)
    link = "mailto:fneves@alunos.utfpr.edu.br?#{query}"

    {:noreply, assign(socket, contact_subject: subject, contact_message: message, mailto_link: link)}
  end



  def handle_info({:run_simplification, expr}, socket) do
    simplify(socket, expr)
  end

  defp simplify(socket, expr) do
    # Clear error when input is empty
    if String.trim(expr) == "" do
      {:noreply,
       assign(socket,
         input: expr,
         simplified: "",
         details: nil,
         truth_table: [],
         error: nil,
         loading: false
       )}
    else
      case BooleanAlgebra.process(expr, operators: :symbolic, parentheses: :minimal) do
        {:ok, result} ->
          {:noreply,
           assign(socket,
             input: expr,
             simplified: result.simplification,
             details: result.details,
             truth_table: result.truth_table,
             error: nil,
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
             loading: false
           )}
      end
    end
  end
end
