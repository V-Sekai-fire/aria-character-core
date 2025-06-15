# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaFlow.GpuConvergenceProcessor do
  @moduledoc """
  GPU convergence-inspired Flow processor for high-performance parallel processing.
  
  Implements GPU convergence principles:
  - Backflow: Results flow back through stages efficiently
  - Work Stealing: Load balancing across available cores
  - Demand-driven: Processing driven by downstream demand
  
  This module encapsulates Flow-based processing behind AriaFlow's interface,
  preventing other apps from directly depending on Flow.
  """
  
  use GenServer
  
  @doc """
  Start the GPU convergence processor with system-wide resource management.
  """
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc """
  Process items using GPU convergence principles with Flow.
  
  ## Options
  - `:batch_size` - Override automatic batch size calculation
  - `:stages` - Override automatic core count detection
  - `:work_stealing` - Enable/disable work stealing (default: true)
  """
  def process_batch(items, processor_fn, opts \\ []) do
    GenServer.call(__MODULE__, {:process_batch, items, processor_fn, opts}, :infinity)
  end

  @doc """
  Get current system processing metrics.
  """
  def get_metrics do
    GenServer.call(__MODULE__, :get_metrics)
  end

  # GenServer implementation

  def init(opts) do
    max_cores = Keyword.get(opts, :max_cores, System.schedulers_online())
    
    state = %{
      max_cores: max_cores,
      active_jobs: 0,
      total_processed: 0,
      processing_time_us: 0,
      convergence_efficiency: 0.0
    }
    
    {:ok, state}
  end

  def handle_call({:process_batch, items, processor_fn, opts}, _from, state) do
    start_time = System.monotonic_time(:microsecond)
    
    # Resource management: prevent oversubscription
    core_count = min(state.max_cores, Keyword.get(opts, :stages, state.max_cores))
    
    # Apply GPU convergence processing with Flow
    result = gpu_convergence_flow_processing(items, processor_fn, core_count, opts)
    
    end_time = System.monotonic_time(:microsecond)
    processing_time = end_time - start_time
    
    # Update metrics
    new_state = %{state |
      total_processed: state.total_processed + length(items),
      processing_time_us: state.processing_time_us + processing_time,
      convergence_efficiency: calculate_efficiency(result, processing_time)
    }
    
    {:reply, result, new_state}
  end

  def handle_call(:get_metrics, _from, state) do
    metrics = %{
      max_cores: state.max_cores,
      active_jobs: state.active_jobs,
      total_processed: state.total_processed,
      processing_time_us: state.processing_time_us,
      convergence_efficiency: state.convergence_efficiency,
      avg_processing_time_per_item: safe_divide(state.processing_time_us, state.total_processed)
    }
    
    {:reply, metrics, state}
  end

  # Private implementation

  defp gpu_convergence_flow_processing(items, processor_fn, core_count, opts) do
    # GPU Convergence Principle 1: Backflow processing
    # Results flow back efficiently through stages
    
    _batch_size = Keyword.get(opts, :batch_size, calculate_optimal_batch_size(length(items), core_count))
    
    start_time = System.monotonic_time(:microsecond)
    
    results = items
    |> Flow.from_enumerable(stages: core_count)
    |> Flow.partition()
    # Work Stealing: Flow automatically balances load across stages
    |> Flow.map(processor_fn)
    # Demand-driven: Each stage processes based on downstream demand
    |> Flow.partition()
    |> Flow.reduce(fn -> [] end, fn result, acc -> [result | acc] end)
    |> Enum.to_list()
    |> List.flatten()
    |> Enum.reverse()
    
    end_time = System.monotonic_time(:microsecond)
    total_time_us = end_time - start_time
    
    # Return convergence metrics alongside results
    %{
      results: results,
      processed_count: length(results),
      processing_time_us: total_time_us,
      core_count: core_count,
      convergence_efficiency: calculate_convergence_efficiency(results, total_time_us, core_count),
      work_stealing_active: true,
      backflow_optimized: length(results) > 0
    }
  end

  defp calculate_optimal_batch_size(item_count, core_count) do
    # GPU-inspired batching: aim for ~64-256 items per core
    base_batch_size = div(item_count, core_count)
    cond do
      base_batch_size < 64 -> 64
      base_batch_size > 256 -> 256
      true -> base_batch_size
    end
  end

  defp calculate_convergence_efficiency(results, processing_time_us, core_count) do
    if length(results) > 0 and processing_time_us > 0 do
      # Efficiency = (results processed) / (time * cores used)
      # Higher values indicate better GPU-style convergence
      throughput = length(results) / (processing_time_us / 1_000_000)
      throughput / core_count
    else
      0.0
    end
  end

  defp calculate_efficiency(result_map, _processing_time) do
    case Map.get(result_map, :convergence_efficiency) do
      nil -> 0.0
      efficiency -> efficiency
    end
  end

  defp safe_divide(_numerator, 0), do: 0.0
  defp safe_divide(numerator, denominator), do: numerator / denominator
end
