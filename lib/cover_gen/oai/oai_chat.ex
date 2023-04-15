defmodule CoverGen.OAIChat do
  alias CoverGen.OAIChat
  alias HTTPoison.Response
  require Elixir.Logger

  @derive Jason.Encoder
  defstruct max_tokens: 255,
            model: "gpt-3.5-turbo",
            temperature: 0.7,
            messages: []

  def send(messages, oai_token) do
    endpoint = "https://api.openai.com/v1/chat/completions"

    # Set headers and options
    headers = [Authorization: "Bearer #{oai_token}", "Content-Type": "application/json"]
    options = [timeout: 40_000, recv_timeout: 40_000]

    messages = default_messages() ++ messages

    oai_params = %OAIChat{model: "gpt-4", messages: messages}
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

  defp default_messages do
    [
      %{role: "system", content: "
      You help modify prompts that were created for AI diffusion models, you answer with the prompt and only in English

      Adjust the artists if user is looking for style changes

      If the user asks to emphasize something or says he doesn't get it in the image - rearrange your response putting the desired object at the start of the sentence 

      If the user says something that doesen't make sense - ignore it and return the prompt without changes
    "},
      %{role: "user", content: "
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
