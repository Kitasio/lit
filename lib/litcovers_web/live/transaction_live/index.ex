defmodule LitcoversWeb.TransactionLive.Index do
  use LitcoversWeb, :live_view
  alias Litcovers.Payments
  alias Litcovers.Payments.Yookassa

  def mount(%{"locale" => locale}, _session, socket) do
    Gettext.put_locale(locale)
    {:ok, assign(socket, locale: locale, pay_options: pay_options(locale))}
  end

  def user_discount_convert(discount, :as_percents) when is_float(discount) do
    100 - discount * 100
  end

  def get_tx_discount(amount, user_discount)
      when is_integer(amount) and is_float(user_discount) do
    amount - ((amount * user_discount) |> floor())
  end

  def apply_discount(price, discount) do
    (price * discount) |> ceil()
  end

  def amount_to_int(amount) do
    amount |> String.split(".") |> List.first() |> String.to_integer()
  end

  def handle_event("make-payment", %{"amount" => amount, "total-amount" => total_amount}, socket) do
    {:ok, body} = Yookassa.Request.payment(to_string(amount) <> ".00")
    %{"confirmation" => %{"confirmation_url" => confirmation_url}} = body

    tx_discount =
      get_tx_discount(amount_to_int(total_amount), socket.assigns.current_user.discount)

    transaction = Yookassa.Helpers.transaction_from_yookassa(body, tx_discount)

    Payments.create_transaction(socket.assigns.current_user, transaction)

    {:noreply, redirect(socket, external: confirmation_url)}
  end

  def pay_options(_locale) do
    [
      %{
        bg: "https://ik.imagekit.io/soulgenesis/pay_blur_1.png",
        name: gettext("Lonely pixel"),
        value: "390.00",
        currency: "₽",
        litcoins: 1,
        bonus: 0
      },
      %{
        bg: "https://ik.imagekit.io/soulgenesis/pay_blur_2.png",
        name: gettext("Creative duo"),
        value: "780.00",
        currency: "₽",
        litcoins: 2,
        bonus: 1
      },
      %{
        bg: "https://ik.imagekit.io/soulgenesis/pay_blur_3.png",
        name: gettext("Novice collector"),
        value: "1950.00",
        currency: "₽",
        litcoins: 5,
        bonus: 2
      },
      %{
        bg: "https://ik.imagekit.io/soulgenesis/pay_blur_4.png",
        name: gettext("Paint Party"),
        value: "3900.00",
        currency: "₽",
        litcoins: 10,
        bonus: 3
      },
      %{
        bg: "https://ik.imagekit.io/soulgenesis/pay_blur_5.png",
        name: gettext("Masterpiece creator"),
        value: "5850.00",
        currency: "₽",
        litcoins: 15,
        bonus: 5
      },
      %{
        bg: "https://ik.imagekit.io/soulgenesis/pay_blur_6.png",
        name: gettext("Legendary Gallery"),
        value: "7800.00",
        currency: "₽",
        litcoins: 20,
        bonus: 10
      }
    ]
  end
end
