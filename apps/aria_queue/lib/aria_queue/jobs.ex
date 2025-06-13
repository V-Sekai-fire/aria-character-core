# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaQueue.Jobs do
  @moduledoc """
  The Jobs context for managing background jobs.
  """

  import Ecto.Query, warn: false
  alias AriaData.QueueRepo

  @doc """
  Enqueues a job for processing.
  """
  def enqueue(worker_module, args, opts \\ []) when is_atom(worker_module) and is_map(args) do
    queue = Keyword.get(opts, :queue, :default)
    priority = Keyword.get(opts, :priority, 0)
    max_attempts = Keyword.get(opts, :max_attempts, 3)

    worker_module.new(args, queue: queue, priority: priority, max_attempts: max_attempts)
    |> AriaQueue.Oban.insert()
  end

  @doc """
  Schedules a job to run at a specific time.
  """
  def schedule(worker_module, args, scheduled_at, opts \\ []) when is_atom(worker_module) and is_map(args) do
    queue = Keyword.get(opts, :queue, :default)
    priority = Keyword.get(opts, :priority, 0)
    max_attempts = Keyword.get(opts, :max_attempts, 3)

    worker_module.new(args,
      queue: queue,
      priority: priority,
      max_attempts: max_attempts,
      scheduled_at: scheduled_at
    )
    |> AriaQueue.Oban.insert()
  end

  @doc """
  Cancels a scheduled job.
  """
  def cancel_job(job_id) when is_integer(job_id) do
    AriaQueue.Oban.cancel_job(job_id)
  end

  @doc """
  Gets job status.
  """
  def get_job_status(job_id) when is_integer(job_id) do
    case QueueRepo.get(AriaQueue.Oban.Job, job_id) do
      nil -> {:error, :not_found}
      job -> {:ok, job}
    end
  end

  @doc """
  Lists jobs by queue.
  """
  def list_jobs_by_queue(queue_name, limit \\ 50) do
    AriaQueue.Oban.Job
    |> where([j], j.queue == ^to_string(queue_name))
    |> order_by([j], desc: j.inserted_at)
    |> limit(^limit)
    |> QueueRepo.all()
  end

  @doc """
  Lists jobs by state.
  """
  def list_jobs_by_state(state, limit \\ 50) when state in [:available, :scheduled, :executing, :retryable, :completed, :discarded, :cancelled] do
    AriaQueue.Oban.Job
    |> where([j], j.state == ^to_string(state))
    |> order_by([j], desc: j.inserted_at)
    |> limit(^limit)
    |> QueueRepo.all()
  end

  @doc """
  Retries a failed job.
  """
  def retry_job(job_id) when is_integer(job_id) do
    AriaQueue.Oban.retry_job(job_id)
  end

  @doc """
  Gets queue statistics.
  """
  def get_queue_stats(queue_name) do
    queue_str = to_string(queue_name)

    states = [:available, :scheduled, :executing, :retryable, :completed, :discarded, :cancelled]

    stats = Enum.reduce(states, %{}, fn state, acc ->
      count =
        AriaQueue.Oban.Job
        |> where([j], j.queue == ^queue_str and j.state == ^to_string(state))
        |> QueueRepo.aggregate(:count, :id)

      Map.put(acc, state, count)
    end)

    {:ok, stats}
  end

  @doc """
  Prunes completed jobs older than the specified number of seconds.
  """
  def prune_jobs(max_age_seconds \\ 86400) do
    cutoff = DateTime.add(DateTime.utc_now(), -max_age_seconds, :second)

    AriaQueue.Oban.Job
    |> where([j], j.state in ["completed", "discarded"] and j.completed_at < ^cutoff)
    |> QueueRepo.delete_all()
  end
end
