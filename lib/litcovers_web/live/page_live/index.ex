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

  def stage_one_steps do
    [
      %{
        icon: "hero-user-circle",
        text: gettext("Fast, non-binding registration.")
      },
      %{
        icon: "hero-cog-solid",
        text:
          gettext(
            "Simple settings. You only need to choose the image format and the style in which it will be executed."
          )
      },
      %{
        icon: "hero-pencil",
        text:
          gettext(
            "Enter a brief description of your book or an approximate image of what should be in the image."
          )
      },
      %{
        icon: "hero-play-circle",
        text: gettext("You are ready to start - now you can start generating images.")
      }
    ]
  end

  def stage_two_steps do
    [
      %{
        icon: "hero-arrow-path",
        text: gettext("Unlimited generation – the result is guaranteed.")
      },
      %{
        icon: "hero-adjustments-horizontal",
        text: gettext("Adjust the settings – improve the result.")
      },
      %{
        icon: "hero-pencil-square",
        text: gettext("Change the description – leave only the right one.")
      },
      %{
        icon: "hero-check-badge",
        text: gettext("Find the perfect result.")
      }
    ]
  end

  def stage_three_steps do
    [
      %{
        icon: "hero-arrows-pointing-out",
        text: gettext("Increase the image quality to the maximum.")
      },
      %{
        icon: "hero-bars-3-bottom-left",
        text:
          gettext("Work with a convenient text overlay tool and turn your image into a layout")
      },
      %{
        icon: "hero-book-open",
        text:
          gettext(
            "Refine the layout to the level of a finished cover, ready for web publishing or printing."
          )
      },
      %{
        icon: "hero-arrow-down-on-square",
        text: gettext("Download the finished result and start publishing.")
      }
    ]
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
