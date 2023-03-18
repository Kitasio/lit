defmodule LitcoversWeb.UserConfirmationInstructionsLive do
  use LitcoversWeb, :live_view

  alias Litcovers.Accounts

  def mount(%{"locale" => locale}, _session, socket) do
    Gettext.put_locale(locale)
    {:ok, assign(socket, locale: locale)}
  end

  def handle_event("send_instructions", %{"user" => %{"email" => email}}, socket) do
    if user = Accounts.get_user_by_email(email) do
      Accounts.deliver_user_confirmation_instructions(
        user,
        &url(~p"/#{socket.assigns.locale}/users/confirm/#{&1}")
      )
    end

    info =
      gettext(
        "If your email is in our system and it has not been confirmed yet, you will receive an email with instructions shortly."
      )

    {:noreply,
     socket
     |> put_flash(:info, info)
     |> redirect(to: ~p"/")}
  end

  def render(assigns) do
    ~H"""
    <.navbar
      locale={@locale}
      current_user={@current_user}
      show_bottom_links={false}
      request_path={"/#{@locale}/users/confirm"}
    />
    <div class="mt-10 p-7 max-w-2xl mx-auto">
      <h1 class="text-2xl md:text-4xl font-semibold text-center">
        <%= gettext("We sent confirmation instructions to your email address") %>
      </h1>
    </div>
    <div class="bg-main p-10 my-5 lg:my-20 mx-auto max-w-md rounded-lg sm:border-2 border-stroke-main">
      <.header><%= gettext("Resend confirmation instructions") %></.header>

      <.simple_form :let={f} for={:user} id="resend_confirmation_form" phx-submit="send_instructions">
        <.input field={{f, :email}} type="email" label={gettext("Email")} required />
        <:actions>
          <.button phx-disable-with={gettext("Sending...")} class="w-full">
            <%= gettext("Send") %>
          </.button>
        </:actions>
      </.simple_form>

      <p class="mt-5 text-center">
        <.link href={~p"/#{@locale}/users/register"}><%= gettext("Register") %></.link>
        | <.link href={~p"/#{@locale}/users/log_in"}><%= gettext("Log in") %></.link>
      </p>
    </div>
    """
  end
end
