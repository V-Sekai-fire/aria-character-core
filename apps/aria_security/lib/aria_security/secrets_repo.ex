defmodule AriaSecurity.SecretsRepo do
  use Ecto.Repo, 
    otp_app: :aria_security, 
    adapter: Ecto.Adapters.SQLite3
end
