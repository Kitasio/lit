defmodule CoverGen.Dreamstudio.Model do
  alias HTTPoison.Response
  require Elixir.Logger

  @sd3_endpoint "https://api.stability.ai/v2beta/stable-image/generate/sd3"
  @core_endpoint "https://api.stability.ai/v2beta/stable-image/generate/core"
  @ultra_endpoint "https://api.stability.ai/v2beta/stable-image/generate/ultra"
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

  # Returns a list of image links
  def diffuse(_params, nil),
    do:
      raise("DREAMSTUDIO_TOKEN was not set\nVisit https://beta.dreamstudio.ai/account to get it")

  def diffuse(params, dreamstudio_token) do
    headers = [
      {"Accept", "image/*"},
      {"Authorization", "Bearer #{dreamstudio_token}"}
    ]

    body = {:multipart, Map.to_list(params)}

    case HTTPoison.post(endpoint(params["model"]), body, headers, @options) do
      {:ok, %Response{status_code: status_code, body: body}}
      when status_code in 200..299 ->
        Logger.info("DREAMSTUDIO Response: #{inspect(body)}")
        {:ok, body}

      {:ok, %Response{status_code: status_code, body: body}} ->
        Logger.error("Unexpected status code (#{status_code}): #{inspect(body)}")
        {:error, "Unexpected status code: #{status_code}"}

      {:error, reason} ->
        Logger.error("Post request to dreamstudio failed: #{inspect(reason)}")
        {:error, "failed post request"}
    end
  end

  def get_params(prompt, aspect_ratio, model, style_preset) do
    %{
      "prompt" => prompt,
      "model" => model,
      "aspect_ratio" => aspect_ratio,
      "style_preset" => validate_style_preset(style_preset)
    }
  end

  def get_params(prompt, width, height, model, style_preset) do
    %{
      "prompt" => prompt,
      "model" => model,
      "aspect_ratio" => calculate_aspect_ratio(width, height),
      "style_preset" => validate_style_preset(style_preset)
    }
  end

  defp validate_style_preset(style_preset) when style_preset in @valid_style_presets,
    do: style_preset

  defp validate_style_preset(_), do: "enhance"

  defp gcd(a, b) when b == 0, do: a
  defp gcd(a, b), do: gcd(b, rem(a, b))

  # Function to calculate the aspect ratio
  defp calculate_aspect_ratio(width, height) do
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
end
