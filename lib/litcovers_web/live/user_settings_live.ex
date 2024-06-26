defmodule LitcoversWeb.UserSettingsLive do
  use LitcoversWeb, :live_view

  alias Litcovers.Accounts

  def render(assigns) do
    ~H"""
    <.navbar
      locale={@locale}
      request_path={"/#{@locale}/users/settings"}
      current_user={@current_user}
      show_bottom_links={false}
    />

    <div
      x-data="{
        changeEmail: false,
        changePassword: false
      }"
      class="bg-main my-10 rounded-xl w-full px-7 max-w-screen-sm mx-auto"
    >
      <.simple_form
        :let={f}
        id="email_form"
        for={@email_changeset}
        phx-submit="update_email"
        phx-change="validate_email"
      >
        <.error :if={@email_changeset.action == :insert}>
          <%= gettext("Oops, something went wrong! Please check the errors below.") %>
        </.error>

        <.input field={{f, :email}} class="bg-transparent" type="email" label="Email" required />

        <.input
          field={{f, :current_password}}
          name="current_password"
          id="current_password_for_email"
          type="password"
          label={gettext("Current password")}
          value={@email_form_current_password}
          required
        />
        <:actions>
          <.button phx-disable-with="Changing..."><%= gettext("Change Email") %></.button>
        </:actions>
      </.simple_form>

      <.header class="mt-10"><%= gettext("Change Password") %></.header>

      <.simple_form
        :let={f}
        id="password_form"
        for={@password_changeset}
        action={~p"/#{@locale}/users/log_in?_action=password_updated"}
        method="post"
        phx-change="validate_password"
        phx-submit="update_password"
        phx-trigger-action={@trigger_submit}
      >
        <.error :if={@password_changeset.action == :insert}>
          <%= gettext("Oops, something went wrong! Please check the errors below.") %>
        </.error>

        <.input field={{f, :email}} type="hidden" value={@current_email} />

        <.input field={{f, :password}} type="password" label={gettext("New password")} required />
        <.input
          field={{f, :password_confirmation}}
          type="password"
          label={gettext("Confirm new password")}
        />
        <.input
          field={{f, :current_password}}
          name="current_password"
          type="password"
          label={gettext("Current password")}
          id="current_password_for_password"
          value={@current_password}
          required
        />
        <:actions>
          <.button phx-disable-with="Changing..."><%= gettext("Change Password") %></.button>
        </:actions>
      </.simple_form>

      <.header class="mt-10"><%= gettext("API Tokens") %></.header>
      <div class="my-5 w-full flex flex-col items-start">
        <.button phx-click="create_user_api_token" phx-disable-with="Creating..."><%= gettext("Create API Token") %></.button>
        <pre class="mt-5"><%= @api_token %></pre>
      </div>

      <div class="my-10 w-full flex justify-center">
        <.link href={~p"/#{@locale}/users/log_out"} method="delete">
          <%= gettext("Log out") %>
        </.link>
      </div>
    </div>
    """
  end

  def mount(%{"token" => token, "locale" => locale}, _session, socket) do
    Gettext.put_locale(locale)

    socket =
      case Accounts.update_user_email(socket.assigns.current_user, token) do
        :ok ->
          put_flash(socket, :info, gettext("Email changed successfully."))

        :error ->
          put_flash(socket, :error, gettext("Email change link is invalid or it has expired."))
      end

    {:ok, push_navigate(socket, to: ~p"/#{socket.assigns.locale}/users/settings")}
  end

  def mount(%{"locale" => locale}, _session, socket) do
    Gettext.put_locale(locale)
    user = socket.assigns.current_user

    socket =
      socket
      |> assign(:current_password, nil)
      |> assign(:email_form_current_password, nil)
      |> assign(:current_email, user.email)
      |> assign(:email_changeset, Accounts.change_user_email(user))
      |> assign(:password_changeset, Accounts.change_user_password(user))
      |> assign(:trigger_submit, false)
      |> assign(:locale, locale)
      |> assign(:api_token, nil)

    {:ok, socket}
  end

  def handle_event("create_user_api_token", _params, socket) do
    socket = assign(socket, api_token: Accounts.create_user_api_token(socket.assigns.current_user))
    {:noreply, socket}
  end

  def handle_event("validate_email", params, socket) do
    %{"current_password" => password, "user" => user_params} = params
    email_changeset = Accounts.change_user_email(socket.assigns.current_user, user_params)

    socket =
      assign(socket,
        email_changeset: Map.put(email_changeset, :action, :validate),
        email_form_current_password: password
      )

    {:noreply, socket}
  end

  def handle_event("update_email", params, socket) do
    %{"current_password" => password, "user" => user_params} = params
    user = socket.assigns.current_user

    case Accounts.apply_user_email(user, password, user_params) do
      {:ok, applied_user} ->
        Accounts.deliver_user_update_email_instructions(
          applied_user,
          user.email,
          socket.assigns.locale,
          &url(~p"/#{socket.assigns.locale}/users/settings/confirm_email/#{&1}")
        )

        info = gettext("A link to confirm your email change has been sent to the new address.")
        {:noreply, put_flash(socket, :info, info)}

      {:error, changeset} ->
        {:noreply, assign(socket, :email_changeset, Map.put(changeset, :action, :insert))}
    end
  end

  def handle_event("validate_password", params, socket) do
    %{"current_password" => password, "user" => user_params} = params
    password_changeset = Accounts.change_user_password(socket.assigns.current_user, user_params)

    {:noreply,
     socket
     |> assign(:password_changeset, Map.put(password_changeset, :action, :validate))
     |> assign(:current_password, password)}
  end

  def handle_event("update_password", params, socket) do
    %{"current_password" => password, "user" => user_params} = params
    user = socket.assigns.current_user

    case Accounts.update_user_password(user, password, user_params) do
      {:ok, user} ->
        socket =
          socket
          |> assign(:trigger_submit, true)
          |> assign(:password_changeset, Accounts.change_user_password(user, user_params))

        {:noreply, socket}

      {:error, changeset} ->
        {:noreply, assign(socket, :password_changeset, changeset)}
    end
  end
end
