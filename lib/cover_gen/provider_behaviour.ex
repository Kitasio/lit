defmodule CoverGen.ProviderBehaviour do
  @moduledoc """
  Defines a behaviour for image generation providers.
  This allows for consistent interfaces across different providers (Dreamstudio, Replicate, etc).
  """

  @doc """
  Generate an image with the given parameters.
  
  Returns `{:ok, image_bytes}` on success, or `{:error, reason}` on failure.
  """
  @callback generate(params :: map()) :: {:ok, binary()} | {:error, term()}

  @doc """
  Prepare parameters for the provider based on prompt, image dimensions, and other options.
  
  Returns a map of parameters to pass to the generate function.
  """
  @callback prepare_params(
              prompt :: String.t(),
              options :: map()
            ) :: map()

  @doc """
  Get a list of all models supported by this provider.
  
  Returns a list of model identifier strings.
  """
  @callback list_models() :: [String.t()]

  @doc """
  Determine if a model name is supported by this provider.
  
  Returns a boolean.
  """
  @callback supports_model?(model_name :: String.t()) :: boolean()
end