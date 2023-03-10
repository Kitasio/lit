defmodule LitcoversWeb.UserResetPasswordLive do
  use LitcoversWeb, :live_view

  alias Litcovers.Accounts

  def render(assigns) do
    ~H"""
    <.navbar locale={@locale} request_path={"/#{@locale}/users/reset_password"} />
    <div class="p-10 pt-2 sm:my-5 lg:my-20 mx-auto w-full max-w-md rounded-lg sm:border-2 border-stroke-main">
      <.header class="text-center pt-5"><%= gettext("Reset Password") %></.header>

      <.simple_form
        :let={f}
        for={@changeset}
        id="reset_password_form"
        phx-submit="reset_password"
        phx-change="validate"
      >
        <.error :if={@changeset.action == :insert}>
          <%= gettext("Oops, something went wrong! Please check the errors below.") %>
        </.error>

        <.input field={{f, :password}} type="password" label={gettext("New password")} required />
        <.input
          field={{f, :password_confirmation}}
          type="password"
          label={gettext("Confirm new password")}
          required
        />
        <:actions>
          <.button phx-disable-with={gettext("Resetting...")} class="w-full">
            <%= gettext("Reset Password") %>
          </.button>
        </:actions>
      </.simple_form>

      <p class="text-center mt-4">
        <.link href={~p"/#{@locale}/users/register"}><%= gettext("Register") %></.link>
        |
        <.link href={~p"/#{@locale}/users/log_in"}><%= gettext("Log in") %></.link>
      </p>
    </div>
    """
  end

  def mount(params, _session, socket) do
    locale = params["locale"]
    Gettext.put_locale(locale)
    socket = assign(socket, locale: locale)
    socket = assign_user_and_token(socket, params)

    socket =
      case socket.assigns do
        %{user: user} ->
          assign(socket, :changeset, Accounts.change_user_password(user))

        _ ->
          socket
      end

    {:ok, socket, temporary_assigns: [changeset: nil]}
  end

  # Do not log in the user after reset password to avoid a
  # leaked token giving the user access to the account.
  def handle_event("reset_password", %{"user" => user_params}, socket) do
    case Accounts.reset_user_password(socket.assigns.user, user_params) do
      {:ok, _} ->
        {:noreply,
         socket
         |> put_flash(:info, gettext("Password reset successfully."))
         |> redirect(to: ~p"/#{socket.assigns.locale}/users/log_in")}

      {:error, changeset} ->
        {:noreply, assign(socket, :changeset, Map.put(changeset, :action, :insert))}
    end
  end

  def handle_event("validate", %{"user" => user_params}, socket) do
    changeset = Accounts.change_user_password(socket.assigns.user, user_params)
    {:noreply, assign(socket, changeset: Map.put(changeset, :action, :validate))}
  end

  defp assign_user_and_token(socket, %{"token" => token}) do
    if user = Accounts.get_user_by_reset_password_token(token) do
      assign(socket, user: user, token: token)
    else
      socket
      |> put_flash(:error, gettext("Reset password link is invalid or it has expired."))
      |> redirect(to: ~p"/")
    end
  end
end
