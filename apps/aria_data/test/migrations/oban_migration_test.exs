# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaData.QueueRepo.Migrations.ObanMigrationTest do
  use ExUnit.Case, async: true

  test "migration file exists and is properly formatted" do
    migration_file = Path.join([
      Application.app_dir(:aria_data),
      "priv", "queue_repo", "migrations", "20250609224548_add_oban_jobs_table.exs"
    ])

    assert File.exists?(migration_file), "Migration file should exist"

    content = File.read!(migration_file)

    # Check for SQLite-compatible features
    assert String.contains?(content, "add :state, :text"), "Should use TEXT for state field"
    assert String.contains?(content, "add :errors, :text"), "Should use TEXT for errors (JSON as TEXT)"
    assert String.contains?(content, "add :attempted_by, :text"), "Should use TEXT for attempted_by (JSON as TEXT)"
    assert String.contains?(content, "cancelled_at"), "Should include cancelled_at field for v2.19.4"
    assert String.contains?(content, "add :conf, :text"), "Should include conf field for v2.19.4"
    assert String.contains?(content, "create table(:oban_peers"), "Should create oban_peers table"
    assert String.contains?(content, "add :args, :text"), "Should use TEXT for args (JSON as TEXT)"
    assert String.contains?(content, "add :meta, :text"), "Should use TEXT for meta (JSON as TEXT)"

    # Ensure SQLite-incompatible types are not used
    refute String.contains?(content, "oban_job_state AS ENUM"), "Should not use PostgreSQL ENUM types"
    refute String.contains?(content, ":jsonb"), "Should not use PostgreSQL JSONB type"
    refute String.contains?(content, ":bigserial"), "Should not use PostgreSQL BIGSERIAL type"
  end
end
