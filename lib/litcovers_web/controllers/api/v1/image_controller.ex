defmodule LitcoversWeb.V1.ImageController do
  alias Litcovers.Accounts
  alias CoverGen.Spaces
  alias CoverGen.OAIChat
  alias Litcovers.Repo
  alias Litcovers.Media.Image
  alias Litcovers.Media
  use LitcoversWeb, :controller

  require Logger

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
    model_name = request_params["model"] || "sd3"

    if model_name not in CoverGen.Models.all() do
      conn
      |> put_status(:bad_request)
      |> put_view(LitcoversWeb.ErrorJSON)
      |> render(:"400")
    end

    price_for_model = CoverGen.Models.price(conn.assigns[:current_user], model_name)

    if conn.assigns[:current_user].litcoins < price_for_model do
      conn
      |> put_status(:payment_required)
      |> put_view(LitcoversWeb.ErrorJSON)
      |> render(:"402")
    end

    image_params = %{
      description: request_params["description"],
      style_preset: request_params["style_preset"] || "photographic",
      model_name: model_name,
      aspect_ratio: request_params["aspect_ratio"] || "2:3"
    }

    IO.inspect(image_params, label: "image_params")

    with {:ok, %Image{} = image} <-
           Media.create_image_from_api(conn.assigns[:current_user], image_params) do
      case generate_image(image) do
        {:ok, updated_image} ->
          Logger.info("removing #{floor(price_for_model)} litcoins")
          Accounts.remove_litcoins(conn.assigns[:current_user], floor(price_for_model))

          conn
          |> put_status(:created)
          |> put_resp_header("location", ~p"/api/v1/images/#{updated_image}")
          |> render(:show, image: updated_image)
      end
    end
  end

  defp generate_image(%Image{} = image) do
    with message <- "#{image.description} => #{image.style_preset}",
         messages <- [%{role: "user", content: message}],
         {:ok, res} <- OAIChat.send(messages, System.get_env("OAI_TOKEN"), :creation),
         _ <- IO.inspect(res, label: "OAI res"),
         {:ok, image} <- Media.update_image(image, %{final_prompt: res["content"]}),
         _ <- IO.inspect(res["content"], label: "updating final_prompt with OAI res content"),
         params <-
           CoverGen.Dreamstudio.Model.get_params(
             res["content"],
             image.aspect_ratio,
             image.model_name,
             image.style_preset
           ),
         _ <- IO.inspect(params, label: "Dreamstudio params"),
         {:ok, image_bytes} <-
           CoverGen.Dreamstudio.Model.diffuse(params, System.get_env("DREAMSTUDIO_TOKEN")),
         {:ok, img_url} <- Spaces.save_bytes(image_bytes),
         _ <- IO.inspect(img_url, label: "image_url"),
         image_params <- %{url: img_url, completed: true},
         _ <- IO.inspect(image_params, label: "image_params"),
         changeset <- Image.ai_changeset(image, image_params),
         {:ok, updated_image} <- Repo.update(changeset),
         _ <- IO.inspect(updated_image, label: "updated_image") do
      {:ok, updated_image}
    else
      {:error, reason} ->
        IO.inspect(reason, label: "Error occurred while generating, deleting image")
        Media.delete_image(image)
        {:error, reason}
    end
  end
end
