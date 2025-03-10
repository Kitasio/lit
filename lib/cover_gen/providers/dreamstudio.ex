defmodule CoverGen.Providers.Dreamstudio do
  @moduledoc """
  Provider implementation for Stability AI's DreamStudio API.
  Supports sd3, core, and ultra models.
  """

  @behaviour CoverGen.ProviderBehaviour

  alias HTTPoison.Response
  require Elixir.Logger

  @sd3_endpoint "https://api.stability.ai/v2beta/stable-image/generate/sd3"
  @core_endpoint "https://api.stability.ai/v2beta/stable-image/generate/core"
  @ultra_endpoint "https://api.stability.ai/v2beta/stable-image/generate/ultra"
  @outpaint_endpoint "https://api.stability.ai/v2beta/stable-image/edit/outpaint"
  @options [timeout: 50_000, recv_timeout: 165_000]

  @valid_style_presets [
    "3d-model",
    "analog-film",
    "anime",
    "cinematic",
    "comic-book",
    "digital-art",
    "enhance",
    "fantasy-art",
    "isometric",
    "line-art",
    "low-poly",
    "modeling-compound",
    "neon-punk",
    "origami",
    "photographic",
    "pixel-art",
    "tile-texture"
  ]

  @supported_models ["sd3", "core", "ultra"]

  @impl CoverGen.ProviderBehaviour
  def generate(params) do
    token = get_api_token()
    diffuse(params, token)
  end

  @impl CoverGen.ProviderBehaviour
  def prepare_params(prompt, options) do
    model = Map.get(options, :model_name, "sd3")
    aspect_ratio = Map.get(options, :aspect_ratio, "2:3")
    style_preset = Map.get(options, :style_preset, "photographic")

    %{
      "prompt" => prompt,
      "model" => model,
      "aspect_ratio" => aspect_ratio,
      "style_preset" => validate_style_preset(style_preset)
    }
  end

  @impl CoverGen.ProviderBehaviour
  def list_models, do: @supported_models

  @impl CoverGen.ProviderBehaviour
  def supports_model?(model_name), do: model_name in @supported_models

  # Private functions

  defp get_api_token do
    token =
      System.get_env("DREAMSTUDIO_TOKEN") ||
        Application.get_env(:cover_gen, :dreamstudio_token)

    unless token do
      raise "DREAMSTUDIO_TOKEN was not set\nVisit https://beta.dreamstudio.ai/account to get it"
    end

    token
  end

  # Returns a list of image links
  defp diffuse(params, dreamstudio_token) do
    headers = [
      {"Accept", "image/*"},
      {"Authorization", "Bearer #{dreamstudio_token}"}
    ]

    body = {:multipart, Map.to_list(params)}

    case HTTPoison.post(endpoint(params["model"]), body, headers, @options) do
      {:ok, %Response{status_code: status_code, body: body}}
      when status_code in 200..299 ->
        Logger.info("DREAMSTUDIO Response successful")
        {:ok, body}

      {:ok, %Response{status_code: status_code, body: body}} ->
        Logger.error("Unexpected status code (#{status_code}): #{inspect(body)}")
        {:error, "Unexpected status code: #{status_code}"}

      {:error, reason} ->
        Logger.error("Post request to dreamstudio failed: #{inspect(reason)}")
        {:error, "failed post request"}
    end
  end

  defp validate_style_preset(style_preset) when style_preset in @valid_style_presets,
    do: style_preset

  defp validate_style_preset(_), do: "enhance"

  defp gcd(a, b) when b == 0, do: a
  defp gcd(a, b), do: gcd(b, rem(a, b))

  # Function to calculate the aspect ratio
  def calculate_aspect_ratio(width, height) do
    gcd_value = gcd(width, height)
    aspect_ratio_width = div(width, gcd_value)
    aspect_ratio_height = div(height, gcd_value)
    valid_or_default_ar("#{aspect_ratio_width}:#{aspect_ratio_height}")
  end

  defp valid_or_default_ar("16:9"), do: "16:9"
  defp valid_or_default_ar("1:1"), do: "1:1"
  defp valid_or_default_ar("3:2"), do: "3:2"
  defp valid_or_default_ar("4:5"), do: "4:5"
  defp valid_or_default_ar("5:4"), do: "5:4"
  defp valid_or_default_ar("9:16"), do: "9:16"
  defp valid_or_default_ar("9:21"), do: "9:21"
  defp valid_or_default_ar(_), do: "2:3"

  defp endpoint("core"), do: @core_endpoint
  defp endpoint("ultra"), do: @ultra_endpoint
  defp endpoint(_model), do: @sd3_endpoint

  @doc """
  Outpaint an image to create a book cover with front, spine, and back cover.

  ## Parameters
  - image_bytes: Binary content of the original image
  - options: A map containing outpaint parameters:
    - left: Pixels to extend left (default: image width)
    - right: Pixels to extend right (default: 0)
    - up: Pixels to extend up (default: 0)
    - down: Pixels to extend down (default: 0)
    - prompt: Text prompt to guide the outpainting (default: nil)
    - style_preset: Style preset to use (default: "photographic")
    - pages: Number of pages to calculate spine width (optional)
    - spine_width: Width of spine in pixels (calculated from pages or defaults to 10% of image width)
    - bleed: Percentage of bleed margin to add to all sides (default: 0)
    
  Returns `{:ok, image_bytes}` on success, or `{:error, reason}` on failure.
  """
  def outpaint(image_bytes, options \\ %{}) do
    token = get_api_token()

    # Prepare a map of parameters
    params_map =
      prepare_outpaint_params_map(image_bytes, options) |> IO.inspect(label: "PARAMS MAP")

    # Use a simpler approach for multipart form data
    # Create a boundary string
    boundary =
      "------------------------#{:crypto.strong_rand_bytes(8) |> Base.encode16(case: :lower)}"

    # Build the multipart body manually
    parts =
      Enum.map(Map.to_list(params_map), fn
        {"image", image_data} ->
          """
          --#{boundary}\r
          Content-Disposition: form-data; name="image"; filename="image.png"\r
          Content-Type: image/png\r
          \r
          #{image_data}
          """

        {key, value} ->
          """
          --#{boundary}\r
          Content-Disposition: form-data; name="#{key}"\r
          \r
          #{to_string(value)}
          """
      end)

    # Add the final boundary
    body = Enum.join(parts) <> "--#{boundary}--\r\n"

    # Set the content-type header with the boundary
    headers = [
      {"Accept", "image/*"},
      {"Authorization", "Bearer #{token}"},
      {"Content-Type", "multipart/form-data; boundary=#{boundary}"}
    ]

    case HTTPoison.post(@outpaint_endpoint, body, headers,
           timeout: 50_000,
           recv_timeout: 165_000,
           # Disable automatic encoding since we're handling it manually
           hackney: [force_multipart: false]
         ) do
      {:ok, %Response{status_code: status_code, body: body}}
      when status_code in 200..299 ->
        Logger.info("DREAMSTUDIO Outpaint successful")
        {:ok, body}

      {:ok, %Response{status_code: status_code, body: body}} ->
        Logger.error("Outpaint failed with status code (#{status_code}): #{inspect(body)}")
        {:error, "Outpaint failed with status code: #{status_code}"}

      {:error, reason} ->
        Logger.error("Outpaint request to DreamStudio failed: #{inspect(reason)}")
        {:error, "Failed outpaint request: #{inspect(reason)}"}
    end
  end

  @doc """
  Prepare parameters map for outpainting based on the options provided.

  Handles default values and calculates missing parameters:
  - If left margin is not specified, it defaults to image width 
  - If spine_width is not provided but pages is, calculates spine width
  """
  def prepare_outpaint_params_map(image_bytes, options) do
    # Convert string keys to atoms for consistency
    options =
      if is_map(options) do
        Enum.reduce(options, %{}, fn
          {key, value}, acc when is_binary(key) -> Map.put(acc, String.to_atom(key), value)
          {key, value}, acc -> Map.put(acc, key, value)
        end)
      else
        %{}
      end

    # Start with a map containing the image
    # Ensure image_bytes is binary data
    params = %{"image" => image_bytes}

    # Add outpaint directions as map entries
    left = options[:left]
    right = options[:right] || 0
    up = options[:up] || 0
    down = options[:down] || 0

    # Add direction parameters
    params = if left, do: Map.put(params, "left", to_string(left)), else: params
    params = Map.put(params, "right", to_string(right))
    params = Map.put(params, "up", to_string(up))
    params = Map.put(params, "down", to_string(down))

    # Add optional parameters
    params = if options[:prompt], do: Map.put(params, "prompt", options[:prompt]), else: params
    params = Map.put(params, "creativity", to_string(options[:creativity] || 0.5))

    # Add style preset only if provided
    params =
      if options[:style_preset],
        do: Map.put(params, "style_preset", validate_style_preset(options[:style_preset])),
        else: params

    # Add output format - almost always want png for print quality
    params = Map.put(params, "output_format", options[:output_format] || "png")

    params
  end

  # Legacy function kept for compatibility
  def prepare_outpaint_params(image_bytes, options) do
    prepare_outpaint_params_map(image_bytes, options) |> Map.to_list()
  end
end
