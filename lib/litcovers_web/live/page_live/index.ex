defmodule LitcoversWeb.PageLive.Index do
  use LitcoversWeb, :live_view
  alias Litcovers.Accounts

  @impl true
  def mount(%{"locale" => locale}, session, socket) do
    Gettext.put_locale(locale)

    current_user =
      case Map.fetch(session, "user_token") do
        {:ok, token} -> Accounts.get_user_by_session_token(token)
        :error -> nil
      end

    {:ok, assign(socket, locale: locale, current_user: current_user)}
  end

  def showcase do
    [
      %{
        img: "https://ik.imagekit.io/soulgenesis/litnet/showcase_1.jpg",
        heading: gettext("Portraits"),
        sub: gettext("Of characters from your book")
      },
      %{
        img: "https://ik.imagekit.io/soulgenesis/litnet/showcase_2.jpg",
        heading: gettext("Worlds"),
        sub: gettext("Amazing in its atmosphere and fullness")
      },
      %{
        img: "https://ik.imagekit.io/soulgenesis/litnet/showcase_3.jpg",
        heading: gettext("Attributes"),
        sub: gettext("Unique artifacts and items from your worlds")
      }
    ]
  end

  def points do
    [
      %{
        icon: "https://ik.imagekit.io/soulgenesis/litnet/point_1.png",
        heading: gettext("Unique artifacts and items from your worlds"),
        sub:
          gettext(
            "Your new cover is a symbiosis of our many years of experience in the field of design and technology and AI"
          )
      },
      %{
        icon: "https://ik.imagekit.io/soulgenesis/litnet/point_2.png",
        heading: gettext("Source files in high resolution"),
        sub:
          gettext(
            "Digital versions and files for printing. All in one place, neatly folded for you"
          )
      },
      %{
        icon: "https://ik.imagekit.io/soulgenesis/litnet/point_3.png",
        heading: gettext("Quick results and a choice"),
        sub:
          gettext(
            "We appreciate your time and know for sure that several options are better than one"
          )
      },
      %{
        icon: "https://ik.imagekit.io/soulgenesis/litnet/point_4.png",
        heading: gettext("Simple and convenient system"),
        sub: gettext("Without the brain-crushing and incomprehensible. Just try it yourself!")
      }
    ]
  end

  def covers do
    [
      "https://ik.imagekit.io/soulgenesis/litnet/cover_1.jpg",
      "https://ik.imagekit.io/soulgenesis/litnet/cover_2.jpg",
      "https://ik.imagekit.io/soulgenesis/litnet/cover_3.jpg",
      "https://ik.imagekit.io/soulgenesis/litnet/cover_4.jpg",
      "https://ik.imagekit.io/soulgenesis/litnet/cover_5.jpg",
      "https://ik.imagekit.io/soulgenesis/litnet/cover_6.jpg"
    ]
  end

  def current_year do
    DateTime.utc_now() |> Map.fetch!(:year)
  end
end
