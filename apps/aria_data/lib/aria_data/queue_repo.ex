# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaData.QueueRepo do
  @moduledoc """
  Repository for background job queue data.
  
  Handles Oban job persistence, queue management, and job state tracking.
  Uses a separate database for queue isolation and performance.
  """
  
  use Ecto.Repo,
    otp_app: :aria_data,
    adapter: Ecto.Adapters.Postgres
    
  def migrations_path do
    Application.app_dir(:aria_data, "priv/queue_repo/migrations")
  end
end
