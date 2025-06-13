# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaData.Repo do
  @moduledoc """
  Main repository for the AriaData application.

  This is the primary database connection for general data persistence
  across the aria-character-core umbrella project.
  """

  use Ecto.Repo,
    otp_app: :aria_data,
    adapter: Ecto.Adapters.SQLite3

  def migrations_path do
    Application.app_dir(:aria_data, "priv/repo/migrations")
  end
end
