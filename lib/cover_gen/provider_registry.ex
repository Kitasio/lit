defmodule CoverGen.ProviderRegistry do
  @moduledoc """
  Registry for image generation providers.

  This module maintains a mapping of model names to their respective provider modules.
  It allows for dynamic resolution of the appropriate provider for a given model request.
  """

  require Logger

  @doc """
  Get the provider module for a given model name.

  Returns `{:ok, provider_module}` if found, or `{:error, :unknown_model}` if not found.
  """
  def get_provider_for_model(model_name) do
    case Enum.find(provider_mapping(), fn {_provider, models} -> model_name in models end) do
      {provider, _models} -> {:ok, provider}
      nil -> {:error, :unknown_model}
    end
  end

  @doc """
  Get all available models across all providers.

  Returns a list of model names.
  """
  def list_all_models do
    provider_mapping()
    |> Enum.flat_map(fn {_provider, models} -> models end)
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
    provider_mapping()
    |> Enum.map(fn {provider, _models} -> provider end)
  end

  # Map providers to their supported models
  def provider_mapping do
    [
      {CoverGen.Providers.Dreamstudio, ["sd3", "core", "ultra"]},
      {CoverGen.Providers.Replicate, ["flux"]}
    ]
  end
end
