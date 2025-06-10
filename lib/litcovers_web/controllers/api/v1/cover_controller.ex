defmodule LitcoversWeb.V1.CoverController do
  @moduledoc """
  Controller for handling cover generation requests.
  """
  use LitcoversWeb, :controller
  alias Litcovers.Accounts
  alias Litcovers.Media
  alias LitcoversWeb.Plugs
  require Logger

  action_fallback LitcoversWeb.FallbackController

  plug Plugs.ValidateModel, "outpaint" when action in [:create]
  plug Plugs.EnsureEnoughCoins when action in [:create]

  @doc """
  Generates a book cover based on an existing image and provided options.

  Expects the image ID in the `id` parameter and outpainting options in the request body.
  Requires the user to have enough Litcoins.

  Returns the created cover resource.
  """
  def create(conn, params) do
    conn
    |> fetch_image(params)
    |> generate_cover(params)
    |> persist_cover(params)
    |> remove_litcoins(params)
    |> return_cover(params)
  end

  @doc false
  defp fetch_image(conn, %{"id" => id}) do
    Media.get_user_image(conn.assigns[:current_user], id)
    |> handle_get_image(conn)
  end

  @doc false
  defp handle_get_image(nil, conn) do
    conn
    |> put_status(:not_found)
    |> put_view(LitcoversWeb.ErrorJSON)
    |> render(:"404")
    |> halt()
  end

  defp handle_get_image(image, conn) do
    assign(conn, :image, image)
  end

  @doc false
  defp generate_cover(conn, params) do
    outpaint_params = Map.drop(params, ["id"])

    CoverGen.generate_cover(params["id"], outpaint_params)
    |> handle_generate_cover_response(conn)
  end

  @doc false
  defp handle_generate_cover_response({:ok, %{url: cover_url}}, conn) do
    assign(conn, :cover_url, cover_url)
  end

  defp handle_generate_cover_response({:error, :not_found}, conn) do
    conn
    |> put_status(:not_found)
    |> put_view(LitcoversWeb.ErrorJSON)
    |> render(:"404")
    |> halt()
  end

  defp handle_generate_cover_response({:error, reason}, conn) do
    Logger.error("Failed to generate cover: #{inspect(reason)}")

    conn
    |> put_status(:unprocessable_entity)
    |> put_view(LitcoversWeb.ErrorJSON)
    |> render(:"422", errors: %{detail: "Failed to generate cover: #{inspect(reason)}"})
    |> halt()
  end

  @doc false
  defp persist_cover(conn, _params) do
    image = conn.assigns[:image]
    current_user = conn.assigns[:current_user]
    cover_url = conn.assigns[:cover_url]

    Media.create_cover(image, current_user, %{url: cover_url, seen: false})
    |> handle_persist_cover(conn)
  end

  @doc false
  defp handle_persist_cover({:ok, cover}, conn) do
    assign(conn, :cover, cover)
  end

  defp handle_persist_cover({:error, changeset}, conn) do
    Logger.error("Failed to save cover: #{inspect(changeset)}")

    conn
    |> put_status(:unprocessable_entity)
    |> put_view(LitcoversWeb.ErrorJSON)
    |> render(:"422", errors: changeset)
    |> halt()
  end

  @doc false
  defp remove_litcoins(conn, _params) do
    Accounts.remove_litcoins(conn.assigns[:current_user], conn.assigns[:cost])
    conn
  end

  @doc false
  defp return_cover(conn, _params) do
    conn
    |> put_status(:created)
    |> render(:cover, cover: conn.assigns[:cover])
  end
end
