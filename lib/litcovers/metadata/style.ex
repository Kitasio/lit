defmodule Litcovers.Metadata.Style do
  use Ecto.Schema
  import Ecto.Changeset
  import LitcoversWeb.Gettext

  schema "styles" do
    field :name, :string
    field :url, :string
  end

  @doc false
  def changeset(chat, attrs) do
    chat
    |> cast(attrs, [:name, :url])
    |> validate_required([:name])
    |> validate_length(:name, min: 2, max: 50)
  end

  def list_all do
    [
      %{
        preset: "photographic",
        name: gettext("Photorealism"),
        url:
          "https://replicate.delivery/pbxt/1oXc1zhaaloiKJKxAisaq0xHaRXpQTF6vRRgrfOUGZl4FXZIA/out-0.png"
      },
      %{
        preset: "digital-art",
        name: gettext("Concept art"),
        url:
          "https://replicate.delivery/pbxt/bD581LwS5hp1AZdDLgKEVDPSKQAS1aQkryHCXRvMmWZodrME/out-0.png"
      },
      %{
        preset: "digital-art",
        name: gettext("Arcane (League of Legends)"),
        url:
          "https://replicate.delivery/pbxt/QIfInFWq8fpOakQ1x4ybIn44e6l3spuCLn39gWaCH7ufi3KDB/out-0.png"
      },
      %{
        preset: "neon-punk",
        name: gettext("Cyberpunk"),
        url:
          "https://replicate.delivery/pbxt/QeEob9PcQjTZWaAH04Iu1dH6hTLLXe5laXrH9GffP59xq3KDB/out-0.png"
      },
      %{
        preset: "enhance",
        name: gettext("Watercolor illustration"),
        url:
          "https://replicate.delivery/pbxt/UWPQ5karSRLuF1ibJVuWFusPYfZ1g9rot7Y2MZOnYHdpyWZIA/out-0.png"
      },
      %{
        preset: "enhance",
        name: gettext("Pencil drawing"),
        url:
          "https://replicate.delivery/pbxt/fAJNiOlJJ0yHJCm8mjS4mqQiUG3bbUjoDhFnSrJjIb7r0WZIA/out-0.png"
      },
      %{
        preset: "anime",
        name: gettext("Anime"),
        url:
          "https://replicate.delivery/pbxt/c2OqWmlxrcaXC5SUMAPCu691ErPBqneE3tKz0QSGunTXftyQA/out-0.png"
      },
    ]
  end
end
