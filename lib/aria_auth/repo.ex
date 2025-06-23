# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaAuth.Repo do
  use Ecto.Repo, otp_app: :aria_auth, adapter: Ecto.Adapters.SQLite3
end