defmodule CoverGen.Models do
  alias Litcovers.Accounts.User
  alias CoverGen.ProviderRegistry

  @doc """
  Returns all the models available across all providers
  """
  def all() do
    ProviderRegistry.list_all_models()
  end

  @doc """
  Returns the price of the model
  Model pricing can be configured here
  """
  # Dreamstudio models
  def price(%User{} = user, "sd3"), do: floor(16 * user.discount)
  def price(%User{} = user, "core"), do: floor(8 * user.discount)
  def price(%User{} = user, "ultra"), do: floor(20 * user.discount)
  
  # Replicate models
  def price(%User{} = user, "flux"), do: floor(15 * user.discount)
  def price(%User{} = user, "couple5"), do: floor(10 * user.discount)
  def price(%User{} = user, "portraitplus"), do: floor(10 * user.discount)
  def price(%User{} = user, "openjourney"), do: floor(8 * user.discount)
  def price(%User{} = user, "stable-diffusion"), do: floor(8 * user.discount)
  
  # Default for unknown models
  def price(%User{} = user, _model), do: floor(10 * user.discount)

  @doc """
  Returns all models with their respective prices for a given user
  """
  def all_with_price(%User{} = user) do
    all()
    |> Enum.map(fn model -> %{"model" => model, "price" => price(user, model)} end)
  end
  
  @doc """
  Get model details including description and display information
  Combines information from all providers
  """
  def get_model_details(model_name) do
    with {:ok, provider} <- ProviderRegistry.get_provider_for_model(model_name) do
      case provider do
        CoverGen.Providers.Replicate ->
          # For Replicate models, fetch from their list
          find_model_in_list(CoverGen.Providers.Replicate.list_available_models(), model_name)
          
        _other ->
          # For other providers, provide basic info
          %{
            name: model_name,
            enabled: true,
            label: model_name,
            description: "AI image generation model"
          }
      end
    else
      _ -> 
        # Model not found
        nil
    end
  end
  
  defp find_model_in_list(models, model_name) do
    Enum.find(models, fn model -> model.name == model_name end)
  end
end
