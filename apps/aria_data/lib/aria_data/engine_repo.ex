# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaData.EngineRepo do
  @moduledoc """
  Repository for planning engine data.

  Handles planning states, domain definitions, task decompositions,
  and plan execution history. Uses a separate database for engine isolation.
  """

  use Ecto.Repo,
    otp_app: :aria_data,
    adapter: Ecto.Adapters.SQLite3

  def migrations_path do
    Application.app_dir(:aria_data, "priv/engine_repo/migrations")
  end
end
