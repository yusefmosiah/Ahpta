defmodule Capstone.Repo do
  use Ecto.Repo,
    otp_app: :capstone,
    adapter: Ecto.Adapters.Postgres
end
