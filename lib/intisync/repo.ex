defmodule Intisync.Repo do
  use Ecto.Repo,
    otp_app: :intisync,
    adapter: Ecto.Adapters.Postgres
end
