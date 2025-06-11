# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaData.QueueRepo.Migrations.AddObanJobsTable do
  use Ecto.Migration

  def up do
    # CockroachDB-compatible Oban migration for v2.19.4
    # Create the enum type for CockroachDB
    execute """
    CREATE TYPE oban_job_state AS ENUM (
      'available',
      'scheduled',
      'executing',
      'retryable',
      'completed',
      'discarded',
      'cancelled'
    )
    """

    # Create the oban_jobs table with CockroachDB-compatible types
    create table(:oban_jobs, primary_key: false) do
      add :id, :bigserial, primary_key: true
      add :state, :oban_job_state, null: false, default: "available"
      add :queue, :text, null: false, default: "default"
      add :worker, :text, null: false
      add :args, :jsonb, null: false
      add :tags, {:array, :text}, null: false, default: []
      # Use JSONB instead of array of JSONB for CockroachDB compatibility
      add :errors, :jsonb, null: false, default: "[]"
      add :attempt, :integer, null: false, default: 0
      add :max_attempts, :integer, null: false, default: 20
      add :inserted_at, :utc_datetime_usec, null: false
      add :scheduled_at, :utc_datetime_usec, null: false
      add :attempted_at, :utc_datetime_usec
      add :completed_at, :utc_datetime_usec
      # Change attempted_by from {:array, :text} to :jsonb for consistency
      add :attempted_by, :jsonb, null: false, default: "[]"
      add :discarded_at, :utc_datetime_usec
      add :priority, :integer, null: false, default: 0
      add :meta, :jsonb, null: false, default: "{}"
      add :cancelled_at, :utc_datetime_usec
      add :conf, :jsonb, null: false, default: "{}"
    end

    # Create indexes optimized for CockroachDB
    create index(:oban_jobs, [:state, :queue, :priority, :scheduled_at], name: :oban_jobs_state_queue_priority_scheduled_at_index)
    create index(:oban_jobs, [:args], name: :oban_jobs_args_index, using: "GIN")
    create index(:oban_jobs, [:meta], name: :oban_jobs_meta_index, using: "GIN")
    create index(:oban_jobs, [:inserted_at], name: :oban_jobs_inserted_at_index)
    create index(:oban_jobs, [:state, :scheduled_at, :id], name: :oban_jobs_state_scheduled_at_id_index)

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
    execute "DROP TYPE IF EXISTS oban_job_state"
  end
end
