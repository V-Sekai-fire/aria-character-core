# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaData.QueueRepo.Migrations.AddObanJobsTable do
  use Ecto.Migration

  def up do
    # SQLite-compatible Oban migration for v2.19.4
    # Create the oban_jobs table with SQLite-compatible types
    create table(:oban_jobs) do
      add :state, :text, null: false, default: "available"
      add :queue, :text, null: false, default: "default"
      add :worker, :text, null: false
      add :args, :text, null: false  # JSON as TEXT in SQLite
      add :tags, :text, null: false, default: "[]"  # JSON array as TEXT
      add :errors, :text, null: false, default: "[]"  # JSON array as TEXT
      add :attempt, :integer, null: false, default: 0
      add :max_attempts, :integer, null: false, default: 20
      add :inserted_at, :utc_datetime_usec, null: false
      add :scheduled_at, :utc_datetime_usec, null: false
      add :attempted_at, :utc_datetime_usec
      add :completed_at, :utc_datetime_usec
      add :attempted_by, :text, null: false, default: "[]"  # JSON array as TEXT
      add :discarded_at, :utc_datetime_usec
      add :priority, :integer, null: false, default: 0
      add :meta, :text, null: false, default: "{}"  # JSON as TEXT
      add :cancelled_at, :utc_datetime_usec
      add :conf, :text, null: false, default: "{}"  # JSON as TEXT
    end

    # Create indexes optimized for SQLite
    create index(:oban_jobs, [:state, :queue, :priority, :scheduled_at])
    create index(:oban_jobs, [:inserted_at])
    create index(:oban_jobs, [:state, :scheduled_at, :id])

    # Create oban_peers table for Oban v2.19.4 distributed features
    create table(:oban_peers, primary_key: false) do
      add :name, :text, primary_key: true
      add :node, :text, null: false
      add :started_at, :utc_datetime_usec, null: false
      add :updated_at, :utc_datetime_usec, null: false
    end
  end

  def down do
    drop table(:oban_peers)
    drop table(:oban_jobs)
  end
end
