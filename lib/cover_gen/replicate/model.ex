defmodule CoverGen.Replicate.Model do
  alias CoverGen.Replicate.Model
  alias CoverGen.Replicate.Input
  alias HTTPoison.Response
  require Logger
  import LitcoversWeb.Gettext

  @derive Jason.Encoder
  defstruct version: nil,
            model: nil,
            input: %Input{}

  @request_options [timeout: 50_000, recv_timeout: 165_000]
  @base_url "https://api.replicate.com/v1"

  @doc """
  Generate images using Replicate API.
  Returns a list of image links on success.
  """
  def generate(params) do
    token = get_api_token()
    
    # Format the request body based on the endpoint type
    {endpoint, formatted_params} = format_request(params)
    
    body = Jason.encode!(formatted_params)
    headers = request_headers(token)

    Logger.info("Generating images with Replicate")
    Logger.debug("Request params: #{inspect(formatted_params, pretty: true)}")

    with {:ok, response} <- HTTPoison.post(endpoint, body, headers, @request_options),
         {:ok, data} <- Jason.decode(response.body) do
      
      case extract_generation_url(data) do
        {:ok, nil, direct_output} -> 
          # Direct output URL in the response
          Logger.info("Generation completed immediately with direct output")
          {:ok, %{"output" => direct_output, "status" => "succeeded"}}
          
        {:ok, generation_url} -> 
          # Need to poll for results
          poll_for_results(generation_url, headers)
          
        {:error, reason} -> 
          {:error, :generation_failed, reason}
      end
    else
      {:error, %HTTPoison.Error{} = error} ->
        Logger.error("Request to Replicate failed: #{inspect(error)}")
        {:error, :api_request_failed, "Failed to connect to Replicate API"}
      
      {:error, %Jason.DecodeError{} = error} ->
        Logger.error("Failed to decode Replicate response: #{inspect(error)}")
        {:error, :invalid_response, "Invalid response from Replicate API"}
      
      {:error, reason} ->
        {:error, :generation_failed, reason}
    end
  end

  defp extract_generation_url(%{"urls" => %{"get" => url}}), do: {:ok, url}
  defp extract_generation_url(%{"output" => url}) when is_binary(url), do: {:ok, nil, url}
  defp extract_generation_url(%{"id" => id}) when is_binary(id), do: {:ok, "#{@base_url}/predictions/#{id}"}
  defp extract_generation_url(%{"error" => error}) when not is_nil(error), do: {:error, error}
  defp extract_generation_url(response), do: 
    {:error, "Missing generation URL in response: #{inspect(response, pretty: true)}"}

  @doc """
  Poll for generation results until completion or failure.
  """
  defp poll_for_results(generation_url, headers) do
    case HTTPoison.get(generation_url, headers, @request_options) do
      {:ok, %Response{body: body}} ->
        case Jason.decode(body) do
          {:ok, %{"error" => error}} when not is_nil(error) ->
            Logger.error("Replicate error: #{error}")
            {:error, :generation_failed, error}

          {:ok, %{"output" => output, "status" => "succeeded"}} ->
            Logger.info("Generation succeeded with direct output")
            {:ok, %{"output" => output, "status" => "succeeded"}}

          {:ok, %{"status" => status} = response} ->
            handle_generation_status(status, response, generation_url, headers)

          {:error, error} ->
            Logger.error("Failed to decode Replicate response: #{inspect(error)}")
            {:error, :invalid_response, "Failed to decode Replicate response"}
        end

      {:error, error} ->
        Logger.error("Failed to poll Replicate: #{inspect(error)}")
        {:error, :polling_failed, "Failed to check generation status"}
    end
  end

  defp handle_generation_status("starting", _response, generation_url, headers) do
    Logger.debug("Generation starting")
    Process.sleep(:timer.seconds(2))
    poll_for_results(generation_url, headers)
  end

  defp handle_generation_status("processing", _response, generation_url, headers) do
    Logger.debug("Generation processing")
    Process.sleep(:timer.seconds(1))
    poll_for_results(generation_url, headers)
  end

  defp handle_generation_status("succeeded", response, _generation_url, _headers) do
    Logger.info("Generation succeeded")
    {:ok, response}
  end

  defp handle_generation_status("failed", _response, _generation_url, _headers) do
    Logger.warn("Generation failed")
    {:error, :generation_failed, "Image generation failed, please try again"}
  end

  defp handle_generation_status(unknown_status, _response, _generation_url, _headers) do
    Logger.warn("Unknown generation status: #{unknown_status}")
    {:error, :unknown_status, "Unknown generation status: #{unknown_status}"}
  end

  @doc """
  Get API token from environment or application config.
  Raises an error if token is not set.
  """
  defp get_api_token do
    token = System.get_env("REPLICATE_TOKEN") || 
            Application.get_env(:cover_gen, :replicate_token)
    
    unless token do
      raise "REPLICATE_TOKEN was not set\nVisit https://replicate.com/account to get it"
    end
    
    token
  end

  defp request_headers(token) do
    [
      Authorization: "Token #{token}", 
      "Content-Type": "application/json",
      Accept: "application/json"
    ]
  end
  
  # Format the request based on the model type (official vs versioned)
  defp format_request(params) do
    case {params[:model], params[:version]} do
      {model_id, nil} when is_binary(model_id) ->
        # Check if it's an official model format (contains "/")
        if String.contains?(model_id, "/") do
          # Official model format (e.g., "black-forest-labs/flux-1.1-pro")
          endpoint = "#{@base_url}/models/#{model_id}/predictions"
          formatted_params = %{input: params[:input]}
          {endpoint, formatted_params}
        else
          # Regular model without version
          endpoint = "#{@base_url}/predictions"
          {endpoint, params}
        end
        
      {nil, version} when is_binary(version) ->
        # Legacy versioned model
        endpoint = "#{@base_url}/predictions"
        {endpoint, params}
        
      _ ->
        # Default case
        endpoint = "#{@base_url}/predictions"
        {endpoint, params}
    end
  end

  @doc """
  Create parameters for a model with the given inputs.
  """
  def create_params(model_name, prompt, neg_prompt, width, height) do
    model = create_model(model_name)

    case model do
      %{model: "black-forest-labs/flux-1.1-pro"} ->
        # Flux model has different parameters
        %{
          model: "black-forest-labs/flux-1.1-pro",
          input: %{
            prompt: prompt,
            aspect_ratio: aspect_ratio_from_dimensions(width, height),
            output_format: "webp",
            output_quality: 80,
            safety_tolerance: 2,
            prompt_upsampling: true,
            # Add negative prompt if provided
            negative_prompt: neg_prompt || Input.universal_neg_prompt()
          }
        }
        
      %{model: model_id} when not is_nil(model_id) ->
        # Other official models
        %{
          model: model_id,
          input: %{
            prompt: prompt,
            negative_prompt: neg_prompt || Input.universal_neg_prompt(),
            width: width,
            height: height
          }
        }

      %{version: version} when not is_nil(version) ->
        # Legacy model format with version
        %{
          version: version,
          input: %{
            prompt: prompt,
            negative_prompt: neg_prompt || Input.universal_neg_prompt(),
            width: width,
            height: height
          }
        }
    end
  end

  # Helper to convert width/height to aspect ratio string
  defp aspect_ratio_from_dimensions(width, height) do
    case {width, height} do
      {w, h} when w == h -> "1:1"
      {w, h} when w > h and w / h == 16 / 9 -> "16:9"
      {w, h} when h > w and h / w == 16 / 9 -> "9:16"
      {w, h} when w > h and w / h == 4 / 3 -> "4:3"
      {w, h} when h > w and h / w == 4 / 3 -> "3:4"
      {w, h} when w > h and w / h == 3 / 2 -> "3:2"
      {w, h} when h > w and h / w == 3 / 2 -> "2:3"
      {w, h} when w > h -> "16:9"  # Default to 16:9 for landscape
      {w, h} when h > w -> "9:16"  # Default to 9:16 for portrait
      _ -> "1:1"  # Default to square
    end
  end

  @doc """
  Create a model struct for the given model name.
  """
  def create_model("flux") do
    %Model{
      model: "black-forest-labs/flux-1.1-pro",
      input: %{
        prompt: "",
        aspect_ratio: "1:1",
        output_format: "webp",
        output_quality: 80,
        safety_tolerance: 2,
        prompt_upsampling: true
      }
    }
  end

  def create_model("couple5") do
    %Model{
      version: "41aa15ac9c83035da10c7b4472cabd7638964b1f47f39e8c7d6132d9e1b80e7f",
      input: %Input{
        prompt: "a cjw "
      }
    }
  end

  def create_model("portraitplus") do
    %Model{
      version: "629a9fe82c7979c1dab323aedac2c03adaae2e1aecf6be278a51fde0245e20a4",
      input: %Input{
        prompt: ""
      }
    }
  end

  def create_model("openjourney") do
    %Model{
      version: "9936c2001faa2194a261c01381f90e65261879985476014a0a37a334593a05eb",
      input: %Input{
        prompt: "mdjrny-v4 style "
      }
    }
  end

  def create_model("stable-diffusion") do
    %Model{
      version: "27b93a2413e7f36cd83da926f3656280b2931564ff050bf9575f1fdf9bcd7478",
      input: %Input{
        prompt: ""
      }
    }
  end

  # Default is stable-diffusion
  def create_model(nil) do
    %Model{
      version: "27b93a2413e7f36cd83da926f3656280b2931564ff050bf9575f1fdf9bcd7478",
      input: %Input{
        prompt: ""
      }
    }
  end

  @doc """
  List all available models with their details.
  """
  def list_all do
    [
      %{
        name: "flux",
        enabled: true,
        img: "https://replicate.delivery/pbxt/4JkBvuGSgJkOlQFMveiwGWC3Vw8JrWLjV6Vf7FqrZGzYeQHIA/output.webp",
        link: "https://replicate.com/black-forest-labs/flux-1.1-pro",
        model: "black-forest-labs/flux-1.1-pro",
        label: gettext("Flux Pro"),
        description: gettext("High quality image generation with excellent composition")
      },
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

  @doc """
  Cancel an ongoing prediction.
  """
  def cancel(prediction_id) do
    token = get_api_token()
    body = Jason.encode!(%{})
    headers = request_headers(token)
    endpoint = "#{@base_url}/predictions/#{prediction_id}/cancel"

    Logger.info("Canceling prediction: #{prediction_id}")

    case HTTPoison.post(endpoint, body, headers, @request_options) do
      {:ok, response} ->
        Logger.info("Cancel response: #{inspect(response.status_code)}")
        {:ok, response.status_code}
      
      {:error, error} ->
        Logger.error("Failed to cancel prediction: #{inspect(error)}")
        {:error, :cancel_failed, "Failed to cancel prediction"}
    end
  end
end
