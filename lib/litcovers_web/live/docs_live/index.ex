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
            example: "flux",
            description: "The model name, to view all available models, see /api/v1/accounts. Available models include: 'sd3', 'flux', 'ultra', and others."
          },
          %{
            name: "aspect_ratio",
            type: "string (optional)",
            location: "body",
            default: "2:3",
            example: "1:1",
            description:
              "The aspect ratio of the image, can be one of 16:9 1:1 21:9 2:3 3:2 4:5 5:4 9:16 9:21"
          },
          %{
            name: "use_custom_prompt",
            type: "boolean (optional)",
            location: "body",
            default: "false",
            example: "true",
            description:
              "When set to true, the service will use your description exactly as provided, without AI enhancement. This allows you to have full control over the final prompt sent to the image generation model."
          }
        ]
      },
      %{
        title: "Create a book cover from an image",
        path: "/api/v1/images/{id}/covers",
        method: "POST",
        description: "Converts a simple generated image into a book cover. If outpainting API is available, it will extend the original image to create front cover, spine, and back cover. Otherwise, it will generate a new book cover based on the provided prompt or original image prompt.",
        params: [
          %{
            name: "id",
            type: "integer",
            location: "path",
            default: "",
            example: "123",
            description: "The ID of the source image to convert to a book cover"
          },
          %{
            name: "left",
            type: "integer (optional)",
            location: "body",
            default: "image width",
            example: "512",
            description: "Number of pixels to extend the image to the left (for back cover). Defaults to the original image width."
          },
          %{
            name: "right",
            type: "integer (optional)",
            location: "body",
            default: "0",
            example: "50",
            description: "Number of pixels to extend the image to the right (bleed area)"
          },
          %{
            name: "up",
            type: "integer (optional)",
            location: "body",
            default: "0",
            example: "50",
            description: "Number of pixels to extend the image upward (bleed area)"
          },
          %{
            name: "down",
            type: "integer (optional)",
            location: "body",
            default: "0",
            example: "50",
            description: "Number of pixels to extend the image downward (bleed area)"
          },
          %{
            name: "prompt",
            type: "string (optional)",
            location: "body",
            default: "original image prompt",
            example: "A fantasy book cover with a dark castle and mountains",
            description: "Text prompt to guide the outpainting. Defaults to the original image's prompt if not provided."
          },
          %{
            name: "style_preset",
            type: "string (optional)",
            location: "body",
            default: "photographic",
            example: "concept-art",
            description: "The style preset to apply to the outpainting. Should match the original image's style."
          },
          %{
            name: "pages",
            type: "integer (optional)",
            location: "body",
            default: "",
            example: "300",
            description: "Number of pages in the book, can be used to calculate spine width."
          }
        ]
      }
    ]
  end
end
