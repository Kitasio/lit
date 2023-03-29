defmodule LitcoversWeb.UserForgotPasswordLive do
  use LitcoversWeb, :live_view

  alias Litcovers.Accounts

  def render(assigns) do
    ~H"""
    <.navbar locale={@locale} request_path={"/#{@locale}/users/reset_password"} />
    <div class="bg-main p-10 pt-2 sm:my-5 lg:my-20 mx-auto max-w-md rounded-lg sm:border-2 border-stroke-main">
      <.header class="text-center mt-5">
        <%= gettext("Forgot your password?") %>
        <:subtitle><%= gettext("We'll send a password reset link to your inbox") %></:subtitle>
      </.header>

      <.simple_form :let={f} id="reset_password_form" for={:user} phx-submit="send_email">
        <.input field={{f, :email}} type="email" placeholder="Email" required />
        <:actions>
          <.button phx-disable-with={gettext("Sending...")} class="w-full">
            <%= gettext("Send password reset instructions") %>
          </.button>
        </:actions>
      </.simple_form>
      <p class="text-center mt-4">
        <.link href={~p"/#{@locale}/users/register"}><%= gettext("Register") %></.link>
        | <.link href={~p"/#{@locale}/users/log_in"}><%= gettext("Log in") %></.link>
      </p>
    </div>
    """
  end

  def mount(%{"locale" => locale}, _session, socket) do
    Gettext.put_locale(locale)
    {:ok, assign(socket, locale: locale)}
  end

  def handle_event("send_email", %{"user" => %{"email" => email}}, socket) do
    if user = Accounts.get_user_by_email(email) do
      Accounts.deliver_user_reset_password_instructions(
        user,
        socket.assigns.locale,
        &url(~p"/#{socket.assigns.locale}/users/reset_password/#{&1}")
      )
    end

    info =
      gettext(
        "If your email is in our system, you will receive instructions to reset your password shortly."
      )

    {:noreply,
     socket
     |> put_flash(:info, info)
     |> redirect(to: ~p"/")}
  end
end
