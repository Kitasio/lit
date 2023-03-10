defmodule Litcovers.Repo do
  use Ecto.Repo,
    otp_app: :litcovers,
    adapter: Ecto.Adapters.Postgres
end
