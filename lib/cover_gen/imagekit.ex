defmodule CoverGen.Imagekit do
  @bucket "soulgenesis"
  @imagekit_host "ik.imagekit.io"

  def transform(link, transformation) do
    uri = URI.parse(link)
    %URI{host: host, path: path} = uri

    case host do
      @imagekit_host ->
        {filename, list} = path |> String.split("/") |> List.pop_at(-1)

        case Enum.count(list) do
          3 ->
            tr = List.last(list) <> add_tr(transformation, :append)
            create_url(tr, filename)

          2 ->
            tr = add_tr(transformation, :new)
            create_url(tr, filename)

          _ ->
            link
        end

      _ ->
        link
    end
  end

  defp create_url(transformation, filename) do
    Path.join(["https://", @imagekit_host, @bucket, transformation, filename])
  end

  defp add_tr(transformation, :new) do
    "tr:" <> transformation
  end

  defp add_tr(transformation, :append) do
    ":" <> transformation
  end
end
