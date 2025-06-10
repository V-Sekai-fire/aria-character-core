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

    # Check for CockroachDB-compatible features
    assert String.contains?(content, "oban_job_state AS ENUM"), "Should create enum type"
    assert String.contains?(content, "add :errors, :jsonb"), "Should use JSONB for errors"
    assert String.contains?(content, "add :attempted_by, :jsonb"), "Should use JSONB for attempted_by"
    assert String.contains?(content, "'cancelled'"), "Should include cancelled state for v2.19.4"
    assert String.contains?(content, "add :conf, :jsonb"), "Should include conf field for v2.19.4"
    assert String.contains?(content, "create table(:oban_peers"), "Should create oban_peers table"

    # Ensure array types are not used for problematic fields
    refute String.contains?(content, "{:array, :jsonb}"), "Should not use array of JSONB"
  end
end
