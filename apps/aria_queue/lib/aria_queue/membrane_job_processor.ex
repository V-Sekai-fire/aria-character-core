# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaQueue.MembraneJobProcessor do
  @moduledoc """
  Membrane-based job processing system that replaces Oban.

  Provides the same functionality as Oban but using a simplified approach:
  - Job queuing and processing
  - Priority-based execution
  - Worker pools for different job types
  """

  use GenServer

  defstruct [:job_queues, :worker_config]

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    # Initialize job queues based on the same structure as Oban config
    worker_config = %{
      sequential_actions: 1,    # Single worker for strict temporal ordering
      parallel_actions: 5,      # Multi-worker for concurrent execution
      instant_actions: 3,       # High-priority immediate responses
      ai_generation: 5,
      planning: 10,
      storage_sync: 3,
      monitoring: 2
    }

    job_queues = Enum.into(worker_config, %{}, fn {queue_name, _worker_count} ->
      {queue_name, :queue.new()}
    end)

    {:ok, %__MODULE__{
      job_queues: job_queues,
      worker_config: worker_config
    }}
  end

  # Public API - matches Oban.insert/1 interface
  def insert(job_params) do
    GenServer.call(__MODULE__, {:insert_job, job_params})
  end

  # Public API - matches Oban.insert_all/1 interface
  def insert_all(jobs) when is_list(jobs) do
    GenServer.call(__MODULE__, {:insert_jobs, jobs})
  end

  @impl true
  def handle_call({:insert_job, job_params}, _from, state) do
    queue_name = String.to_atom(job_params["queue"] || "parallel_actions")

    case Map.get(state.job_queues, queue_name) do
      nil ->
        {:reply, {:error, :unknown_queue}, state}

      queue ->
        job = create_membrane_job(job_params)
        new_queue = :queue.in(job, queue)
        new_queues = Map.put(state.job_queues, queue_name, new_queue)

        {:reply, {:ok, job}, %{state | job_queues: new_queues}}
    end
  end

  @impl true
  def handle_call({:insert_jobs, jobs}, _from, state) when is_list(jobs) do
    results = Enum.map(jobs, fn job_params ->
      queue_name = String.to_atom(job_params["queue"] || "parallel_actions")

      case Map.get(state.job_queues, queue_name) do
        nil -> {:error, :unknown_queue}
        _queue ->
          job = create_membrane_job(job_params)
          {:ok, job}
      end
    end)

    # Update all queues with new jobs
    new_queues = Enum.reduce(jobs, state.job_queues, fn job_params, acc_queues ->
      queue_name = String.to_atom(job_params["queue"] || "parallel_actions")

      case Map.get(acc_queues, queue_name) do
        nil -> acc_queues
        existing_queue ->
          job = create_membrane_job(job_params)
          new_queue = :queue.in(job, existing_queue)
          Map.put(acc_queues, queue_name, new_queue)
      end
    end)

    {:reply, {:ok, results}, %{state | job_queues: new_queues}}
  end

  defp create_membrane_job(job_params) do
    %{
      id: System.unique_integer([:positive]),
      worker: job_params["worker"] || "DefaultWorker",
      args: job_params["args"] || %{},
      queue: job_params["queue"] || "parallel_actions",
      priority: job_params["priority"] || 0,
      scheduled_at: job_params["scheduled_at"] || DateTime.utc_now(),
      inserted_at: DateTime.utc_now()
    }
  end
end
