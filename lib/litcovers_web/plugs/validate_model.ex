defmodule LitcoversWeb.Plugs.ValidateModel do
  import Plug.Conn
  use LitcoversWeb, :controller

  def init(model), do: model

  def call(conn, model) do
    model_name = model || conn.params["model_name"] || conn.params["model"] || "sd3"

    unless CoverGen.Models.all() |> Enum.member?(model_name) do
      conn
      |> put_status(:bad_request)
      |> put_view(LitcoversWeb.ErrorJSON)
      |> render(:"400")
      |> halt()
    else
      assign(conn, :model_name, model_name)
    end
  end
end
