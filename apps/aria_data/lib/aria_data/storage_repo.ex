# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaData.StorageRepo do
  @moduledoc """
  Repository for storage metadata and file tracking.

  Handles file metadata, content addressing, storage locations,
  and content sync state. Uses a separate database for storage isolation.
  """

  use Ecto.Repo,
    otp_app: :aria_data,
    adapter: Ecto.Adapters.SQLite3

  def migrations_path do
    Application.app_dir(:aria_data, "priv/storage_repo/migrations")
  end
end
