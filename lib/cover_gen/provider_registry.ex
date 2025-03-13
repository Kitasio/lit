defmodule CoverGen.ProviderRegistry do
  @moduledoc """
  Registry for image generation providers.

  This module maintains a mapping of model names to their respective provider modules.
  It allows for dynamic resolution of the appropriate provider for a given model request.
  """

  require Logger

  # Define providers to check
  @providers [
    CoverGen.Providers.Replicate,
    CoverGen.Providers.Dreamstudio
  ]

  @doc """
  Get the provider module for a given model name.

  Returns `{:ok, provider_module}` if found, or `{:error, :unsupported_model}` if not found.
  """
  def get_provider_for_model(model_name) do
    Logger.info("Looking for provider for model: #{model_name}")
    
    provider =
      @providers
      |> Enum.find(fn provider -> 
        supports = provider.supports_model?(model_name)
        Logger.debug("Provider #{inspect(provider)} supports #{model_name}: #{supports}")
        supports
      end)

    case provider do
      nil -> 
        Logger.error("No provider found for model: #{model_name}")
        {:error, :unsupported_model}
      provider -> 
        Logger.info("Found provider for #{model_name}: #{inspect(provider)}")
        {:ok, provider}
    end
  end

  @doc """
  Get all available models across all providers.

  Returns a list of model names.
  """
  def list_all_models do
    @providers
    |> Enum.flat_map(fn provider -> provider.list_models() end)
    |> Enum.uniq()
  end

  @doc """
  Check if a model is available from any provider.

  Returns boolean.
  """
  def model_exists?(model_name) do
    model_name in list_all_models()
  end

  @doc """
  List all registered providers with their supported models.

  Returns a list of provider modules.
  """
  def list_providers do
    @providers
  end
end
