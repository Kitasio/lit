defmodule CoverGen.Generator do
  @moduledoc """
  Main interface for generating images across different providers.
  This module handles the routing of requests to the appropriate provider 
  and manages the generation workflow.
  """
  
  require Logger
  alias CoverGen.OAIChat
  alias CoverGen.Spaces
  alias CoverGen.ProviderRegistry

  @doc """
  Generate an image based on the description, style, and model preferences.
  Handles the complete process from prompt refinement to image storage.
  
  Options:
  - model_name: The model to use for generation (default: "sd3")
  - style_preset: The style preset to apply (default: "photographic")
  - aspect_ratio: The aspect ratio for the image (default: "2:3")
  - use_custom_prompt: Boolean to use the description as-is without enhancement (default: false)
  
  Returns `{:ok, image_url}` on success or `{:error, reason}` on failure.
  """
  def generate_image(description, options \\ %{}) do
    # Support both string and atom keys
    options = convert_keys_to_atoms(options)
    
    model_name = Map.get(options, :model_name, "sd3")
    style_preset = Map.get(options, :style_preset, "photographic")
    aspect_ratio = Map.get(options, :aspect_ratio, "2:3")
    use_custom_prompt = Map.get(options, :use_custom_prompt, false)
    
    with {:ok, provider} <- ProviderRegistry.get_provider_for_model(model_name),
         # Get the prompt - either enhanced or use original as-is
         {:ok, final_prompt} <- get_final_prompt(description, style_preset, use_custom_prompt),
         # Log the final prompt
         _ = Logger.info("Final prompt: #{final_prompt}"),
         # Prepare parameters for the provider
         provider_options = %{
           model_name: model_name,
           style_preset: style_preset,
           aspect_ratio: aspect_ratio
         },
         params = provider.prepare_params(final_prompt, provider_options),
         # Generate the image
         {:ok, image_bytes} <- provider.generate(params),
         # Save the image
         {:ok, image_url} <- Spaces.save_bytes(image_bytes) do
      
      {:ok, %{url: image_url, final_prompt: final_prompt}}
    else
      {:error, :unknown_model} ->
        {:error, "Unknown model: #{model_name}"}
      
      {:error, reason} ->
        Logger.error("Image generation failed: #{inspect(reason)}")
        {:error, reason}
    end
  end
  
  # Get the final prompt based on user preference
  defp get_final_prompt(description, _style_preset, true) do
    Logger.info("Using original prompt as-is (custom prompt mode)")
    {:ok, description}
  end
  
  defp get_final_prompt(description, style_preset, false) do
    Logger.info("Enhancing prompt with AI")
    enhance_prompt(description, style_preset)
  end

  # Helper to convert string keys to atoms in a map
  defp convert_keys_to_atoms(map) when is_map(map) do
    Map.new(map, fn
      {key, value} when is_binary(key) -> {String.to_atom(key), value}
      {key, value} -> {key, value}
    end)
  end
  
  # Handle the case where options is not a map
  defp convert_keys_to_atoms(not_map), do: not_map
  
  @doc """
  Enhance a user prompt with AI assistance to create an optimal prompt for image generation.
  """
  def enhance_prompt(description, style_preset) do
    message = "#{description} => #{style_preset}"
    messages = [%{role: "user", content: message}]
    
    case OAIChat.send(messages, System.get_env("OAI_TOKEN"), :creation) do
      {:ok, response} -> 
        {:ok, response["content"]}
      
      {:error, reason} ->
        Logger.error("Failed to enhance prompt: #{inspect(reason)}")
        # Fall back to original description if enhancement fails
        {:ok, description}
    end
  end
end