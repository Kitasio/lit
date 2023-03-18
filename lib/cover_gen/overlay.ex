defmodule CoverGen.Overlay do
  alias CoverGen.Overlay

  require Elixir.Logger

  @derive Jason.Encoder
  defstruct author_font: "Stig.ttf",
            title_font: "Ramp.ttf",
            title: "Title",
            author: "Author",
            image_url:
              "https://ik.imagekit.io/soulgenesis/61737fdd-987e-4314-b035-4edca8600c30.png",
            line_length: 16

  def request_overlay(%Overlay{} = params) do
    endpoint = "https://litcovers-api.fly.dev/overlay"
    body = Jason.encode!(params)
    headers = ["Content-Type": "application/json"]

    case HTTPoison.post!(endpoint, body, headers) do
      %HTTPoison.Response{status_code: 200, body: image_bytes} ->
        {:ok, image_bytes}

      %HTTPoison.Response{status_code: status_code, body: body} ->
        {:error, "Error: #{status_code} - #{body}"}
    end
  end

  def put_text_on_images([], _img_url, _author, _title, _prompt_realm), do: []

  def put_text_on_images([num | line_length_list], img_url, author, title, prompt_realm) do
    [
      insert_author_title(img_url, author, title, prompt_realm, num)
      | put_text_on_images(line_length_list, img_url, author, title, prompt_realm)
    ]
  end

  def insert_author_title(link, author, title, prompt_realm, num) do
    params = %Overlay{
      author_font: get_rand_type(prompt_realm, "author") <> ".ttf",
      title_font: get_rand_type(prompt_realm, "title") <> ".ttf",
      title: title,
      author: author,
      image_url: link |> insert_vinyetta(),
      line_length: num
    }

    imagekit_url = Application.get_env(:litcovers, :imagekit_url)
    bucket = Application.get_env(:litcovers, :bucket)
    filename = "#{Ecto.UUID.generate()}.png"

    case Overlay.request_overlay(params) do
      {:ok, image_bytes} ->
        ExAws.S3.put_object(bucket, filename, image_bytes) |> ExAws.request!()

        image_url = Path.join(imagekit_url, filename)
        image_url

      {:error, reason} ->
        Logger.error("Error while requesting overlay API: #{inspect(reason)}")
    end
  end

  def get_rand_type(prompt_realm, font_type) do
    %{^prompt_realm => %{^font_type => types}} = font_types()
    types |> Enum.random()
  end

  def insert_vinyetta(link) do
    uri = link |> URI.parse()
    %URI{host: host, path: path} = uri

    case host do
      "ik.imagekit.io" ->
        vinyetta = "tr:w-512,h-768,oi-vin.png,ow-512,oh-768,q-100,f-jpg"
        {filename, list} = path |> String.split("/") |> List.pop_at(-1)
        bucket = list |> List.last()

        Path.join(["https://", host, bucket, vinyetta, filename])

      _ ->
        link
    end
  end

  # returns a list of numbers based on the length of a given string
  def get_line_length_list(str) do
    cond do
      String.length(str) <= 16 ->
        [16]

      String.length(str) <= 26 ->
        [16, 26]

      true ->
        [16, 26, 32]
    end
  end

  def font_types do
    %{
      "fantasy" => %{
        "author" => [
          "AttackType-Heavy",
          "BalkaraFreeCondensed-npoekmu.me",
          "DwarvenStonecraftCyr",
          "GarciaMarquez",
          "OrelegaOne-Regular",
          "Underdog-Regular"
        ],
        "title" => [
          "Ambidexter_Regular",
          "AttackType-Heavy",
          "BalkaraFreeCondensed-npoekmu.me",
          "Belozersk_Font",
          "DRUZHOK",
          "DwarvenStonecraftCyr",
          "FemmeFatale-Regular",
          "GarciaMarquez",
          "Germanica",
          "kurbanistika",
          "Mirra",
          "Ramp",
          "ST-Nizhegorodsky",
          "StalinistOne-Regular",
          "Stig",
          "Tsarevich_old",
          "Underdog-Regular"
        ]
      },
      "realism" => %{
        "author" => [
          "Comic_CAT",
          "DelaGothicOne-Regular",
          "Felidae",
          "Garet-Heavy",
          "Izax",
          "Sloval",
          "TT2020StyleB-Regular"
        ],
        "title" => [
          "Angry",
          "Comic_CAT",
          "DelaGothicOne-Regular",
          "Eleventh-Square",
          "Felidae",
          "Garet-Heavy",
          "Izax",
          "le-murmure",
          "Miratrix-Normal",
          "Molot",
          "NovitoNova-Regular",
          "Ouroboros-Regular",
          "Sloval",
          "tangak",
          "TT2020StyleB-Regular"
        ]
      },
      "futurism" => %{
        "author" => [
          "Aronder",
          "EBENYA",
          "Hellenica",
          "MoscowMetro",
          "Practice-font-Mono",
          "Radiotechnika"
        ],
        "title" => [
          "Aronder",
          "EBENYA",
          "forward",
          "Greybeard-22px-Bold",
          "Hellenica",
          "Kontanter-Bold",
          "MonHugo-in",
          "MoscowMetro",
          "Obrazec-2.0",
          "Polonium-Bold",
          "Practice-font-Mono",
          "Radiotechnika",
          "shinners-regular",
          "Snowstorm-Bold",
          "Yulong",
          "Zyablik-Regular"
        ]
      }
    }
  end
end
