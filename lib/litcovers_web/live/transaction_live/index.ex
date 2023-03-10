defmodule LitcoversWeb.TransactionLive.Index do
  use LitcoversWeb, :live_view
  alias Litcovers.Payments
  alias Litcovers.Payments.Yookassa

  def mount(%{"locale" => locale}, _session, socket) do
    Gettext.put_locale(locale)
    {:ok, assign(socket, locale: locale, pay_options: pay_options(locale))}
  end

  def handle_event("make-payment", %{"amount" => amount}, socket) do
    {:ok, body} = Yookassa.Request.payment(amount)
    %{"confirmation" => %{"confirmation_url" => confirmation_url}} = body
    transaction = Yookassa.Helpers.transaction_from_yookassa(body)

    Payments.create_transaction(socket.assigns.current_user, transaction)

    {:noreply, redirect(socket, external: confirmation_url)}
  end

  def pay_options(_locale) do
    [
      %{name: gettext("Lonely pixel"), value: "390.00", label: "390₽", litcoins: 1, bonus: 0},
      %{name: gettext("Creative duo"), value: "780.00", label: "780₽", litcoins: 2, bonus: 1},
      %{name: gettext("Novice collector"), value: "1950.00", label: "1950₽", litcoins: 5, bonus: 2},
      %{name: gettext("Paint Party"), value: "3900.00", label: "3900₽", litcoins: 10, bonus: 3},
      %{name: gettext("Masterpiece creator"), value: "5850.00", label: "5850₽", litcoins: 15, bonus: 5},
      %{name: gettext("Legendary Gallery"), value: "7800.00", label: "7800₽", litcoins: 20, bonus: 10}
    ]
  end
end
