defmodule CoverGen.Replicate.Model do
  alias CoverGen.Replicate.Model
  alias CoverGen.Replicate.Input

  @derive Jason.Encoder
  defstruct version: "9936c2001faa2194a261c01381f90e65261879985476014a0a37a334593a05eb",
            input: %Input{}

  def new("stable-diffusion") do
    %Model{
      version: "8abccf52e7cba9f6e82317253f4a3549082e966db5584e92c808ece132037776",
      input: %Input{
        prompt: ""
      }
    }
  end

  def new("couple5") do
    %Model{
      version: "41aa15ac9c83035da10c7b4472cabd7638964b1f47f39e8c7d6132d9e1b80e7f",
      input: %Input{
        prompt: "a cjw "
      }
    }
  end

  def new("portraitplus") do
    %Model{
      version: "629a9fe82c7979c1dab323aedac2c03adaae2e1aecf6be278a51fde0245e20a4",
      input: %Input{
        prompt: ""
      }
    }
  end

  def new("openjourney") do
    %Model{
      version: "9936c2001faa2194a261c01381f90e65261879985476014a0a37a334593a05eb",
      input: %Input{
        prompt: "mdjrny-v4 style "
      }
    }
  end

  def list_all do
    [
      %{
        name: "stable-diffusion",
        img: "https://ik.imagekit.io/soulgenesis/litnet/setting.jpg",
        link:
          "https://replicate.com/stability-ai/stable-diffusion/versions/8abccf52e7cba9f6e82317253f4a3549082e966db5584e92c808ece132037776",
        version: "8abccf52e7cba9f6e82317253f4a3549082e966db5584e92c808ece132037776"
      },
      %{
        name: "couple5",
        img: "https://ik.imagekit.io/soulgenesis/litnet/couple.jpg",
        link: "https://replicate.com/kitasio/couple5",
        version: "41aa15ac9c83035da10c7b4472cabd7638964b1f47f39e8c7d6132d9e1b80e7f"
      },
      %{
        name: "portraitplus",
        img:
          "https://replicate.delivery/pbxt/nsv3z04pENLwCJFCNoKOCCpzPwmYBJX2YBFCB9eagHLNfdXQA/out-0.png",
        link:
          "https://replicate.com/cjwbw/portraitplus/versions/629a9fe82c7979c1dab323aedac2c03adaae2e1aecf6be278a51fde0245e20a4",
        version: "629a9fe82c7979c1dab323aedac2c03adaae2e1aecf6be278a51fde0245e20a4"
      },
      %{
        name: "openjourney",
        img:
          "https://replicate.delivery/pbxt/VueyYHELjzV9WiveDN9TfybM57OXpuC66hQUms0uJHioCVAgA/out-0.png",
        link:
          "https://replicate.com/prompthero/openjourney/versions/9936c2001faa2194a261c01381f90e65261879985476014a0a37a334593a05eb",
        version: "9936c2001faa2194a261c01381f90e65261879985476014a0a37a334593a05eb"
      }
    ]
  end
end
