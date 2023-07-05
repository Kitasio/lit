defmodule CoverGen.Dreamstudio.Model do
  alias HTTPoison.Response
  require Elixir.Logger

  # Returns a list of image links
  def diffuse(_params, nil),
    do:
      raise("DREAMSTUDIO_TOKEN was not set\nVisit https://beta.dreamstudio.ai/account to get it")

  def diffuse(params, dreamstudio_token) do
    body = Jason.encode!(params)

    headers = [
      Authorization: "Bearer #{dreamstudio_token}",
      "Content-Type": "application/json",
      Accept: "image/png"
    ]

    options = [timeout: 50_000, recv_timeout: 165_000]

    endpoint =
      "https://api.stability.ai/v1/generation/stable-diffusion-xl-1024-v0-9/text-to-image"

    Logger.info("Generating image")

    case HTTPoison.post(endpoint, body, headers, options) do
      {:ok, response} ->
        %Response{body: image_bytes} = response
        {:ok, image_bytes}

      {:error, reason} ->
        Logger.error("Post request to replicate failed: #{inspect(reason)}")
        {:error, :sdxl_failed, "failed post request"}
    end
  end

  def get_params(prompt, width, height) do
    %{
      text_prompts: [
        %{
          text: prompt
        }
      ],
      cfg_scale: 3..10 |> Enum.random(),
      clip_guidance_preset: "FAST_BLUE",
      height: height,
      width: width,
      samples: 1,
      steps: 20..45 |> Enum.random(),
    }
  end
end
