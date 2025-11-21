defmodule BooleanAlgebraWeb.CoreComponentsTest do
  use BooleanAlgebraWeb.ConnCase, async: true
  use Phoenix.Component
  import Phoenix.LiveViewTest
  import BooleanAlgebraWeb.CoreComponents

  test "button renders correctly" do
    assigns = %{label: "Click me"}

    html =
      rendered_to_string(~H"""
      <.button>{@label}</.button>
      """)

    assert html =~ "Click me"
    assert html =~ "btn-primary"
  end

  test "input renders correctly" do
    assigns = %{form: to_form(%{"name" => "test"}, as: "test"), field: :name}

    html =
      rendered_to_string(~H"""
      <.input field={@form[:name]} />
      """)

    assert html =~ "name=\"test[name]\""
  end

  test "checkbox renders correctly" do
    assigns = %{form: to_form(%{"active" => true}, as: "user"), field: :active}

    html =
      rendered_to_string(~H"""
      <.input field={@form[:active]} type="checkbox" label="Active" />
      """)

    assert html =~ "type=\"checkbox\""
    assert html =~ "Active"
    assert html =~ "checked"
  end

  test "select renders correctly" do
    assigns = %{
      form: to_form(%{"role" => "admin"}, as: "user"),
      field: :role,
      options: ["admin", "user"]
    }

    html =
      rendered_to_string(~H"""
      <.input field={@form[:role]} type="select" options={@options} label="Role" />
      """)

    assert html =~ "select"
    assert html =~ "admin"
    assert html =~ "Role"
  end

  test "textarea renders correctly" do
    assigns = %{form: to_form(%{"bio" => "Hello"}, as: "user"), field: :bio}

    html =
      rendered_to_string(~H"""
      <.input field={@form[:bio]} type="textarea" label="Bio" />
      """)

    assert html =~ "textarea"
    assert html =~ "Hello"
    assert html =~ "Bio"
  end

  test "list renders correctly" do
    assigns = %{items: [%{title: "Item 1", description: "Desc 1"}]}

    html =
      rendered_to_string(~H"""
      <.list>
        <:item title="Title">Item Content</:item>
      </.list>
      """)

    assert html =~ "Title"
    assert html =~ "Item Content"
  end

  test "icon renders correctly" do
    assigns = %{name: "hero-home"}

    html =
      rendered_to_string(~H"""
      <.icon name={@name} />
      """)

    assert html =~ "hero-home"
  end

  test "header renders correctly" do
    assigns = %{title: "My Header"}

    html =
      rendered_to_string(~H"""
      <.header>
        {@title}
        <:subtitle>My Subtitle</:subtitle>
      </.header>
      """)

    assert html =~ "My Header"
    assert html =~ "My Subtitle"
  end

  test "flash renders correctly" do
    assigns = %{flash: %{"info" => "Success"}}

    html =
      rendered_to_string(~H"""
      <.flash kind={:info} title="Info" flash={@flash} />
      """)

    assert html =~ "Success"
    assert html =~ "Info"
  end

  test "table renders correctly" do
    assigns = %{rows: [%{id: 1, name: "Test"}]}

    html =
      rendered_to_string(~H"""
      <.table id="my-table" rows={@rows}>
        <:col :let={row} label="Name">{row.name}</:col>
      </.table>
      """)

    assert html =~ "Test"
    assert html =~ "Name"
  end
end
