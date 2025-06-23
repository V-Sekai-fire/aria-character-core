defmodule AriaAuth.Repo do
  use Ecto.Repo, otp_app: :aria_auth, adapter: Ecto.Adapters.SQLite3
end