# Plugs as composition

By abiding by the plug contract, we turn an application request into a series of explicit transformations. It doesn't stop there. To really see how effective Plug's design is, let's imagine a scenario where we need to check a series of conditions and then either redirect or halt if a condition fails. Without plug, we would end up with something like this:

```elixir
defmodule HelloWeb.MessageController do
  use HelloWeb, :controller

  def show(conn, params) do
    case Authenticator.find_user(conn) do
      {:ok, user} ->
        case find_message(params["id"]) do
          nil ->
            conn |> put_flash(:info, "That message wasn't found") |> redirect(to: ~p"/")
          message ->
            if Authorizer.can_access?(user, message) do
              render(conn, :show, page: message)
            else
              conn |> put_flash(:info, "You can't access that page") |> redirect(to: ~p"/")
            end
        end
      :error ->
        conn |> put_flash(:info, "You must be logged in") |> redirect(to: ~p"/")
    end
  end
end
```

Notice how just a few steps of authentication and authorization require complicated nesting and duplication? Let's improve this with a couple of plugs.

```elixir
defmodule HelloWeb.MessageController do
  use HelloWeb, :controller

  plug :authenticate
  plug :fetch_message
  plug :authorize_message

  def show(conn, params) do
    render(conn, :show, page: conn.assigns[:message])
  end

  defp authenticate(conn, _) do
    case Authenticator.find_user(conn) do
      {:ok, user} ->
        assign(conn, :user, user)
      :error ->
        conn |> put_flash(:info, "You must be logged in") |> redirect(to: ~p"/") |> halt()
    end
  end

  defp fetch_message(conn, _) do
    case find_message(conn.params["id"]) do
      nil ->
        conn |> put_flash(:info, "That message wasn't found") |> redirect(to: ~p"/") |> halt()
      message ->
        assign(conn, :message, message)
    end
  end

  defp authorize_message(conn, _) do
    if Authorizer.can_access?(conn.assigns[:user], conn.assigns[:message]) do
      conn
    else
      conn |> put_flash(:info, "You can't access that page") |> redirect(to: ~p"/") |> halt()
    end
  end
end
```

To make this all work, we converted the nested blocks of code and used halt(conn) whenever we reached a failure path. The halt(conn) functionality is essential here: it tells Plug that the next plug should not be invoked.

At the end of the day, by replacing the nested blocks of code with a flattened series of plug transformations, we are able to achieve the same functionality in a much more composable, clear, and reusable way.
