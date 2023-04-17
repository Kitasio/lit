defmodule LitcoversWeb.ImageLive.ChatComponent do
  alias Litcovers.Metadata.UserChatMessage
  use LitcoversWeb, :live_component

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        <%= @title %>
        <:subtitle>
          <%= gettext("Describe what you would like to add, change or remove in the image.") %>
        </:subtitle>
      </.header>
      <.simple_form :let={f} for={@form} phx-target={@myself} phx-change="validate" phx-submit="save">
        <.input
          field={{f, :preserve_composition}}
          type="checkbox"
          label={gettext("Preserve composition")}
          id={"comp-#{@image_id}-checkbox"}
        />
        <.input field={{f, :content}} label={gettext("Message")} id={"content-#{@image_id}-input"} />
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
    composition = Map.get(chat_params, "preserve_composition")

    socket =
      push_navigate(socket,
        to:
          ~p"/#{socket.assigns.locale}/images/new/#{socket.assigns.image_id}/correct?message=#{message}&composition=#{composition}"
      )

    {:noreply, socket}
  end
end
