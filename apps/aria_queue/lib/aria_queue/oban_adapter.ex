# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaQueue.ObanAdapter do
  @moduledoc """
  Oban-like adapter interface for Flow-based processing.
  
  Provides familiar Oban API but uses efficient Flow pipelines underneath
  instead of database-backed job processing. Maintains compatibility for
  existing code while delivering superior performance.
  """

  @doc """
  Insert a job for processing using Flow pipelines.
  
  Unlike Oban's database approach, this immediately processes the job
  through Flow pipelines for maximum efficiency.
  """
  def insert(job_spec) do
    case validate_job_spec(job_spec) do
      {:ok, validated_job} ->
        process_job_through_pipeline(validated_job)
      
      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Process multiple jobs in parallel using Flow.
  
  This is where the real performance gain happens - batch processing
  through Flow's efficient parallel pipelines.
  """
  def insert_all(job_specs) do
    validated_jobs = Enum.map(job_specs, &validate_job_spec/1)
    
    case Enum.any?(validated_jobs, fn {status, _} -> status == :error end) do
      true ->
        errors = for {:error, reason} <- validated_jobs, do: reason
        {:error, {:validation_errors, errors}}
      
      false ->
        jobs = for {:ok, job} <- validated_jobs, do: job
        process_jobs_batch_through_pipeline(jobs)
    end
  end

  @doc """
  Create a worker-like interface for Flow processing.
  
  Maintains familiar worker API but executes through Flow pipelines.
  """
  defmodule Worker do
    @callback perform(args :: map()) :: :ok | {:ok, any()} | {:error, any()}
    
    defmacro __using__(_opts) do
      quote do
        @behaviour AriaQueue.ObanAdapter.Worker
        
        def new(args, opts \\ []) do
          %{
            worker: __MODULE__,
            args: args,
            queue: Keyword.get(opts, :queue, "default"),
            max_attempts: Keyword.get(opts, :max_attempts, 3),
            priority: Keyword.get(opts, :priority, 0)
          }
        end
        
        def perform_async(args, opts \\ []) do
          job = new(args, opts)
          AriaQueue.ObanAdapter.insert(job)
        end
      end
    end
  end

  # Private implementation

  defp validate_job_spec(job_spec) do
    required_fields = [:worker, :args]
    
    case ensure_required_fields(job_spec, required_fields) do
      :ok ->
        {:ok, %{
          worker: job_spec[:worker] || job_spec["worker"],
          args: job_spec[:args] || job_spec["args"],
          queue: job_spec[:queue] || job_spec["queue"] || "default",
          id: job_spec[:id] || generate_job_id(),
          priority: job_spec[:priority] || 0
        }}
      
      {:error, missing_fields} ->
        {:error, "Missing required fields: #{Enum.join(missing_fields, ", ")}"}
    end
  end

  defp ensure_required_fields(job_spec, required_fields) do
    missing_fields = Enum.filter(required_fields, fn field ->
      is_nil(job_spec[field]) and is_nil(job_spec[Atom.to_string(field)])
    end)
    
    case missing_fields do
      [] -> :ok
      fields -> {:error, fields}
    end
  end

  defp process_job_through_pipeline(job) do
    # Create a single-job pipeline
    pipeline = AriaQueue.FlowPipeline.create_pipeline(
      {:data, [job]},
      [&prepare_job_execution/1, &execute_job/1],
      &finalize_job_result/1,
      stages: 1
    )

    case AriaQueue.FlowPipeline.execute_pipeline(pipeline) do
      %{results: [result]} -> {:ok, result}
      %{results: []} -> {:error, "No result from job execution"}
      %{results: results} -> {:ok, List.first(results)}
    end
  end

  defp process_jobs_batch_through_pipeline(jobs) do
    # Create a batch processing pipeline
    pipeline = AriaQueue.FlowPipeline.create_pipeline(
      {:data, jobs},
      [&prepare_job_execution/1, &execute_job/1],
      &finalize_job_result/1,
      stages: System.schedulers_online()
    )

    case AriaQueue.FlowPipeline.execute_pipeline(pipeline) do
      %{results: results} -> {:ok, results}
      error -> {:error, error}
    end
  end

  defp prepare_job_execution(job) do
    %{job | status: :executing, started_at: DateTime.utc_now()}
  end

  defp execute_job(job) do
    worker_module = get_worker_module(job.worker)
    
    try do
      case worker_module.perform(job.args) do
        :ok -> 
          %{job | status: :completed, result: :ok}
        
        {:ok, result} -> 
          %{job | status: :completed, result: result}
        
        {:error, error} -> 
          %{job | status: :failed, error: error}
        
        other -> 
          %{job | status: :completed, result: other}
      end
    rescue
      error ->
        %{job | status: :failed, error: error}
    end
  end

  defp finalize_job_result(job) do
    %{job | completed_at: DateTime.utc_now()}
  end

  defp get_worker_module(worker) when is_atom(worker), do: worker
  defp get_worker_module(worker) when is_binary(worker), do: String.to_existing_atom(worker)

  defp generate_job_id do
    :crypto.strong_rand_bytes(16) |> Base.encode64()
  end
end
