defmodule LitcoversWeb.DocsLive.Index do
  alias Litcovers.Accounts
  use LitcoversWeb, :live_view

  @impl true
  def mount(%{"locale" => locale}, session, socket) do
    Gettext.put_locale(locale)

    current_user =
      case Map.fetch(session, "user_token") do
        {:ok, token} -> Accounts.get_user_by_session_token(token)
        :error -> nil
      end

    {:ok,
     assign(socket,
       locale: locale,
       endpoints: endpoints(),
       current_user: current_user
     )}
  end

  defp endpoints do
    [
      %{
        title: "Get account information",
        path: "/api/v1/accounts",
        method: "GET",
        description: "Get account information",
        params: []
      },
      %{
        title: "Get all images",
        path: "/api/v1/images",
        method: "GET",
        description: "Get all completed images for the user",
        params: []
      },
      %{
        title: "Get a single image",
        path: "/api/v1/images/{id}",
        method: "GET",
        description: "Get a single image",
        params: [
          %{
            name: "id",
            type: "integer",
            location: "path",
            default: "",
            example: "123",
            description: "The image id"
          }
        ]
      },
      %{
        title: "Generate an image",
        path: "/api/v1/images",
        method: "POST",
        description: "Generate an image",
        params: [
          %{
            name: "description",
            type: "string",
            location: "body",
            default: "",
            example: "A cute brown cat in a tailored space suit",
            description: "The image prompt"
          },
          %{
            name: "style_preset",
            type: "string (optional)",
            location: "body",
            default: "photographic",
            example: "concept-art",
            description:
              "The style preset, an arbitrary string up to 50 characters, indicates the style of the image, here are some options: Dark Souls 3, Arcane League of Legends, cyberpunk, 3d-model, analog-film, anime, cinematic, comic-book, digital-art, enhance, fantasy-art, isometric, line-art, low-poly, modeling-compound, neon-punk, origami, photographic, pixel-art, tile-texture"
          },
          %{
            name: "model",
            type: "string (optional)",
            location: "body",
            default: "sd3",
            example: "ultra",
            description: "The model name, to view all available models, see /api/v1/accounts"
          },
          %{
            name: "aspect_ratio",
            type: "string (optional)",
            location: "body",
            default: "2:3",
            example: "1:1",
            description:
              "The aspect ratio of the image, can be one of 16:9 1:1 21:9 2:3 3:2 4:5 5:4 9:16 9:21"
          }
        ]
      }
    ]
  end
end
