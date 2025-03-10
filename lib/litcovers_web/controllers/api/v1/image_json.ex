defmodule LitcoversWeb.V1.ImageJSON do
  alias Litcovers.Media.Image
  alias Litcovers.Media.Cover

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
  
  @doc """
  Renders a created cover.
  """
  def cover(%{cover: cover}) do
    %{data: cover_data(cover)}
  end

  defp data(%Image{} = image) do
    %{
      id: image.id,
      completed: image.completed,
      url: image.url,
      final_prompt: image.final_prompt,
      description: image.description,
      style_preset: image.style_preset,
      aspect_ratio: image.aspect_ratio,
      model_name: image.model_name
    }
  end
  
  defp cover_data(%Cover{} = cover) do
    %{
      id: cover.id,
      url: cover.url,
      image_id: cover.image_id,
      created_at: cover.inserted_at
    }
  end
end
