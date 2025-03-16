# Guide: Adding a New Model to the System

This guide explains how to add a new AI model to the image generation system. We'll walk through the key files that need to be modified and provide code examples.

## Overview

When adding a new model, you need to:
1. Add the model to the appropriate provider
2. Set up pricing for the model
3. Configure model parameters
4. Test the integration

## Step 1: Identify the Provider

First, determine which provider will host your model. The system currently supports:
- Replicate
- Dreamstudio

For this example, we'll add a new model to the Replicate provider.

## Step 2: Update the Provider's Supported Models List

Edit `lib/cover_gen/providers/replicate.ex` to add your model to the `@supported_models` list:

```elixir
@supported_models [
  "flux",
  "flux-ultra",
  "couple5",
  "portraitplus",
  "openjourney",
  "stable-diffusion",
  "your-new-model"  # Add your model here
]
```

## Step 3: Create Model Parameters Function

In the same file, add a `create_model_params` function for your new model:

```elixir
defp create_model_params("your-new-model", prompt, neg_prompt, width, height, style_preset) do
  %{
    model: "creator/your-new-model-id",  # Replace with actual model ID
    input: %{
      prompt: prompt,
      aspect_ratio: aspect_ratio_from_dimensions(width, height),
      safety_tolerance: 2,
      prompt_upsampling: true,
      negative_prompt: neg_prompt || @universal_neg_prompt
      # Add any other model-specific parameters here
    }
  }
end
```

## Step 4: Add Model to Available Models List

Add your model to the `list_available_models` function in the same file:

```elixir
def list_available_models do
  [
    # Existing models...
    %{
      name: "your-new-model",
      enabled: true,
      img: "https://example.com/model-preview-image.jpg",
      link: "https://replicate.com/creator/your-new-model-id",
      model: "creator/your-new-model-id",
      label: gettext("Your New Model"),
      description: gettext("Description of your new model's capabilities")
    },
    # Other models...
  ]
end
```

## Step 5: Add Model to Replicate Model Module

Edit `lib/cover_gen/replicate/model.ex` to add a `create_model` function for your new model:

```elixir
def create_model("your-new-model") do
  %Model{
    model: "creator/your-new-model-id",
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
```

Also add your model to the `list_all` function in the same file.

## Step 6: Set Pricing for the Model

Edit `lib/cover_gen/models.ex` to add pricing for your new model:

```elixir
# Replicate models
def price(%User{} = user, "flux"), do: floor(15 * user.discount)
def price(%User{} = user, "flux-ultra"), do: floor(25 * user.discount)
def price(%User{} = user, "your-new-model"), do: floor(20 * user.discount)  # Add your model here
```

## Complete Example: Adding "stable-diffusion-xl"

Here's a complete example of adding a new model called "stable-diffusion-xl":

### 1. Update Supported Models List

```elixir
# In lib/cover_gen/providers/replicate.ex
@supported_models [
  "flux",
  "flux-ultra",
  "couple5",
  "portraitplus",
  "openjourney",
  "stable-diffusion",
  "stable-diffusion-xl"  # New model added
]
```

### 2. Create Model Parameters Function

```elixir
# In lib/cover_gen/providers/replicate.ex
defp create_model_params("stable-diffusion-xl", prompt, neg_prompt, width, height, style_preset) do
  %{
    model: "stability-ai/sdxl",
    input: %{
      prompt: prompt,
      negative_prompt: neg_prompt || @universal_neg_prompt,
      width: width,
      height: height,
      num_outputs: 1,
      scheduler: "K_EULER",
      num_inference_steps: 30,
      guidance_scale: 7.5,
      # Use style_preset if provided
      style_preset: style_preset || "photographic"
    }
  }
end
```

### 3. Add to Available Models List

```elixir
# In lib/cover_gen/providers/replicate.ex
def list_available_models do
  [
    # Existing models...
    %{
      name: "stable-diffusion-xl",
      enabled: true,
      img: "https://replicate.delivery/pbxt/4JkBvuGSgJkOlQFMveiwGWC3Vw8JrWLjV6Vf7FqrZGzYeQHIA/output.webp",
      link: "https://replicate.com/stability-ai/sdxl",
      model: "stability-ai/sdxl",
      label: gettext("Stable Diffusion XL"),
      description: gettext("High-resolution image generation with excellent detail and composition")
    },
    # Other models...
  ]
end
```

### 4. Add to Replicate Model Module

```elixir
# In lib/cover_gen/replicate/model.ex
def create_model("stable-diffusion-xl") do
  %Model{
    model: "stability-ai/sdxl",
    input: %{
      prompt: "",
      negative_prompt: "",
      width: 1024,
      height: 1024,
      num_outputs: 1,
      scheduler: "K_EULER",
      num_inference_steps: 30,
      guidance_scale: 7.5
    }
  }
end
```

### 5. Add to list_all Function

```elixir
# In lib/cover_gen/replicate/model.ex
def list_all do
  [
    # Existing models...
    %{
      name: "stable-diffusion-xl",
      enabled: true,
      img: "https://replicate.delivery/pbxt/4JkBvuGSgJkOlQFMveiwGWC3Vw8JrWLjV6Vf7FqrZGzYeQHIA/output.webp",
      link: "https://replicate.com/stability-ai/sdxl",
      model: "stability-ai/sdxl",
      label: gettext("Stable Diffusion XL"),
      description: gettext("High-resolution image generation with excellent detail and composition")
    },
    # Other models...
  ]
end
```

### 6. Set Pricing

```elixir
# In lib/cover_gen/models.ex
def price(%User{} = user, "stable-diffusion-xl"), do: floor(18 * user.discount)
```

## Testing Your New Model

After adding your model, you should test it by:

1. Making a POST request to `/api/v1/images` with your new model name:

```json
{
  "description": "A test image for the new model",
  "model": "stable-diffusion-xl",
  "aspect_ratio": "1:1"
}
```

2. Check the logs for any errors during the request processing
3. Verify the image is generated correctly

## Troubleshooting

If you encounter issues:

1. Add logging to track the request flow:
```elixir
Logger.info("Creating params for your-new-model")
Logger.debug("Model params: #{inspect(params)}")
```

2. Check that the model is correctly registered with the provider:
```elixir
# In iex console
iex> CoverGen.ProviderRegistry.get_provider_for_model("your-new-model")
```

3. Verify the model parameters are correctly formatted for the API

## Summary

Adding a new model involves updating several files to register the model with the system, configure its parameters, and set its pricing. By following this guide, you can easily extend the system with new AI models as they become available.
