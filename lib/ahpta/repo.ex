defmodule Ahpta.Repo do
  use Ecto.Repo,
    otp_app: :ahpta,
    adapter: Ecto.Adapters.Postgres
end
