defmodule LitcoversWeb.UserConfirmationLive do
  use LitcoversWeb, :live_view

  alias Litcovers.Accounts

  def render(%{live_action: :edit} = assigns) do
    ~H"""
    <.navbar locale={@locale} request_path={"/#{@locale}/users/confirm"} />
    <div class="p-10 pt-2 sm:my-5 lg:my-20 mx-auto max-w-md">
      <.simple_form :let={f} for={:user} id="confirmation_form" phx-submit="confirm_account">
        <.input field={{f, :token}} type="hidden" value={@token} />
        <:actions>
          <.button phx-disable-with={gettext("Confirming...")} class="w-full">
            <%= gettext("Confirm my account") %>
          </.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  def mount(params, _session, socket) do
    Gettext.put_locale(params["locale"])

    {:ok, assign(socket, token: params["token"], locale: params["locale"]),
     temporary_assigns: [token: nil]}
  end

  # Do not log in the user after confirmation to avoid a
  # leaked token giving the user access to the account.
  def handle_event("confirm_account", %{"user" => %{"token" => token}}, socket) do
    case Accounts.confirm_user(token) do
      {:ok, _} ->
        {:noreply,
         socket
         |> put_flash(:info, gettext("User confirmed successfully."))
         |> redirect(to: ~p"/#{socket.assigns.locale}/images/new")}

      :error ->
        # If there is a current user and the account was already confirmed,
        # then odds are that the confirmation link was already visited, either
        # by some automation or by the user themselves, so we redirect without
        # a warning message.
        case socket.assigns do
          %{current_user: %{confirmed_at: confirmed_at}} when not is_nil(confirmed_at) ->
            {:noreply, redirect(socket, to: ~p"/#{socket.assigns.locale}/")}

          %{} ->
            {:noreply,
             socket
             |> put_flash(:error, gettext("User confirmation link is invalid or it has expired."))
             |> redirect(to: ~p"/#{socket.assigns.locale}/")}
        end
    end
  end
end
