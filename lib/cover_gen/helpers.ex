defmodule CoverGen.Helpers do
  require Elixir.Logger

  def create_prompt(idea_prompt, style_prompt, gender, :portrait) do
    "#{random_portrait(gender)}, #{idea_prompt}, #{style_prompt}"
  end

  def create_prompt(idea_prompt, style_prompt, _gender, :setting) do
    "#{idea_prompt}, #{style_prompt}"
  end

  def create_prompt(idea_prompt, style_prompt, _gender, :couple) do
    "a cjw couple closeup, #{idea_prompt}, #{style_prompt}"
  end

  defp random_portrait(gender) do
    [
      "A cjw close up portrait of a #{gender_to_naming(gender)}",
      "A cjw symmetrical face portrait of a #{gender_to_naming(gender)}"
    ]
    |> Enum.random()
  end

  defp gender_to_naming(gender) do
    case gender do
      "male" ->
        "man"

      "female" ->
        "woman"
    end
  end
end
