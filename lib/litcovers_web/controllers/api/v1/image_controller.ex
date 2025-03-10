defmodule LitcoversWeb.V1.ImageController do
  alias Litcovers.Accounts
  alias CoverGen.Generator
  alias Litcovers.Repo
  alias Litcovers.Media.Image
  alias Litcovers.Media
  use LitcoversWeb, :controller

  require Logger

  action_fallback LitcoversWeb.FallbackController

  def index(conn, _params) do
    images = Media.list_user_images(conn.assigns[:current_user])
    render(conn, :index, images: images)
  end

  def show(conn, %{"id" => id}) do
    image = Media.get_user_image!(conn.assigns[:current_user], id)
    render(conn, :show, image: image)
  end

  def create(conn, request_params) do
    model_name = request_params["model"] || "sd3"

    # Validate the model exists
    unless CoverGen.Models.all() |> Enum.member?(model_name) do
      return = conn
        |> put_status(:bad_request)
        |> put_view(LitcoversWeb.ErrorJSON)
        |> render(:"400")
      
      # Need to return to exit the function
      return
    end

    # Check user has enough coins for the selected model
    price_for_model = CoverGen.Models.price(conn.assigns[:current_user], model_name)
    if conn.assigns[:current_user].litcoins < price_for_model do
      return = conn
        |> put_status(:payment_required)
        |> put_view(LitcoversWeb.ErrorJSON)
        |> render(:"402")
      
      # Need to return to exit the function
      return
    end

    # Extract use_custom_prompt flag
    use_custom_prompt = request_params["use_custom_prompt"] || false
    
    # Create initial image params
    image_params = %{
      description: request_params["description"],
      style_preset: request_params["style_preset"] || "photographic",
      model_name: model_name,
      aspect_ratio: request_params["aspect_ratio"] || "2:3"
    }

    Logger.info("Creating image with params: #{inspect(image_params)}")
    Logger.info("Use custom prompt: #{use_custom_prompt}")

    # Create the image record and generate the actual image
    with {:ok, %Image{} = image} <- Media.create_image_from_api(conn.assigns[:current_user], image_params),
         {:ok, updated_image} <- generate_image(image, %{use_custom_prompt: use_custom_prompt}) do
      
      # Deduct litcoins after successful generation
      Logger.info("Removing #{floor(price_for_model)} litcoins")
      Accounts.remove_litcoins(conn.assigns[:current_user], floor(price_for_model))

      # Return the created image
      conn
      |> put_status(:created)
      |> put_resp_header("location", ~p"/api/v1/images/#{updated_image}")
      |> render(:show, image: updated_image)
    else
      {:error, :payment_required} ->
        conn
        |> put_status(:payment_required)
        |> put_view(LitcoversWeb.ErrorJSON)
        |> render(:"402")
        
      {:error, reason} ->
        Logger.error("Failed to create image: #{inspect(reason)}")
        conn
        |> put_status(:unprocessable_entity)
        |> put_view(LitcoversWeb.ErrorJSON)
        |> render(:"422", errors: %{detail: "Failed to generate image: #{inspect(reason)}"})
    end
  end

  # Private function to generate the image using our new Generator module
  defp generate_image(%Image{} = image, options) do
    # Prepare options for the generator
    generation_options = %{
      model_name: image.model_name,
      style_preset: image.style_preset,
      aspect_ratio: image.aspect_ratio,
      use_custom_prompt: Map.get(options, :use_custom_prompt, false)
    }
    
    # Call the generator to create the image
    case Generator.generate_image(image.description, generation_options) do
      {:ok, result} ->
        # Update the image record with the result
        image_params = %{
          url: result.url, 
          final_prompt: result.final_prompt,
          completed: true
        }
        
        Logger.info("Generated image successful: #{result.url}")
        
        # Update the image record in the database
        changeset = Image.ai_changeset(image, image_params)
        Repo.update(changeset)
        
      {:error, reason} ->
        # Clean up the image record on failure
        Logger.error("Error occurred while generating, deleting image: #{inspect(reason)}")
        Media.delete_image(image)
        {:error, reason}
    end
  end
end
