# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaQueue do
  @moduledoc """
  AriaQueue provides background job processing for the Aria platform.
  
  This service handles:
  - Background job scheduling and execution
  - Queue management across different job types
  - Job monitoring and retry logic
  - Distributed job processing
  """

  alias AriaQueue.Jobs

  @doc """
  Enqueues a job for processing.
  """
  defdelegate enqueue(job_name, args, opts \\ []), to: Jobs

  @doc """
  Schedules a job to run at a specific time.
  """
  defdelegate schedule(job_name, args, scheduled_at, opts \\ []), to: Jobs

  @doc """
  Cancels a scheduled job.
  """
  defdelegate cancel_job(job_id), to: Jobs

  @doc """
  Gets job status.
  """
  defdelegate get_job_status(job_id), to: Jobs

  @doc """
  Lists jobs by queue.
  """
  defdelegate list_jobs_by_queue(queue_name), to: Jobs

  @doc """
  Retries a failed job.
  """
  defdelegate retry_job(job_id), to: Jobs
end
