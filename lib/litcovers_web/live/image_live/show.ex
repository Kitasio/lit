defmodule LitcoversWeb.ImageLive.Show do
  use LitcoversWeb, :live_view
  import LitcoversWeb.ImageLive.Index
  require Logger

  alias Litcovers.Metadata
  alias Litcovers.Media
  alias CoverGen.Imagekit

  @impl true
  def mount(%{"locale" => locale, "id" => id}, _session, socket) do
    Gettext.put_locale(locale)
    image = Media.get_image!(id)

    image_base64 =
      image.url
      |> Imagekit.transform("oi-dark-effect-top.png,oy-0")
      |> Imagekit.transform("oi-dark-effect-bot.png,oy-N0")
      |> Imagekit.transform("q-100,f-jpg")
      |> img_url_to_base64()

    author_current_font = fonts_list() |> List.first()
    author_font_base64 = author_current_font |> redis_get_or_set_font()

    {:ok,
     assign(socket,
       locale: locale,
       image: image,
       image_base64: image_base64,
       author_current_font: author_current_font,
       author_font_base64: author_font_base64,
       title_font_base64: author_font_base64,
       title_current_font: author_current_font,
       params: initial_params(),
       placeholder: placeholder_or_empty(Metadata.get_random_placeholder()),
       current_tut: nil,
       user_tuts: Metadata.list_user_tutorials(socket.assigns.current_user)
     )}
  end

  defp tutorials do
    [
      %{
        title: "overlay",
        banner_url: "https://ik.imagekit.io/soulgenesis/overlay_tut.jpg",
        header: gettext("Text overlay"),
        text: [
          gettext(
            "Specially for the authors, we have prepared an alpha version of the text overlay, which will allow you to create a ready-made cover in a matter of seconds! Just enter your name/creative pseudonym and the title of the work. Font selection and other parameters will give you room for variation."
          )
        ],
        button: gettext("Begin!")
      }
    ]
  end

  @impl true
  def handle_params(params, _url, socket) do
    socket = apply_action(socket, socket.assigns.live_action, params)

    {:noreply,
     push_event(socket, "create_cover", %{
       author_font_base64: socket.assigns.author_font_base64,
       title_font_base64: socket.assigns.title_font_base64,
       image_base64: socket.assigns.image_base64,
       params: socket.assigns.params
     })}
  end

  def apply_action(socket, :show, %{"id" => id}) do
    image = Media.get_image_preload!(id)

    if image.user_id == socket.assigns.current_user.id do
      next = next_tut(socket, tutorials())

      if connected?(socket) and next != nil do
        Metadata.create_tutotial(socket.assigns.current_user, %{title: next.title})
      end

      socket = assign(socket, current_tut: next)

      assign(socket, image: image)
    else
      socket
      |> put_flash(:error, gettext("You don't have access to this image"))
      |> push_navigate(to: ~p"/#{socket.assigns.locale}/images")
    end
  end

  def initial_params do
    %{
      author: "",
      author_position: "TopCenter",
      title: "",
      title_position: "BottomStretch",
      blend_mode: "None",
      alfa: "3.0",
      line_length: "16"
    }
  end

  def title_position_opts do
    ["BottomCenter", "BottomLeft", "BottomStretch", "BottomSides"]
  end

  @impl true
  def handle_event("save-to-spaces", %{"img" => img}, socket) do
    image_bytes =
      img
      |> String.split(",")
      |> List.last()
      |> Base.decode64!()

    img_url = CoverGen.Spaces.save_bytes(image_bytes)
    params = %{url: img_url}

    case Media.create_cover(socket.assigns.image, socket.assigns.current_user, params) do
      {:ok, _cover} ->
        socket =
          socket
          |> put_flash(:info, gettext("Your cover is saved"))
          |> push_navigate(
            to: ~p"/#{socket.assigns.locale}/images/#{socket.assigns.image.id}/edit"
          )

        {:noreply, socket}

      {:error, _changeset} ->
        socket =
          socket
          |> put_flash(:error, gettext("Error saving your cover"))
          |> push_navigate(to: ~p"/#{socket.assigns.locale}/images")

        {:noreply, socket}
    end
  end

  @impl true
  def handle_event("create-cover", %{"params" => params}, socket) do
    params = update_params(params, socket)
    socket = assign(socket, params: params)

    {:noreply,
     push_event(socket, "create_cover", %{
       author_font_base64: socket.assigns.author_font_base64,
       title_font_base64: socket.assigns.title_font_base64,
       image_base64: socket.assigns.image_base64,
       params: params
     })}
  end

  @impl true
  def handle_event("title-position-change", %{"position" => position}, socket) do
    params = update_params(%{"title_position" => position}, socket)
    socket = assign(socket, params: params)

    {:noreply,
     push_event(socket, "create_cover", %{
       author_font_base64: socket.assigns.author_font_base64,
       title_font_base64: socket.assigns.title_font_base64,
       image_base64: socket.assigns.image_base64,
       params: params
     })}
  end

  @impl true
  def handle_event("next-author-font", _, socket) do
    next_font = socket.assigns.author_current_font |> next_font()
    next_font_base64 = next_font |> redis_get_or_set_font()

    socket =
      assign(socket,
        author_current_font: next_font,
        author_font_base64: next_font_base64
      )

    {:noreply,
     push_event(socket, "create_cover", %{
       author_font_base64: socket.assigns.author_font_base64,
       title_font_base64: socket.assigns.title_font_base64,
       image_base64: socket.assigns.image_base64,
       params: socket.assigns.params
     })}
  end

  @impl true
  def handle_event("prev-author-font", _, socket) do
    prev_font = socket.assigns.author_current_font |> prev_font()
    prev_font_base64 = prev_font |> redis_get_or_set_font()

    socket =
      assign(socket,
        author_current_font: prev_font,
        author_font_base64: prev_font_base64
      )

    {:noreply,
     push_event(socket, "create_cover", %{
       author_font_base64: socket.assigns.author_font_base64,
       title_font_base64: socket.assigns.title_font_base64,
       image_base64: socket.assigns.image_base64,
       params: socket.assigns.params
     })}
  end

  @impl true
  def handle_event("next-title-font", _, socket) do
    next_font = socket.assigns.title_current_font |> next_font()
    next_font_base64 = next_font |> redis_get_or_set_font()

    socket =
      assign(socket,
        title_current_font: next_font,
        title_font_base64: next_font_base64
      )

    {:noreply,
     push_event(socket, "create_cover", %{
       author_font_base64: socket.assigns.author_font_base64,
       title_font_base64: socket.assigns.title_font_base64,
       image_base64: socket.assigns.image_base64,
       params: socket.assigns.params
     })}
  end

  @impl true
  def handle_event("prev-title-font", _, socket) do
    prev_font = socket.assigns.title_current_font |> prev_font()
    prev_font_base64 = prev_font |> redis_get_or_set_font()

    socket =
      assign(socket,
        title_current_font: prev_font,
        title_font_base64: prev_font_base64
      )

    {:noreply,
     push_event(socket, "create_cover", %{
       author_font_base64: socket.assigns.author_font_base64,
       title_font_base64: socket.assigns.title_font_base64,
       image_base64: socket.assigns.image_base64,
       params: socket.assigns.params
     })}
  end

  defp update_params(params, socket) do
    params = params |> Enum.into(%{}) |> Map.new(fn {k, v} -> {String.to_atom(k), v} end)
    Map.merge(socket.assigns.params, params)
  end

  defp fonts_base_path do
    if System.get_env("MIX_ENV") == "prod" do
      [Application.app_dir(:litcovers), "priv/static/fonts"] |> Path.join()
    else
      "priv/static/fonts"
    end
  end

  def font_to_base64(font_name) do
    [fonts_base_path(), font_name]
    |> Path.join()
    |> File.read!()
    |> Base.encode64()
  end

  def redis_get_or_set_font(font_name) do
    # check if font stored in redis
    case Redix.command(:redix, ["GET", font_name]) do
      {:ok, nil} ->
        font_base64 = font_name |> font_to_base64()
        Logger.info("Setting font #{font_name} in redis")
        Redix.command(:redix, ["SET", font_name, font_base64])
        font_base64

      {:ok, font_base64} ->
        Logger.info("Font #{font_name} found in redis")
        font_base64

      {:error, reason} ->
        Logger.error("Error getting font #{font_name} from redis: #{inspect(reason)}")
        font_name |> font_to_base64()
    end
  end

  def img_url_to_base64(url) do
    res = HTTPoison.get!(url)
    res.body |> Base.encode64()
  end

  def next_font(current_font) do
    current_font_index = fonts_list() |> Enum.find_index(fn font -> font == current_font end)
    next_font_index = current_font_index + 1
    fonts_list() |> Enum.at(next_font_index)
  end

  def prev_font(current_font) do
    current_font_index = fonts_list() |> Enum.find_index(fn font -> font == current_font end)
    prev_font_index = current_font_index - 1
    fonts_list() |> Enum.at(prev_font_index)
  end

  def get_font_name(font_file_name) do
    font_file_name
    |> String.split(".")
    |> List.first()
    |> String.replace("-", " ")
    |> String.capitalize()
  end

  defp fonts_list() do
    [
      "ProstoOne-Regular.ttf",
      "Brygada1918-Bold.ttf",
      "ZenAntiqueSoft-Regular.ttf",
      "Alice-Regular.ttf",
      "Rubik80sFade-Regular.ttf",
      "Nunito-Black.ttf",
      "EBGaramond-Bold.ttf",
      "DotGothic16-Regular.ttf",
      "MontserratAlternates-ExtraBold.ttf",
      "Alegreya-Black.ttf",
      "RubikGlitch-Regular.ttf",
      "SourceSerifPro-Black.ttf",
      "RussoOne-Regular.ttf",
      "OldStandardTT-Bold.ttf",
      "Forum-Regular.ttf",
      "PressStart2P-Regular.ttf",
      "Lora-Bold.ttf",
      "Oswald-Bold.ttf",
      "IBMPlexSerif-Bold.ttf",
      "DelaGothicOne-Regular.ttf",
      "BadScript-Regular.ttf",
      "Vollkorn-ExtraBold.ttf",
      "AlumniSans-Black.ttf",
      "Montserrat-Black.ttf",
      "Unbounded-Black.ttf",
      "PlayfairDisplay-ExtraBold.ttf",
      "PTSerif-Bold.ttf",
      "FiraSansExtraCondensed-Black.ttf",
      "Comfortaa-Bold.ttf",
      "RobotoSlab-ExtraBold.ttf",
      "YanoneKaffeesatz-Bold.ttf",
      "Oi-Regular.ttf",
      "StalinistOne-Regular.ttf",
      "ElMessiri-SemiBold.ttf",
      "YesevaOne-Regular.ttf",
      "SeymourOne-Regular.ttf",
      "Oranienbaum-Regular.ttf",
      "PoiretOne-Regular.ttf",
      "Cuprum-VariableFont_wght.ttf",
      "Neucha-Regular.ttf",
      "Cormorant-Bold.ttf",
      "Play-Bold.ttf",
      "Prata-Regular.ttf",
      "Stick-Regular.ttf",
      "RuslanDisplay-Regular.ttf",
      "Merriweather-Bold.ttf",
      "AlumniSansPinstripe-Regular.ttf",
      "AmaticSC-Bold.ttf",
      "Tinos-Bold.ttf",
      "Pattaya-Regular.ttf",
      "TenorSans-Regular.ttf",
      "NotoSerif-Bold.ttf",
      "Spectral-ExtraBold.ttf",
      "Bitter-ExtraBold.ttf",
      "RubikSprayPaint-Regular.ttf",
      "Podkova-ExtraBold.ttf",
      "CormorantGaramond-SemiBold.ttf",
      "PlayfairDisplaySC-Black.ttf",
      "Jost-Black.ttf"
    ]
  end
end
