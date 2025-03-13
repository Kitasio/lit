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
    - spine_width: Width of spine in pixels (optional, calculated from pages if not provided)
    - bleed: Add bleed margin as percentage (default: 5%)
    
  Returns `{:ok, url}` on success, or `{:error, reason}` on failure.
  """
  def generate_cover(image_id, options \\ %{}) do
    with {:ok, image} <- get_image(image_id),
         {:ok, image_bytes} <- fetch_image_content(image.url),
         {width, height} <- get_image_dimensions(image_bytes),
         enriched_options = enrich_options(image, width, height, options),
         {:ok, cover_bytes} <-
           CoverGen.Providers.Dreamstudio.outpaint(image_bytes, enriched_options),
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
      image = Litcovers.Media.get_image_preload_all!(image_id)
      {:ok, image}
    rescue
      Ecto.NoResultsError -> {:error, :not_found}
    end
  end

  # Fetch the binary content of the image
  def fetch_image_content(url) do
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
  defp enrich_options(image, width, height, options) do
    # Convert string keys to atoms for consistency
    options = normalize_options(options)

    # If left margin is not set, use the image width as default
    # This creates a balanced book cover where the back cover is the same width as the front
    options =
      if is_nil(options[:left]) do
        Map.put(options, :left, width)
      else
        options
      end

    # Add spine width if not provided but pages is
    options = add_spine_width(options, width)

    # Add bleed margin if requested (default 5%)
    options = add_bleed_margin(options, width, height)

    # Process the prompt with OAI.send using :outpaint atom
    options = process_outpaint_prompt(options, image)

    # Return the enriched options
    options
  end

  # Convert string keys to atom keys for consistency
  defp normalize_options(options) do
    Enum.reduce(options, %{}, fn
      {key, value}, acc when is_binary(key) -> Map.put(acc, String.to_atom(key), value)
      {key, value}, acc -> Map.put(acc, key, value)
    end)
  end

  # Get image dimensions from metadata or estimate based on aspect ratio
  defp get_image_dimensions(image_bytes) do
    {_, width, height, _} = ExImageInfo.info(image_bytes)
    {width, height}
  end

  # Calculate spine width based on pages or set default
  defp add_spine_width(options, image_width) do
    cond do
      # Use provided spine width
      not is_nil(options[:spine_width]) ->
        options

      # Calculate from pages
      not is_nil(options[:pages]) ->
        pages = options[:pages]
        # Formula: 0.0025 inches per page * DPI (300)
        spine_width = max(round(pages * 0.0025 * 300), 30)
        Map.put(options, :spine_width, spine_width)

      # Default to 10% of image width
      true ->
        Map.put(options, :spine_width, max(round(image_width * 0.1), 30))
    end
  end

  # Add bleed margins to all sides if requested
  defp add_bleed_margin(options, width, height) do
    bleed_percent = options[:bleed] || 5

    if bleed_percent > 0 do
      bleed_x = round(width * bleed_percent / 100)
      bleed_y = round(height * bleed_percent / 100)

      # Add bleed to all sides
      options
      |> Map.update(:left, bleed_x, &(&1 + bleed_x))
      |> Map.update(:right, bleed_x, &(&1 + bleed_x))
      |> Map.update(:up, bleed_y, &(&1 + bleed_y))
      |> Map.update(:down, bleed_y, &(&1 + bleed_y))
    else
      options
    end
  end

  # Process the prompt with OAI.send using :outpaint atom
  defp process_outpaint_prompt(options, image) do
    original_prompt =
      if is_nil(options[:prompt]) && !is_nil(image.final_prompt) do
        image.final_prompt
      else
        options[:prompt]
      end

    if is_nil(original_prompt) do
      # No prompt available, return options as is
      options
    else
      # Process the prompt with OAI.send using :outpaint atom
      messages = [%{role: "user", content: original_prompt}]

      case CoverGen.OAIChat.send(messages, System.get_env("OAI_TOKEN"), :outpaint) do
        {:ok, response} ->
          # Update the prompt with the processed version
          Map.put(options, :prompt, response["content"])

        {:error, reason} ->
          Logger.error("Failed to process outpaint prompt: #{inspect(reason)}")
          # Fall back to original prompt
          Map.put(options, :prompt, original_prompt)
      end
    end
  end
end
