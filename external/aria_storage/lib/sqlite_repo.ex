# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaStorage.SqliteRepo do
  use Ecto.Repo, otp_app: :aria_storage, adapter: Ecto.Adapters.SQLite3
end
