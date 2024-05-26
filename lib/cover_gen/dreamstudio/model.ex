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

  def get_params(prompt, width, height, style_preset) do
    %{
      text_prompts: [
        %{
          text: prompt
        }
      ],
      cfg_scale: 3..7 |> Enum.random(),
      clip_guidance_preset: "FAST_BLUE",
      height: height,
      width: width,
      samples: 1,
      steps: 20..40 |> Enum.random(),
      style_preset: style_preset,
    }
  end
end
