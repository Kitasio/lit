defmodule LitcoversWeb.PlaceholderLive.FormComponent do
  use LitcoversWeb, :live_component

  alias Litcovers.Metadata

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        <%= @title %>
        <:subtitle>Use this form to manage placeholder records in your database.</:subtitle>
      </.header>

      <.simple_form
        :let={f}
        for={@changeset}
        id="placeholder-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={{f, :author}} type="text" label="Author" />
        <.input field={{f, :title}} type="text" label="Title" />
        <.input field={{f, :description}} type="text" label="Description" />
        <:actions>
          <.button phx-disable-with="Saving...">Save Placeholder</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{placeholder: placeholder} = assigns, socket) do
    changeset = Metadata.change_placeholder(placeholder)

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:changeset, changeset)}
  end

  @impl true
  def handle_event("validate", %{"placeholder" => placeholder_params}, socket) do
    changeset =
      socket.assigns.placeholder
      |> Metadata.change_placeholder(placeholder_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :changeset, changeset)}
  end

  def handle_event("save", %{"placeholder" => placeholder_params}, socket) do
    save_placeholder(socket, socket.assigns.action, placeholder_params)
  end

  defp save_placeholder(socket, :edit, placeholder_params) do
    case Metadata.update_placeholder(socket.assigns.placeholder, placeholder_params) do
      {:ok, _placeholder} ->
        {:noreply,
         socket
         |> put_flash(:info, "Placeholder updated successfully")
         |> push_navigate(to: socket.assigns.navigate)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :changeset, changeset)}
    end
  end

  defp save_placeholder(socket, :new, placeholder_params) do
    case Metadata.create_placeholder(placeholder_params) do
      {:ok, _placeholder} ->
        {:noreply,
         socket
         |> put_flash(:info, "Placeholder created successfully")
         |> push_navigate(to: socket.assigns.navigate)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
    end
  end
end
