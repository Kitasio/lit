defmodule CoverGen.OAIChat do
  alias CoverGen.OAIChat
  alias HTTPoison.Response
  require Elixir.Logger

  @derive Jason.Encoder
  defstruct max_tokens: 255,
            model: "gpt-4o-mini",
            temperature: 1,
            messages: []

  defp endpoint_settings(oai_token) do
    endpoint = "https://api.openai.com/v1/chat/completions"

    # Set headers and options
    headers = [Authorization: "Bearer #{oai_token}", "Content-Type": "application/json"]
    options = [timeout: 40_000, recv_timeout: 40_000]

    {endpoint, headers, options}
  end

  def translate(words, oai_token) when is_bitstring(words) do
    {endpoint, headers, options} = endpoint_settings(oai_token)

    messages = [
      %{
        role: "user",
        content: "Translate to English if needed, answer only with the translation\n\n#{words}"
      }
    ]

    oai_params = %OAIChat{messages: messages, temperature: 0.1}
    body = Jason.encode!(oai_params)

    # Send the post request
    case HTTPoison.post(endpoint, body, headers, options) do
      {:ok, %Response{body: res_body}} ->
        message = oai_response_chat(res_body) || ""

        %{"content" => content} = message
        content

      {:error, reason} ->
        IO.inspect(reason)
        Logger.error("Open AI gen idea failed")
        {:error, :oai_failed}
    end
  end

  def send(messages, oai_token, :creation) do
    {endpoint, headers, options} = endpoint_settings(oai_token)

    messages = creation_messages() ++ messages

    oai_params = %OAIChat{messages: messages}
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

A good prompt needs to be detailed and specific. A good process is to look through a list of keyword categories and decide whether you want to use any of them.

The keyword categories are

    Subject
    Medium
    Style
    Artist
    Website
    Resolution
    Additional details
    Color
    Lighting


A a young woman with red hair, a powerful mysterious sorceress, casting lightning magic => Digital painting
    "},
      %{role: "assistant", content: "
A young woman with red hair, a powerful mysterious sorceress, casting lightning magic, detailed clothing, digital painting, hyperrealistic, fantasy, Surrealist, full body, by Stanley Artgerm Lau and Alphonse Mucha, artstation, highly detailed, sharp focus, sci-fi, stunningly beautiful, dystopian, iridescent gold, cinematic lighting, dark
     "},
      %{role: "user", content: "
Магический кабинет с зельями, артефактами, склянками, книгами, черным котом => Flat Illustration
    "},
      %{role: "assistant", content: "
A magical cabinet, filled with various bottles, potions, books, and a curious black cat, flat illustration, minimalistic, modern design, by Mary Blair and Charley Harper, behance, clean lines, simple shapes, vibrant colors, whimsical, playful, mysterious, well-organized, limited color palette, soft lighting, slightly abstract
     "},
      %{role: "user", content: "
A red-haired young lady noblewoman in the palace of the Russian Empire at the beginning of the 19th century => Oil on canvas
    "},
      %{role: "assistant", content: "
A red-haired young lady noblewoman, elegantly dressed, standing in the grand palace of the Russian Empire at the beginning of the 19th century, oil on canvas, exquisite detail, historical, Romanticism, by Ilya Repin and Ivan Aivazovsky, fineartamerica, full-length portrait, sumptuous interior, luxurious fabrics, intricate patterns, rich colors, dramatic lighting, regal bearing
     "},
      %{role: "user", content: "
Девушка с каштановыми волсами и сером платье на коленях стоит в пещере. Рядом с ней мужчина злой маг в черном плаще и красными глазами. => Digital art
    "},
      %{role: "assistant", content: "
A girl with chestnut hair, wearing a knee-length gray dress, standing in a dimly lit cave, accompanied by a sinister male sorcerer in a black cloak and red eyes, digital art, fantasy, dark atmosphere, by H.R. Giger and Gerald Brom, artstation, contrasting characters, detailed textures, tension-filled, cold color scheme, eerie lighting, ominous presence
     "},
      %{role: "user", content: "
писатель - родственник дьявола. один желает получить душу, другой жаждет внимания. и неизвестно, чья одержимость сильнее => Arcane (League of Legends)
    "},
      %{role: "assistant", content: "
A man standing with a shadow of a demon with horns, digital art, inspired by League of Legends' Arcane series, dark fantasy, by Christian Fell and Riot Games Art Team, artstation, dramatic scene, intense emotions, magical aura, sinister atmosphere, vivid colors, dynamic lighting, power struggle
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
