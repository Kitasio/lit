defmodule CoverGen.Replicate.Input do
  @derive Jason.Encoder
  defstruct prompt: "multicolor hyperspace",
            negative_prompt:
              "ugly, tiling, poorly drawn hands, poorly drawn feet, poorly drawn face, out of frame, extra limbs, disfigured, deformed, body out of frame, bad anatomy, watermark, signature, cut off, low contrast, underexposed, overexposed, bad art, beginner, amateur, distorted face, blurry, draft, grainy",
            width: 512,
            height: 768,
            num_outputs: 1,
            guidance_scale: 10,
            disable_safety_check: true
end
