# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaData.MonitorRepo do
  @moduledoc """
  Repository for monitoring and telemetry data.

  Handles metrics, logs, performance data, and system health tracking.
  Uses a separate database for monitoring isolation and retention policies.
  """

  use Ecto.Repo,
    otp_app: :aria_data,
    adapter: Ecto.Adapters.SQLite3

  def migrations_path do
    Application.app_dir(:aria_data, "priv/monitor_repo/migrations")
  end
end
