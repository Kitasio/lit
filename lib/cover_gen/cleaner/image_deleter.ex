defmodule CoverGen.Cleaner.ImageDeleter do
  alias Litcovers.Media
  require Logger
  use Task, restart: :transient

  def start_link(_arg) do
    Task.start_link(&loop/0)
  end

  defp loop do
    Logger.info("ImageDeleter doing work")

    Media.list_old_images()
    |> Flow.from_enumerable(max_demand: 5)
    |> Flow.map(fn image ->
      delete(image)
    end)
    |> Flow.run()

    Process.sleep(:timer.hours(1))
    loop()
  end

  defp delete(image) do
    unless image.unlocked do
      Logger.info("deleting image, id: #{image.id}")
      Media.delete_image(image)

      if image.url do
        CoverGen.Spaces.delete_object(image.url)
      end
    end
  end
end
