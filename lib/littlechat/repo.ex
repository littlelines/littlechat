defmodule Littlechat.Repo do
  use Ecto.Repo,
    otp_app: :littlechat,
    adapter: Ecto.Adapters.Postgres
end
