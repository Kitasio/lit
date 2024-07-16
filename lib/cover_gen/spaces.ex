defmodule CoverGen.Spaces do
  require Elixir.Logger

  # Takes a list of image urls and saves them to DO spaces returning an imagekit url
  def save_to_spaces([]), do: []

  def save_to_spaces([url | img_list]) do
    Logger.info("Saving to spaces: #{url}")
    options = [timeout: 50_000, recv_timeout: 50_000]

    imagekit_url = Application.get_env(:litcovers, :imagekit_url)
    bucket = Application.get_env(:litcovers, :bucket)
    filename = "#{Ecto.UUID.generate()}.png"

    case HTTPoison.get(url, [], options) do
      {:error, reason} ->
        {:error, reason}

      {:ok, %HTTPoison.Response{body: image_bytes}} ->
        ExAws.S3.put_object(bucket, filename, image_bytes) |> ExAws.request!()

        image_url = Path.join(imagekit_url, filename)
        [image_url | save_to_spaces(img_list)]
    end
  end

  def save_bytes(image_bytes) do
    imagekit_url = Application.get_env(:litcovers, :imagekit_url)
    bucket = Application.get_env(:litcovers, :bucket)
    filename = "#{Ecto.UUID.generate()}.png"

    case ExAws.S3.put_object(bucket, filename, image_bytes) |> ExAws.request() do
      {:ok, _} ->
        image_url = Path.join(imagekit_url, filename)
        {:ok, image_url}

      {:error, reason} ->
        Logger.error(reason, label: "S3 error")
        {:error, reason}
    end
  end

  def delete_object(url) do
    bucket = Application.get_env(:litcovers, :bucket)
    filename = Path.basename(url)
    ExAws.S3.delete_object(bucket, filename) |> ExAws.request!()
  end
end
