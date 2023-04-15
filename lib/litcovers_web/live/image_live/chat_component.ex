defmodule LitcoversWeb.ImageLive.ChatComponent do
  alias Litcovers.Metadata.UserChatMessage
  use LitcoversWeb, :live_component

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        <%= @title %>
      </.header>
      <.simple_form :let={f} for={@form} phx-target={@myself} phx-change="validate" phx-submit="save">
        <.input field={{f, :content}} label="Message" />
        <:actions>
          <.button><%= gettext("Send") %></.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def handle_event("validate", %{"user_chat_message" => chat_params}, socket) do
    form =
      UserChatMessage.changeset(%UserChatMessage{}, chat_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :form, form)}
  end

  def handle_event("save", %{"user_chat_message" => chat_params}, socket) do
    message = Map.get(chat_params, "content")

    socket =
      push_navigate(socket,
        to:
          ~p"/#{socket.assigns.locale}/images/new/#{socket.assigns.image_id}/redo?message=#{message}"
      )

    {:noreply, socket}
  end
end
