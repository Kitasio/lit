defmodule LitcoversWeb.V1.ImageController do
  alias Litcovers.Accounts
  alias CoverGen.Generator
  alias Litcovers.Repo
  alias Litcovers.Media.Image
  alias Litcovers.Media
  alias LitcoversWeb.Plugs
  use LitcoversWeb, :controller

  require Logger

  action_fallback LitcoversWeb.FallbackController

  plug Plugs.ValidateModel, nil when action in [:create]
  plug Plugs.EnsureEnoughCoins when action in [:create]

  def index(conn, _params) do
    images = Media.list_user_images(conn.assigns[:current_user])
    render(conn, :index, images: images)
  end

  def show(conn, %{"id" => id}) do
    image = Media.get_user_image!(conn.assigns[:current_user], id)
    render(conn, :show, image: image)
  end

  @doc """
  Generates an image based on provided options.

  Requires the user to have enough Litcoins.

  Returns the created image resource.
  """
  def create(conn, params) do
    conn
    |> create_image_record(params)
    |> generate_image(params)
    |> update_image_record(params)
    |> remove_litcoins(params)
    |> return_image(params)
  end

  @doc false
  defp create_image_record(conn, params) do
    current_user = conn.assigns[:current_user]

    # Extract image params from request params
    image_params = %{
      description: params["description"],
      style_preset: params["style_preset"] || "photographic",
      model_name: params["model_name"] || params["model"] || "sd3",
      aspect_ratio: params["aspect_ratio"] || "2:3"
    }

    Logger.info("Creating image record with params: #{inspect(image_params)}")

    Media.create_image_from_api(current_user, image_params)
    |> handle_create_image_record(conn)
  end

  @doc false
  defp handle_create_image_record({:ok, %Image{} = image}, conn) do
    assign(conn, :image, image)
  end

  defp handle_create_image_record({:error, changeset}, conn) do
    Logger.error("Failed to create image record: #{inspect(changeset)}")

    conn
    |> put_status(:unprocessable_entity)
    |> put_view(LitcoversWeb.ErrorJSON)
    |> render(:"422", errors: changeset)
    |> halt()
  end

  @doc false
  defp generate_image(conn, params) do
    image = conn.assigns[:image]
    # Extract use_custom_prompt flag from request params
    use_custom_prompt = params["use_custom_prompt"] || false

    # Prepare options for the generator
    generation_options = %{
      model_name: image.model_name,
      style_preset: image.style_preset,
      aspect_ratio: image.aspect_ratio,
      use_custom_prompt: use_custom_prompt
    }

    Logger.info(
      "Generating image content for image ID #{image.id} with options: #{inspect(generation_options)}"
    )

    # Call the generator to create the image
    case Generator.generate_image(image.description, generation_options) do
      {:ok, result} ->
        assign(conn, :generation_result, result)

      {:error, reason} ->
        # Clean up the image record on failure
        Logger.error(
          "Error occurred while generating, deleting image ID #{image.id}: #{inspect(reason)}"
        )

        Media.delete_image(image)

        conn
        |> put_status(:unprocessable_entity)
        |> put_view(LitcoversWeb.ErrorJSON)
        |> render(:"422", errors: %{detail: "Failed to generate image: #{inspect(reason)}"})
        |> halt()
    end
  end

  @doc false
  defp update_image_record(conn, _params) do
    image = conn.assigns[:image]
    generation_result = conn.assigns[:generation_result]

    # Update the image record with the result
    image_params = %{
      url: generation_result.url,
      final_prompt: generation_result.final_prompt,
      completed: true
    }

    Logger.info("Updating image record ID #{image.id} with generated content")

    # Update the image record in the database
    changeset = Image.ai_changeset(image, image_params)

    case Repo.update(changeset) do
      {:ok, updated_image} ->
        assign(conn, :image, updated_image)

      {:error, changeset} ->
        # Clean up the image record on failure
        Logger.error("Failed to update image record ID #{image.id}: #{inspect(changeset)}")
        Media.delete_image(image)

        conn
        |> put_status(:unprocessable_entity)
        |> put_view(LitcoversWeb.ErrorJSON)
        |> render(:"422", errors: changeset)
        |> halt()
    end
  end

  @doc false
  defp remove_litcoins(conn, _params) do
    current_user = conn.assigns[:current_user]
    # Cost is assigned by Plugs.EnsureEnoughCoins
    cost = conn.assigns[:cost]

    Logger.info("Removing #{floor(cost)} litcoins from user #{current_user.id}")
    Accounts.remove_litcoins(current_user, floor(cost))
    conn
  end

  @doc false
  defp return_image(conn, _params) do
    image = conn.assigns[:image]

    conn
    |> put_status(:created)
    |> put_resp_header("location", ~p"/api/v1/images/#{image}")
    |> render(:show, image: image)
  end
end
