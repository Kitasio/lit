defmodule CoverGen.Dreamstudio.Model do
  alias HTTPoison.Response
  require Elixir.Logger

  @endpoint "https://api.stability.ai/v2beta/stable-image/generate/sd3"

  # Returns a list of image links
  def diffuse(_params, nil),
    do:
      raise("DREAMSTUDIO_TOKEN was not set\nVisit https://beta.dreamstudio.ai/account to get it")

  def diffuse(params, dreamstudio_token) do
    params = Map.put(params, "output_format", "jpeg")

    headers = [
      {"Accept", "image/*"},
      {"Authorization", "Bearer #{dreamstudio_token}"}
    ]

    options = [timeout: 50_000, recv_timeout: 165_000]

    Logger.info("Generating image")

    body = {:multipart, Map.to_list(params)}

    case HTTPoison.post(@endpoint, body, headers, options) do
      {:ok, response} ->
        %Response{body: image_bytes} = response
        {:ok, image_bytes}
    
      {:error, reason} ->
        Logger.error("Post request to replicate failed: #{inspect(reason)}")
        {:error, :sdxl_failed, "failed post request"}
    end
  end

  def get_params(prompt, aspect_ratio, model) do
    %{
      "prompt" => prompt,
      "model" => model,
      "aspect_ratio" => aspect_ratio,
    }
  end

  def get_params(prompt, width, height, model) do
    %{
      "prompt" => prompt,
      "model" => model,
      "aspect_ratio" => calculate_aspect_ratio(width, height),
    }
  end

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
end
