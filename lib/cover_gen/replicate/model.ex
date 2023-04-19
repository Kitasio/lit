defmodule CoverGen.Replicate.Model do
  alias CoverGen.Replicate.Model
  alias CoverGen.Replicate.Input
  alias HTTPoison.Response
  require Elixir.Logger
  import LitcoversWeb.Gettext

  @derive Jason.Encoder
  defstruct version: "27b93a2413e7f36cd83da926f3656280b2931564ff050bf9575f1fdf9bcd7478",
            input: %Input{}

  # Returns a list of image links
  def diffuse(_params, nil),
    do: raise("REPLICATE_TOKEN was not set\nVisit https://replicate.com/account to get it")

  def diffuse(params, replicate_token) do
    body = Jason.encode!(params)
    headers = [Authorization: "Token #{replicate_token}", "Content-Type": "application/json"]
    options = [timeout: 50_000, recv_timeout: 165_000]

    endpoint = "https://api.replicate.com/v1/predictions"

    Logger.info("Generating images")

    case HTTPoison.post(endpoint, body, headers, options) do
      {:ok, response} ->
        %Response{body: res_body} = response

        case Jason.decode(res_body) do
          {:ok, data} ->
            %{"urls" => %{"get" => generation_url}} = data
            check_for_output(generation_url, headers, options)

          {:error, reason} ->
            Logger.error("Decoding replicate data failed: #{inspect(reason)}")
            {:error, :sd_failed, "failed data decoding"}
        end

      {:error, reason} ->
        Logger.error("Post request to replicate failed: #{inspect(reason)}")
        {:error, :sd_failed, "failed post requsrt"}
    end
  end

  defp check_for_output(generation_url, headers, options) do
    case HTTPoison.get(generation_url, headers, options) do
      {:ok, response} ->
        %Response{body: res} = response

        case Jason.decode(res) do
          {:ok, res} ->
            case res["error"] do
              nil ->
                case res["status"] do
                  "starting" ->
                    Logger.debug("Starting")
                    :timer.seconds(2) |> Process.sleep()
                    check_for_output(generation_url, headers, options)

                  "processing" ->
                    Logger.debug("Processing")
                    :timer.seconds(1) |> Process.sleep()
                    check_for_output(generation_url, headers, options)

                  "succeeded" ->
                    Logger.debug("Replicate model succeeded")
                    {:ok, res}

                  "failed" ->
                    Logger.debug("Replicate model failed")
                    {:error, :sd_failed, "Generation failed, try again"}
                end

              error ->
                {:error, :sd_failed, error}
            end

          {:error, reason} ->
            {:error, :sd_failed, "Failed decoding replicate response: #{inspect(reason)}"}
        end

      {:error, reason} ->
        {:error, :sd_failed, "GET request to replicate failed: #{inspect(reason)}"}
    end
  end

  def get_params(model_name, prompt, width, height) do
    model = Model.new(model_name)

    update_in(model.input, fn _input ->
      %Input{
        width: width,
        height: height,
        prompt: prompt
      }
    end)
  end

  def new("couple5") do
    %Model{
      version: "41aa15ac9c83035da10c7b4472cabd7638964b1f47f39e8c7d6132d9e1b80e7f",
      input: %Input{
        prompt: "a cjw "
      }
    }
  end

  def new("portraitplus") do
    %Model{
      version: "629a9fe82c7979c1dab323aedac2c03adaae2e1aecf6be278a51fde0245e20a4",
      input: %Input{
        prompt: ""
      }
    }
  end

  def new("openjourney") do
    %Model{
      version: "9936c2001faa2194a261c01381f90e65261879985476014a0a37a334593a05eb",
      input: %Input{
        prompt: "mdjrny-v4 style "
      }
    }
  end

  def new("stable-diffusion") do
    %Model{
      version: "27b93a2413e7f36cd83da926f3656280b2931564ff050bf9575f1fdf9bcd7478",
      input: %Input{
        prompt: ""
      }
    }
  end

  # Default is stable-diffusion
  def new(nil) do
    %Model{
      version: "27b93a2413e7f36cd83da926f3656280b2931564ff050bf9575f1fdf9bcd7478",
      input: %Input{
        prompt: ""
      }
    }
  end

  def list_all do
    [
      %{
        name: "stable-diffusion",
        enabled: true,
        img: "https://ik.imagekit.io/soulgenesis/litnet/setting.jpg",
        link:
          "https://replicate.com/stability-ai/stable-diffusion/versions/27b93a2413e7f36cd83da926f3656280b2931564ff050bf9575f1fdf9bcd7478",
        version: "27b93a2413e7f36cd83da926f3656280b2931564ff050bf9575f1fdf9bcd7478",
        label: gettext("Setting"),
        description: gettext("Works best with landscapes, buildings, and other objects")
      },
      %{
        name: "couple5",
        enabled: true,
        img: "https://ik.imagekit.io/soulgenesis/litnet/couple.jpg",
        link: "https://replicate.com/kitasio/couple5",
        version: "41aa15ac9c83035da10c7b4472cabd7638964b1f47f39e8c7d6132d9e1b80e7f",
        label: gettext("Faces"),
        description: gettext("Good for depiction of a portrait or a couple")
      },
      %{
        name: "portraitplus",
        enabled: false,
        img:
          "https://replicate.delivery/pbxt/nsv3z04pENLwCJFCNoKOCCpzPwmYBJX2YBFCB9eagHLNfdXQA/out-0.png",
        link:
          "https://replicate.com/cjwbw/portraitplus/versions/629a9fe82c7979c1dab323aedac2c03adaae2e1aecf6be278a51fde0245e20a4",
        version: "629a9fe82c7979c1dab323aedac2c03adaae2e1aecf6be278a51fde0245e20a4"
      },
      %{
        name: "openjourney",
        enabled: false,
        img:
          "https://replicate.delivery/pbxt/VueyYHELjzV9WiveDN9TfybM57OXpuC66hQUms0uJHioCVAgA/out-0.png",
        link:
          "https://replicate.com/prompthero/openjourney/versions/9936c2001faa2194a261c01381f90e65261879985476014a0a37a334593a05eb",
        version: "9936c2001faa2194a261c01381f90e65261879985476014a0a37a334593a05eb"
      }
    ]
  end

  def cancel(prediction_id, replicate_token) do
    body = Jason.encode!(%{})
    headers = [Authorization: "Token #{replicate_token}", "Content-Type": "application/json"]
    options = [timeout: 50_000, recv_timeout: 165_000]

    endpoint = "https://api.replicate.com/v1/predictions/#{prediction_id}/cancel"

    Logger.info("Canceling: #{prediction_id}")

    res = HTTPoison.post(endpoint, body, headers, options)
    IO.inspect(res)
  end
end
