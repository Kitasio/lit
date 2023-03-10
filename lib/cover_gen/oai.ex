defmodule CoverGen.OAI do
  alias CoverGen.OAI
  alias HTTPoison.Response
  require Elixir.Logger

  @derive Jason.Encoder
  defstruct prompt: "Hello mr robot",
            max_tokens: 255,
            model: "text-davinci-003",
            temperature: 1

  # Returns a prompt for stable diffusion
  def description_to_cover_idea(_description, _cover_type, _gender, nil),
    do: raise("OAI_TOKEN was not set\nVisit https://beta.openai.com/account/api-keys to get it")

  def description_to_cover_idea(description, cover_type, gender, oai_token) do
    # Set Open AI endpoint
    endpoint = "https://api.openai.com/v1/completions"

    # Set headers and options
    headers = [Authorization: "Bearer #{oai_token}", "Content-Type": "application/json"]
    options = [timeout: 40_000, recv_timeout: 40_000]

    # Append description to preamble
    prompt = description |> preamble(gender, cover_type)

    # Prepare params for Open AI
    oai_params = %OAI{prompt: prompt, temperature: 1}
    body = Jason.encode!(oai_params)

    Logger.info("Generatig idea with Open AI")
    # Send the post request
    case HTTPoison.post(endpoint, body, headers, options) do
      {:ok, %Response{body: res_body}} ->
        ideas = oai_response_text(res_body)
        {:ok, ideas}

      {:error, reason} ->
        IO.inspect(reason)
        Logger.error("Open AI gen idea failed")
        {:error, :oai_failed}
    end
  end

  defp preamble(input, _gender, :couple) do
    "Suggest a 4 book cover ideas, every idea depicts a couple, man and woman on some kind of background, separate ideas with commas

    Description: A student teenage girl moves into a new city and finds her life turned upside-down when she falls in love with a beautiful young vampire.
    Book cover ideas: Beautiful student girl and handsome pale vampire with a dark grey forest in the background, A vampire man with a red glowing eyes and a pretty woman iside a dark apartment, Passionate woman with a pale skin and dark haired handsome man on a red abstract background, beautiful girl with her eyes closed and her partner hugging her with a dark misty field in the background

    Description: Christian understood that the two things one needs to be successful are power and control. His relationship with Ana perfectly encapsulates the ideology of the story’s portrayal of dominance and control.
    Book cover ideas: A pretty woman in a red night dress and a man in black suite in a modern room, A strong handome man wearing a white shirt and a woman in the office, strong male protagonist with bright blue eyes hugging a pretty woman with long hair, a woman in silk dress kissing a handsome man

    Description: #{input}
    Book cover ideas:"
  end

  defp preamble(input, _gender, :setting) do
    "Suggest a 4 book cover ideas, use objects and landscapes to describe it, separate ideas with commas

    Description: Time machine in the shape of a car accidentally sends our heroes from our modern world into the times of the wild west, into a small dusty cowboy town in the middle of the desert.
    Book cover ideas: Dusty wild west city of cowboys with a modern car in the middle of the street, bright white beams of light coming from the inside of a wild west saloon in the desert, a car tracks on the ground inside a wild west town street, A giant canyon with the old wild west city inside of it.

    Description: The story starts in nowadays London and than continues into majestic medieval fantasy hidden world of magic and wizarding, into the giant gothic castle with hundreds of secrets to be discovered.
    Book cover ideas: A giant magical gothic castle in the woods, A beautiful night castle with a lot of high towers hidden in the mist, A fantasy world with a giant castle made of stone, A giant hall of a medieval magical castle

    Description: The future world of high technologies isn’t bright - it’s cruel and ruthless. The story starts in the night club located in the heart of the futuristic megapolis.
    Book cover ideas: The night streets of a futuristic city, Cyberpunk night club party, Dirty high-tech night club interior, Abandoned bar inside a scyscrapper

    Description: #{input}
    Book cover ideas:"
  end

  defp preamble(input, "male", :portrait) do
    "Suggest 4 book cover ideas, every idea depicts a portrait of a man on some kind of background, separated by a comma

    Description: Old scientist with crazy sunglasses creates a time machine in a form of a car and travels back in time with his student, they try to change the future
    Book cover ideas: A scientist in a white coat inside of a high-tech mechanism, A handsome man wearing crazy glasses with cosmos and stars behind him, A mad professor and vivid blue electricity sparks everywhere around him, An attractive student with a dirty face inside of a car

    Description: The story of a vampire king from Transylvania, he ruled his kingdom for days, and drank people's blood at night
    Book cover ideas: A dark and handsome vampire with long hair in a dark gothic castle, A strong pale man wearing a long coat under the rain in a medieval city, A mysterious unknown in a dark hall of a castle, A dark prince with his face covered in blood on a bright red abstract background

    Description: #{input}
    Book cover ideas:"
  end

  defp preamble(input, "female", :portrait) do
    "Suggest 4 book cover ideas, every idea depicts portrait of a woman located in some kind of a setting, separated by a comma

    Description: A student teenage girl moves into a new city and finds her life turned upside-down when she falls in love with a beautiful young vampire.
    Book cover ideas: Beautiful student with a dark grey forest in the background, A vampire with a red glowing eyes iside a dark apartment, Passionate woman with a pale skin on a red abstract background, beautiful girl with her eyes closed with a dark misty field in the background

    Description: A girl-archer living in a poor district of the future city is selected by lottery to compete in a televised battle royale to the death.
    Book cover ideas: A serious woman with a dirty face in a dark green forest, A strong young hero with scratches on her face with the explosion on the background, Protagonist with bright blue eyes in a mysterious forest at night, An archer princess within a ruined city

    Description: #{input}
    Book cover ideas:"
  end

  defp preamble(input, _, _) do
    input
  end

  defp oai_response_text(oai_res_body) do
    %{"choices" => choices_list} = Jason.decode!(oai_res_body)
    [%{"text" => text} | _] = choices_list

    text
    |> String.split("output:")
    |> List.last()
    |> String.trim()
    |> String.split("\n")
    |> List.first()
    |> String.split(",")
  end
end
