# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaData.AuthRepo do
  @moduledoc """
  Repository for authentication and authorization data.
  
  Handles user accounts, sessions, tokens, roles, and permissions.
  Uses a separate database for security isolation.
  """
  
  use Ecto.Repo,
    otp_app: :aria_data,
    adapter: Ecto.Adapters.Postgres
    
  def migrations_path do
    Application.app_dir(:aria_data, "priv/auth_repo/migrations")
  end
end
