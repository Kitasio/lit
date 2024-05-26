defmodule LitcoversWeb.V1.ImageJSON do
  alias Litcovers.Media.Image

  @doc """
  Renders a list of images.
  """
  def index(%{images: images}) do
    %{data: for(img <- images, do: data(img))}
  end

  @doc """
  Renders a single image.
  """
  def show(%{image: image}) do
    %{data: data(image)}
  end

  defp data(%Image{} = image) do
    %{
      id: image.id,
      completed: image.completed,
      url: image.url,
      final_prompt: image.final_prompt,
      prompt: image.description,
      style: image.style_preset,
      aspect_ratio: image.aspect_ratio,
      model: image.model_name
    }
  end
end
