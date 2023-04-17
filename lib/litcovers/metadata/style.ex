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
        name: gettext("Mosaic"),
        url:
          "https://replicate.delivery/pbxt/ROfwu41C6QU2XaOZJ0enMRRzYeC2HTNJ5edkkpcOYcQBW0KDB/out-0.png"
      },
      %{
        name: gettext("Ink art"),
        url: "https://ik.imagekit.io/soulgenesis/cats/cccc.jpg"
      },
      %{
        name: gettext("Impressionism"),
        url:
          "https://replicate.delivery/pbxt/57NeKDnfTWofBJAS9DQHBBd9BapriDf0sPGHrWrvc2ccqzKDB/out-0.png"
      },
      %{
        name: gettext("Renaissance"),
        url:
          "https://replicate.delivery/pbxt/6mz7bmoqumK9JlwhsSfXNmgNss2gIj2t2jzfeKzANvTfH2KDB/out-0.png"
      },
      %{
        name: gettext("Watercolor illustration"),
        url:
          "https://replicate.delivery/pbxt/UWPQ5karSRLuF1ibJVuWFusPYfZ1g9rot7Y2MZOnYHdpyWZIA/out-0.png"
      },
      %{
        name: gettext("Pop Art"),
        url:
          "https://replicate.delivery/pbxt/EbvBTH2ZkZLhENyM6QneuV3BVr73qnvA2R57S72qB2HemtyQA/out-0.png"
      },
      %{
        name: gettext("Pencil drawing"),
        url:
          "https://replicate.delivery/pbxt/fAJNiOlJJ0yHJCm8mjS4mqQiUG3bbUjoDhFnSrJjIb7r0WZIA/out-0.png"
      },
      %{
        name: gettext("Concept art"),
        url:
          "https://replicate.delivery/pbxt/bD581LwS5hp1AZdDLgKEVDPSKQAS1aQkryHCXRvMmWZodrME/out-0.png"
      },
      %{
        name: gettext("Arcane (League of Legends)"),
        url:
          "https://replicate.delivery/pbxt/QIfInFWq8fpOakQ1x4ybIn44e6l3spuCLn39gWaCH7ufi3KDB/out-0.png"
      },
      %{
        name: gettext("Cyberpunk"),
        url:
          "https://replicate.delivery/pbxt/QeEob9PcQjTZWaAH04Iu1dH6hTLLXe5laXrH9GffP59xq3KDB/out-0.png"
      },
      %{
        name: gettext("Minimalism"),
        url:
          "https://replicate.delivery/pbxt/W4i6ifnoxsx0cSBsYYII8dZAmhr79hdieOXp6kzevFok4blhA/out-0.png"
      },
      %{
        name: gettext("Anime"),
        url:
          "https://replicate.delivery/pbxt/c2OqWmlxrcaXC5SUMAPCu691ErPBqneE3tKz0QSGunTXftyQA/out-0.png"
      },
      %{
        name: gettext("Oil on canvas"),
        url:
          "https://replicate.delivery/pbxt/vg9izfvG1gVPJCOaD59XVep69I8AeliWuTZbZBIe3NXUG4KDB/out-0.png"
      },
      %{
        name: gettext("Photorealism"),
        url:
          "https://replicate.delivery/pbxt/1oXc1zhaaloiKJKxAisaq0xHaRXpQTF6vRRgrfOUGZl4FXZIA/out-0.png"
      },
      %{
        name: gettext("Metal Etchings"),
        url:
          "https://replicate.delivery/pbxt/P4zZBDQZYgqACBGymVgBwfl6fyFwYl1DFMO05c3h8vbrDuyQA/out-0.png"
      },
      %{
        name: gettext("Vector illustration"),
        url:
          "https://replicate.delivery/pbxt/zPx4cRDtLS5GIVZ0wFlXhPnUIWGfu4ItKwZIeXLEOGJwFuyQA/out-0.png"
      },
      %{
        name: gettext("Pointillism"),
        url:
          "https://replicate.delivery/pbxt/4G1se5F4KfqOAU58Mmbw5fgn0Iw63eIXIeviBrCDiExd7wVGC/out-0.png"
      }
    ]
  end
end
