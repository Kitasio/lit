defmodule LitcoversWeb.UserRegistrationLive do
  use LitcoversWeb, :live_view

  alias Litcovers.Accounts
  alias Litcovers.Accounts.User

  def mount(%{"locale" => locale}, session, socket) do
    Gettext.put_locale(locale)
    changeset = Accounts.change_user_registration(%User{})

    socket =
      assign(socket,
        changeset: changeset,
        trigger_submit: false,
        locale: locale,
        referer: session["referer"],
        current_tut: tut()
      )

    {:ok, socket, temporary_assigns: [changeset: nil]}
  end

  defp tut do
    %{
      title: "rugram",
      banner_url: "https://ik.imagekit.io/soulgenesis/ban_rugram.jpg",
      header: "Новый проект Rugram и Litcovers!",
      text: [
        "Экспериментируем, внедряем новые технологии и развиваем сервисы для авторов вместе с издательской платформой Rugram!",
        "Для авторов  Rugram Litcovers подготовили специальные условия:<br>
самые низкие цены в индустрии и удобный сервис!",
        "Время создавать и удивлять!"
      ],
      button: "Начать!"
    }
  end

  def handle_event("save", %{"user" => user_params}, socket) do
    user_params =
      if socket.assigns.referer do
        %{host: host, discount: discount} = socket.assigns.referer
        Map.put_new(user_params, "discount", discount) |> Map.put_new("referer", host)
      else
        user_params
      end

    case Accounts.register_user(user_params) do
      {:ok, user} ->
        {:ok, _} =
          Accounts.deliver_user_confirmation_instructions(
            user,
            socket.assigns.locale,
            &url(~p"/#{socket.assigns.locale}/users/confirm/#{&1}")
          )

        changeset = Accounts.change_user_registration(user)
        {:noreply, assign(socket, trigger_submit: true, changeset: changeset)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :changeset, changeset)}
    end
  end

  def handle_event("validate", %{"user" => user_params}, socket) do
    changeset = Accounts.change_user_registration(%User{}, user_params)
    {:noreply, assign(socket, changeset: Map.put(changeset, :action, :validate))}
  end

  def render(assigns) do
    ~H"""
    <.modal
      :if={@referer}
      on_confirm={hide_modal("reg-referer-modal")}
      id="reg-referer-modal"
      show={@referer}
      banner_url={@current_tut.banner_url}
    >
      <:title><%= @current_tut.header %></:title>
      <div class="flex text-xs sm:text-sm font-light sm:font-normal text-zinc-300 flex-col gap-2">
        <p :for={text <- @current_tut.text}><%= raw text %></p>
      </div>
      <:confirm><%= @current_tut.button %></:confirm>
    </.modal>
    <.navbar locale={@locale} request_path={"/#{@locale}/users/register"} />
    <div class="bg-main p-10 sm:my-5 lg:my-20 mx-auto max-w-md rounded-lg sm:border-2 border-stroke-main">
      <p :if={@referer} class="mb-2 text-xs text-slate-300 text-center w-full">
        <%= gettext("Bonuses applied from ") %>
        <span class="text-slate-100 font-semibold"><%= @referer.host %></span>
      </p>
      <.header class="text-center">
        <%= gettext("Register for an account") %>
        <:subtitle>
          <%= gettext("Already registered?") %>
          <.link
            navigate={~p"/#{@locale}/users/log_in"}
            class="font-semibold text-accent-main hover:underline"
          >
            <%= gettext("Sign in") %>
          </.link>
          <%= gettext("to your account now.") %>
        </:subtitle>
      </.header>

      <.simple_form
        :let={f}
        id="registration_form"
        for={@changeset}
        phx-submit="save"
        phx-change="validate"
        phx-trigger-action={@trigger_submit}
        action={~p"/#{@locale}/users/log_in?_action=registered"}
        method="post"
        as={:user}
      >
        <.error :if={@changeset.action == :insert}>
          <%= gettext("Oops, something went wrong! Please check the errors below.") %>
        </.error>

        <.input field={{f, :email}} type="email" label={gettext("Email")} required />
        <.input field={{f, :password}} type="password" label={gettext("Password")} required />

        <:actions>
          <.button phx-disable-with={gettext("Creating account...")} class="w-full">
            <%= gettext("Create an account") %>
          </.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end
end
