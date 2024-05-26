defmodule LitcoversWeb.V1.ImageController do
  alias CoverGen.Spaces
  alias CoverGen.OAIChat
  alias Litcovers.Repo
  alias Litcovers.Media.Image
  alias Litcovers.Media
  use LitcoversWeb, :controller

  action_fallback LitcoversWeb.FallbackController

  def index(conn, _params) do
    images = Media.list_user_images(conn.assigns[:current_user])
    render(conn, :index, images: images)
  end

  def show(conn, %{"id" => id}) do
    image = Media.get_user_image!(conn.assigns[:current_user], id)
    render(conn, :show, image: image)
  end

  def create(conn, request_params) do
    IO.inspect(request_params, label: "request_params")
    image_params = %{
      description: request_params["prompt"],
      style_preset: request_params["style"],
      model_name: request_params["model"] || "sd3",
      aspect_ratio: request_params["aspect_ratio"] || "2:3"
    }
    IO.inspect(image_params, label: "image_params")
    with {:ok, %Image{} = image} <- Media.create_image_from_api(conn.assigns[:current_user], image_params) do
      updated_image = generate_image(image)

      conn
      |> put_status(:created)
      |> put_resp_header("location", ~p"/api/v1/images/#{updated_image}")
      |> render(:show, image: updated_image)
    end
  end

  defp generate_image(%Image{} = image) do
    message = "#{image.description} => #{image.style_preset}"
    messages = [%{role: "user", content: message}]
    {:ok, res} = OAIChat.send(messages, System.get_env("OAI_TOKEN"), :creation)
    IO.inspect(res, label: "OAI res")

    IO.inspect(res["content"], label: "updating final_prompt with OAI res content")
    {:ok, image} = Media.update_image(image, %{final_prompt: res["content"]})

    params =
      CoverGen.Dreamstudio.Model.get_params(
        res["content"],
        image.aspect_ratio,
        image.model_name
      )
    IO.inspect(params, label: "Dreamstudio params")

    {:ok, image_bytes} =
      CoverGen.Dreamstudio.Model.diffuse(
        params,
        System.get_env("DREAMSTUDIO_TOKEN")
      )
    image_url = Spaces.save_bytes(image_bytes)
    IO.inspect(image_url, label: "image_url")
    image_params = %{url: image_url, completed: true}
    IO.inspect(image_params, label: "image_params")

    {:ok, updated_image} = 
      image
      |> Image.ai_changeset(image_params)
      |> Repo.update()

    IO.inspect(updated_image, label: "updated_image")
    updated_image
  end
end
