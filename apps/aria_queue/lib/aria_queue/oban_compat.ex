# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaQueue.Oban do
  @moduledoc """
  Compatibility layer for Oban API using Membrane-based job processing.

  This module provides the same interface as Oban but uses Membrane internally.
  """

  @doc """
  Insert a single job into the queue.
  Compatible with Oban.insert/1
  """
  def insert(job_params) when is_map(job_params) do
    AriaQueue.MembraneJobProcessor.insert(job_params)
  end

  def insert(%{} = changeset) do
    # Handle Ecto changeset format
    job_params = changeset.changes || %{}
    AriaQueue.MembraneJobProcessor.insert(job_params)
  end

  @doc """
  Insert multiple jobs into the queue.
  Compatible with Oban.insert_all/1
  """
  def insert_all(jobs) when is_list(jobs) do
    AriaQueue.MembraneJobProcessor.insert_all(jobs)
  end

  @doc """
  Cancel a job (stub implementation)
  """
  def cancel_job(_job_id) do
    {:ok, :cancelled}
  end

  @doc """
  Retry a failed job (Oban compatibility)
  """
  def retry_job(_job_id) do
    # For now, just return ok - actual retry would depend on implementation
    {:ok, :retried}
  end

  @doc """
  Get a job by ID (Oban compatibility)
  """
  def get_job(job_id) do
    # For now, just return a mock job as a map
    job = %{
      id: job_id,
      state: "available",
      args: %{},
      queue: "default",
      worker: nil,
      priority: 0,
      scheduled_at: nil,
      inserted_at: DateTime.utc_now(),
      completed_at: nil,
      max_attempts: 3,
      attempt: 1
    }
    {:ok, job}
  end

  defmodule Job do
    @moduledoc """
    Job struct compatible with Oban.Job
    """

    defstruct [
      :id,
      :args,
      :queue,
      :worker,
      :priority,
      :scheduled_at,
      :inserted_at,
      :completed_at,
      :state,
      :max_attempts,
      :attempt
    ]

    def new(attrs) when is_map(attrs) do
      struct(__MODULE__, attrs)
    end
  end
end
