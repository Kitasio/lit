defmodule CoverGen.Replicate.Input do
  @derive Jason.Encoder
  defstruct prompt: "multicolor hyperspace",
            negative_prompt: "three heads, three faces, fingers, hands, four heads, four faces",
            width: 512,
            height: 768,
            num_outputs: 1,
            guidance_scale: 10,
            disable_safety_check: true
end
