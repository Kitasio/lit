defmodule CoverGen.OAIChat do
  alias CoverGen.OAIChat
  alias HTTPoison.Response
  require Elixir.Logger

  @derive Jason.Encoder
  defstruct max_tokens: 255,
            model: "gpt-3.5-turbo",
            temperature: 1,
            messages: []

  defp endpoint_settings(oai_token) do
    endpoint = "https://api.openai.com/v1/chat/completions"

    # Set headers and options
    headers = [Authorization: "Bearer #{oai_token}", "Content-Type": "application/json"]
    options = [timeout: 40_000, recv_timeout: 40_000]

    {endpoint, headers, options}
  end

  def send(messages, oai_token, :creation) do
    {endpoint, headers, options} = endpoint_settings(oai_token)

    messages = creation_messages() ++ messages

    oai_params = %OAIChat{messages: messages, model: "gpt-4"}
    body = Jason.encode!(oai_params)

    # Send the post request
    case HTTPoison.post(endpoint, body, headers, options) do
      {:ok, %Response{body: res_body}} ->
        message = oai_response_chat(res_body) || ""

        {:ok, message}

      {:error, reason} ->
        IO.inspect(reason)
        Logger.error("Open AI gen idea failed")
        {:error, :oai_failed}
    end
  end

  def send(messages, model, oai_token) do
    {endpoint, headers, options} = endpoint_settings(oai_token)

    messages = default_messages() ++ messages

    Logger.info("Using OAI model: #{model}")
    oai_params = %OAIChat{model: model, messages: messages}
    body = Jason.encode!(oai_params)

    # Send the post request
    case HTTPoison.post(endpoint, body, headers, options) do
      {:ok, %Response{body: res_body}} ->
        message = oai_response_chat(res_body) || ""

        {:ok, message}

      {:error, reason} ->
        IO.inspect(reason)
        Logger.error("Open AI gen idea failed")
        {:error, :oai_failed}
    end
  end

  defp oai_response_chat(oai_res_body) do
    case Jason.decode(oai_res_body) do
      {:ok, body} ->
        case Map.get(body, "choices") do
          nil ->
            nil

          choices_list ->
            [%{"message" => message} | _] = choices_list

            message
        end

      {:error, reason} ->
        Logger.error("decode oai response body error: #{inspect(reason)}")
        nil
    end
  end

  defp creation_messages do
    [
      %{role: "system", content: "
You come up with prompts to feed to diffusion models, select artists in prompts based on relevance
    "},
      %{role: "user", content: "
Pick words that are relevant both to user prompt and the style chosen, pick two artists where possible and answer only with the prompt and only in English

If user supplies the string `cjw` - add it before the main object of the prompt and convert it to close up portrait where possible

If user describes two persons - use the words `cjw couple`

A a young woman with red hair => Photorealism cjw
    "},
      %{role: "assistant", content: "
A close up portrait of a young cjw woman with red hair, agfa vista 4 0 0 photograph, synth vibe, cold vaporwave colors, lens flare, moody lighting, moody vibe, telephoto, 9 0 s vibe, blurry background, grain, tranquil, calm, faded, by Annie Leibovitz and Herb Ritts
     "},
      %{role: "user", content: "
писатель - родственник дьявола. один желает получить душу, другой жаждет внимания. и неизвестно, чья одержимость сильнее => Post-impressionism
    "},
      %{role: "assistant", content: "
A man standing with a shadow of a demon with horns, oil on canvas, bold brushstrokes, vibrant colors, thick impasto, playful composition, dynamic movement, textured background, warm and bright lighting, by Vincent van Gogh and Paul Gauguin
     "},
      %{role: "user", content: "
Девушка с каштановыми волсами и сером платье на коленях стоит в пещере. Рядом с ней мужчина злой маг в черном плаще и красными глазами. => Digital art cjw
    "},
      %{role: "assistant", content: "
A close-up portrait of a cjw couple in a dark cave, digital art, woman with brown hair and a gray dress, man with glowing red eyes and a black cape, dramatic lighting, detailed textures, contrasting colors, mysterious atmosphere, by Dan LuVisi and Charlie Bowater.
     "},
      %{role: "user", content: "
Магический кабинет с зельями, артефактами, склянками, книгами, черным котом => Flat illustration
    "},
      %{role: "assistant", content: "
A flat illustration of a magical cabinet, with various bottles, potions, books, and a black cat, colorful and whimsical design, simple geometric shapes and lines, pastel, and muted color scheme, by Shoko Ishida and Margaret Altamirano.
     "},
      %{role: "user", content: "
a red-haired young lady noblewoman in the palace of the Russian Empire at the beginning of the 19th century => Oil on canvas cjw
    "},
      %{role: "assistant", content: "
An oil on canvas cjw close up portrait of a young noblewoman with red hair in the palace of the Russian Empire at the beginning of the 19th century, realistic and detailed, rich and warm colors, elegant and refined attire, traditional and classic composition, by Konstantin Makovsky and Pyotr Sokolov.
     "}
    ]
  end

  defp default_messages do
    [
      %{role: "system", content: "
      You help modify prompts that were created for AI diffusion models, you answer with the prompt and only in English
    "},
      %{role: "user", content: "
      Adjust the artists if user is looking for style changes

      If the user asks to emphasize something or says he doesn't get it in the image - rearrange your response putting the desired object at the start of the sentence 

      If user supplies the string `cjw` - add it before the main object of the prompt

      If the user says something that doesen't make sense - ignore it and return the prompt without changes, answer only with the prompt and only in English

      A young Slavic couple, with the girl having a freckled face, long reddish hair and green eyes, and the boy having black hair, black eyes and pale skin, in dark armor, stand together, artwork by tooth wu and wlop and alena aenami and greg rutkowski 

      Let's make the girl without freckles and make her blonde
    "},
      %{role: "assistant", content: "
      A young Slavic couple, with the girl having a pretty face, long blonde hair and green eyes, and the boy having black hair, black eyes and pale skin, in dark armor, stand together, artwork by tooth wu and wlop and alena aenami and greg rutkowski 
    "},
      %{role: "user", content: "
      do a close up shot
    "},
      %{role: "assistant", content: "
      A close up portrait of a young Slavic couple, with the girl having a pretty face, long blonde hair and green eyes, and the boy having black hair, black eyes and pale skin, in dark armor, stand together, artwork by tooth wu and wlop and alena aenami and greg rutkowski
    "},
      %{role: "user", content: "
      make it more uplifting and illustrative
    "},
      %{role: "assistant", content: "
      A close up portrait of a young Slavic couple, with the girl having a pretty face, long blonde hair and green eyes, and the boy having black hair, black eyes and pale skin, in dark armor, stand together, smooth blend, modern impressionistic abstract painting, thick painting, palette knife and brush strokes, desaturated colors studio ghibli, artstation, concept art, behance, ray tracing, smooth, ethereal lighting
    "},
      %{role: "user", content: "
      Reminder: You are a model trained to return prompts, you answer with a prompt only, and nothing else

      A magical castle stands in front of the king and queen, surrounded by autumn trees, medieval times, Soft and warm light and colors, by greg rutkowski, by greg tocchini 

      make it summer
    "},
      %{role: "assistant", content: "
      A magical castle stands in front of the king and queen, surrounded by lush summer trees, in medieval times, with soft and warm light and vibrant colors, artwork by Greg Rutkowski, Greg Tocchiniand and Rob Moline.
    "},
      %{role: "user", content: "
        lets add a river
    "},
      %{role: "assistant", content: "
      A magical castle stands in front of the king and queen, surrounded by lush summer trees and a serene river, in medieval times, with soft and warm light and vibrant colors, artwork by Greg Rutkowski, Daubigny and Rob Moline.
    "},
      %{role: "user", content: "
        сделай картинку более темной и страшной
    "},
      %{role: "assistant", content: "
      A haunting castle stands in front of the king and queen, surrounded by ominous summer trees and a dark, mysterious river, in medieval times, with somber and eerie light and colors, artwork by Julian Calle and Roman Kuteynikov.
    "},
      %{role: "user", content: "
        не вижу короля с королевой
    "},
      %{role: "assistant", content: "
      A king and queen with a haunting castle stands in the background, surrounded by ominous summer trees and a dark, mysterious river, in medieval times, with somber and eerie light and colors, artwork by Julian Calle and Roman Kuteynikov.
    "},
      %{role: "user", content: "
        make it more photorealistic
    "},
      %{role: "assistant", content: "
      A king and queen with an ultra-realistic depiction of a haunting castle in the background, surrounded by ominous summer trees and a dark, mysterious river, in medieval times, with lifelike and somber light and colors, artwork by Kyle Thompson and Roman Kuteynikov.
    "}
    ]
  end
end
