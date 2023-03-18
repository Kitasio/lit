defmodule LitcoversWeb.UserLoginLive do
  use LitcoversWeb, :live_view

  def mount(%{"locale" => locale}, _session, socket) do
    Gettext.put_locale(locale)
    email = live_flash(socket.assigns.flash, :email)
    {:ok, assign(socket, email: email, locale: locale), temporary_assigns: [email: nil]}
  end

  def render(assigns) do
    ~H"""
    <.navbar locale={@locale} request_path={"/#{@locale}/users/log_in"} />
    <div class="bg-main p-10 sm:my-5 lg:my-20 mx-auto max-w-md rounded-lg sm:border-2 border-stroke-main">
      <.header class="text-center">
        <%= gettext("Sign in to account") %>
        <:subtitle>
          <%= gettext("Don't have an account?") %>
          <.link
            navigate={~p"/#{@locale}/users/register"}
            class="font-semibold text-accent-main hover:underline"
          >
            <%= gettext("Sign up") %>
          </.link>
          <%= gettext("for an account now.") %>
        </:subtitle>
      </.header>

      <.simple_form
        :let={f}
        id="login_form"
        for={:user}
        action={~p"/#{@locale}/users/log_in"}
        as={:user}
        phx-update="ignore"
      >
        <.input field={{f, :email}} type="email" label={gettext("Email")} required />
        <.input field={{f, :password}} type="password" label={gettext("Password")} required />

        <:actions :let={f}>
          <.input field={{f, :remember_me}} type="checkbox" label={gettext("Remember me")} />
          <.link href={~p"/#{@locale}/users/reset_password"} class="text-sm font-semibold">
            <%= gettext("Forgot your password?") %>
          </.link>
        </:actions>
        <:actions>
          <.button phx-disable-with={gettext("Signing in...")} class="w-full">
            <%= gettext("Sign in") %> <span aria-hidden="true">→</span>
          </.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end
end
