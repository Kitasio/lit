defmodule LitcoversWeb.ImageLive.FormComponent do
  use LitcoversWeb, :live_component

  alias Litcovers.Media

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        <%= @title %>
        <:subtitle>Use this form to manage image records in your database.</:subtitle>
      </.header>

      <.simple_form
        :let={f}
        for={@changeset}
        id="image-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={{f, :url}} type="text" label="Url" />
        <.input field={{f, :description}} type="text" label="Description" />
        <.input field={{f, :completed}} type="checkbox" label="Completed" />
        <.input field={{f, :width}} type="number" label="Width" />
        <.input field={{f, :height}} type="number" label="Height" />
        <.input field={{f, :prompt}} type="text" label="Prompt" />
        <.input field={{f, :character_gender}} type="text" label="Character gender" />
        <:actions>
          <.button phx-disable-with="Saving...">Save Image</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{image: image} = assigns, socket) do
    changeset = Media.change_image(image)

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:changeset, changeset)}
  end

  @impl true
  def handle_event("validate", %{"image" => image_params}, socket) do
    changeset =
      socket.assigns.image
      |> Media.change_image(image_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :changeset, changeset)}
  end

  def handle_event("save", %{"image" => image_params}, socket) do
    save_image(socket, socket.assigns.action, image_params)
  end

  defp save_image(socket, :edit, image_params) do
    case Media.update_image(socket.assigns.image, image_params) do
      {:ok, _image} ->
        {:noreply,
         socket
         |> put_flash(:info, "Image updated successfully")
         |> push_navigate(to: socket.assigns.navigate)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :changeset, changeset)}
    end
  end

  # defp save_image(socket, :new, image_params) do
  #   case Media.create_image(image_params) do
  #     {:ok, _image} ->
  #       {:noreply,
  #        socket
  #        |> put_flash(:info, "Image created successfully")
  #        |> push_navigate(to: socket.assigns.navigate)}
  #
  #     {:error, %Ecto.Changeset{} = changeset} ->
  #       {:noreply, assign(socket, changeset: changeset)}
  #   end
  # end
end
