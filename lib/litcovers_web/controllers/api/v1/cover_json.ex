defmodule LitcoversWeb.V1.CoverJSON do
  alias Litcovers.Media.Cover

  @doc """
  Renders a created cover.
  """
  def cover(%{cover: cover}) do
    %{data: cover_data(cover)}
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
