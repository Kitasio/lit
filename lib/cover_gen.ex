defmodule CoverGen do
  require Logger
  
  def create_new(args) do
    args =
      Keyword.put(
        args,
        :state_holder_name,
        {:via, Registry, {CoverGen.Registry, key: random_job_id()}}
      )

    child_spec =
      Supervisor.child_spec({CoverGen.Worker.CreatorSupervisor, args},
        type: :supervisor,
        shutdown: 30_000
      )

    DynamicSupervisor.start_child(CoverGen.Runner, child_spec)
  end

  def correct(args) do
    args =
      Keyword.put(
        args,
        :state_holder_name,
        {:via, Registry, {CoverGen.Registry, key: random_job_id()}}
      )

    child_spec =
      Supervisor.child_spec({CoverGen.Worker.CorrectorSupervisor, args},
        type: :supervisor,
        shutdown: 30_000
      )

    DynamicSupervisor.start_child(CoverGen.Runner, child_spec)
  end

  defp random_job_id do
    :crypto.strong_rand_bytes(5) |> Base.url_encode64(padding: false)
  end
  
  @doc """
  Generate a book cover by outpainting an existing image.
  
  ## Parameters
  - image_id: The ID of the source image
  - options: A map containing outpaint parameters:
    - left: Pixels to extend left (default: image width)
    - right: Pixels to extend right (default: 0)
    - up: Pixels to extend up (default: 0)
    - down: Pixels to extend down (default: 0)
    - prompt: Text prompt to guide the outpainting (default: uses original image prompt)
    - pages: Number of pages to calculate spine width (optional)
    
  Returns `{:ok, url}` on success, or `{:error, reason}` on failure.
  """
  def generate_cover(image_id, options \\ %{}) do
    with {:ok, image} <- get_image(image_id),
         {:ok, image_bytes} <- fetch_image_content(image.url),
         enriched_options = enrich_options(image, options),
         {:ok, cover_bytes} <- CoverGen.Providers.Dreamstudio.outpaint(image_bytes, enriched_options),
         {:ok, cover_url} <- CoverGen.Spaces.save_bytes(cover_bytes) do
      
      {:ok, %{url: cover_url}}
    else
      {:error, :not_found} ->
        {:error, "Image not found"}
        
      {:error, reason} ->
        Logger.error("Failed to generate cover: #{inspect(reason)}")
        {:error, reason}
    end
  end
  
  # Fetch image data from the database
  defp get_image(image_id) do
    try do
      image = Litcovers.Media.get_image!(image_id)
      {:ok, image}
    rescue
      Ecto.NoResultsError -> {:error, :not_found}
    end
  end
  
  # Fetch the binary content of the image
  defp fetch_image_content(url) do
    case HTTPoison.get(url) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        {:ok, body}
        
      {:ok, %HTTPoison.Response{status_code: status_code}} ->
        {:error, "Failed to download image: HTTP #{status_code}"}
        
      {:error, %HTTPoison.Error{reason: reason}} ->
        {:error, "Failed to download image: #{inspect(reason)}"}
    end
  end
  
  # Enhance the options with information from the image
  defp enrich_options(image, options) do
    # If left margin is not set, use the image width as default
    # This creates a balanced book cover where the back cover is the same width as the front
    options = cond do
      # Use image width if available
      is_nil(options["left"]) && is_nil(options[:left]) && not is_nil(image.width) ->
        Map.put(options, :left, image.width)
      
      # Set a reasonable default if image width is not available
      is_nil(options["left"]) && is_nil(options[:left]) && is_nil(image.width) ->
        Map.put(options, :left, 512)  # Standard size
        
      true ->
        options
    end
    
    # Use the original prompt if no prompt is provided
    if is_nil(options["prompt"]) && is_nil(options[:prompt]) && !is_nil(image.final_prompt) do
      Map.put(options, :prompt, image.final_prompt)
    else
      options
    end
  end
end
