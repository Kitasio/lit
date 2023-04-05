defmodule LitcoversWeb.ImageLive.FormComponent do
  use LitcoversWeb, :live_component

  alias Litcovers.Accounts.Feedback
  alias Litcovers.Accounts

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        <%= @title %>
        <:subtitle>
          <%= gettext(
            "Write what comes to mind in a free manner and a human being will definetly read it and make conclusions"
          ) %>
        </:subtitle>
      </.header>
      <.simple_form :let={f} for={@form} phx-target={@myself} phx-change="validate" phx-submit="save">
        <.input field={{f, :text}} type="textarea" label={gettext("Your feedback")} />
        <:actions>
          <.button><%= gettext("Send") %></.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def handle_event("validate", %{"feedback" => feedback_params}, socket) do
    IO.inspect(feedback_params)

    form =
      Accounts.change_feedback(%Feedback{}, feedback_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :form, form)}
  end

  def handle_event("save", %{"feedback" => feedback_params}, socket) do
    case Accounts.create_feedback(socket.assigns.current_user, feedback_params) do
      {:ok, _feedback} ->
        {:noreply,
         socket
         |> put_flash(:info, gettext("Thanks! Your feedback is submited"))
         |> push_navigate(to: ~p"/#{socket.assigns.locale}/images/new")}

      {:error, %Ecto.Changeset{} = form} ->
        {:noreply, assign(socket, form: form)}
    end
  end
end
