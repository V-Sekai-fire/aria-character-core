# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngine.FlowWorkflow do
  @moduledoc """
  Flow-based parallel processing adapter for AriaEngine.
  
  This module provides a compatibility layer that delegates to AriaQueue.FlowProcessor
  to prevent scheduling oversubscription and provide system-wide coordination.
  
  All Flow operations are routed through the centralized processor in aria_queue
  which implements GPU convergence principles.
  """

  @doc """
  Process actions in parallel using centralized Flow processor.
  
  Delegates to AriaQueue.FlowProcessor to prevent scheduling oversubscription.
  """
  def parallel_action_processing(actions, core_count \\ System.schedulers_online()) do
    result = AriaQueue.FlowProcessor.process_actions(actions, max_cores: core_count)
    
    # Extract just the results for compatibility with existing tests
    case result do
      %{results: results} -> results
      _ -> []
    end
  end

  @doc """
  Solve constraints in parallel using centralized Flow processor.
  """
  def parallel_constraint_solving(constraints, core_count \\ System.schedulers_online()) do
    result = AriaQueue.FlowProcessor.process_constraints(constraints, max_cores: core_count)
    
    # Convert results to map format for compatibility
    case result do
      %{results: results} ->
        results
        |> Enum.with_index()
        |> Enum.into(%{}, fn {constraint_result, index} ->
          {index, constraint_result}
        end)
      _ -> %{}
    end
  end

  @doc """
  Performance test using centralized Flow processor.
  
  This ensures consistent performance metrics across the system.
  """
  def test_flow_parallel_processing(action_count, core_count \\ System.schedulers_online()) do
    actions = generate_test_actions(action_count)
    
    # Use centralized processor to prevent oversubscription
    result = AriaQueue.FlowProcessor.process_actions(actions, max_cores: core_count)
    
    # Convert to expected format for test compatibility
    %{
      processed_count: result.processed_count,
      total_time_us: result.processing_time_us,
      total_time_ms: result.processing_time_us / 1000,
      coordination_time_ms: 0.0,  # Centralized processor handles coordination
      core_count: result.core_count,
      actions_per_second: if(result.processing_time_us > 0, 
        do: result.processed_count / (result.processing_time_us / 1_000_000), 
        else: 0),
      convergence_efficiency: result.convergence_efficiency,
      work_stealing_active: result.work_stealing_active,
      backflow_optimized: result.backflow_optimized
    }
  end

  # Backflow processing functions for GPU convergence patterns

  @doc """
  Test backflow GPU convergence with work stealing using Flow.
  
  Implements the GPU convergence concept from ADRs with Flow's efficiency.
  """
  def test_backflow_gpu_convergence_with_work_stealing(action_count, worker_count) do
    pipeline_name = :"backflow_test_#{worker_count}_#{System.unique_integer()}"
    
    # Create backflow pipeline with GPU convergence characteristics
    {:ok, _pid} = AriaQueue.FlowBackflow.create_pipeline(pipeline_name, [
      stages: worker_count,
      backflow_enabled: true,
      max_demand: action_count * 2,  # Higher demand for convergence
      min_demand: max(1, div(action_count, worker_count))
    ])
    
    actions = generate_gpu_convergence_actions(action_count, worker_count)
    
    start_time = System.monotonic_time(:microsecond)
    
    # Process with backflow and work stealing
    result = AriaQueue.FlowBackflow.process_with_backflow(pipeline_name, actions, [
      source_fn: &process_gpu_source/1,
      filter_fn: &process_gpu_filter/1,
      sink_fn: &process_gpu_sink/1
    ])
    
    end_time = System.monotonic_time(:microsecond)
    coordination_time_ms = (end_time - start_time) / 1000
    
    %{
      processed_count: result.processed_count,
      total_computation_cost: Map.get(result.metrics, :total_processing_time, 0),
      backpressure_events: Map.get(result.metrics, :backpressure_events, 0),
      coordination_time_ms: coordination_time_ms,
      processing_type: :flow_backflow_convergence,
      work_stealing_efficiency: calculate_work_stealing_efficiency(result, worker_count)
    }
  end

  # GPU convergence processing functions

  defp process_gpu_source(action) do
    # Source stage for GPU convergence - prepare data for parallel processing
    action
    |> Map.put(:gpu_prepared_at, System.monotonic_time(:microsecond))
    |> Map.put(:convergence_ready, true)
  end

  defp process_gpu_filter(action) do
    # Filter stage with heavy computation for GPU convergence testing
    processing_start = System.monotonic_time(:microsecond)
    
    # Simulate GPU-style parallel computation workload
    base_iterations = case action.action do
      :move_to -> 15000 + rem(Map.get(action, :worker_target, 0), 1500)
      :attack -> 22500 + rem(Map.get(action, :worker_target, 0), 2250)
      :skill_cast -> 36000 + rem(Map.get(action, :worker_target, 0), 3600)
      :interact -> 12000 + rem(Map.get(action, :worker_target, 0), 1200)
      _ -> 15000
    end
    
    # Perform actual CPU-intensive work (similar to GPU kernels)
    computation_result = Enum.reduce(1..base_iterations, 0.0, fn i, acc ->
      x = :math.sin(i * 0.001 + Map.get(action, :x, 0))
      y = :math.cos(i * 0.002 + Map.get(action, :y, 0))
      z = :math.sqrt(x * x + y * y + i * 0.0001)
      acc + z
    end)
    
    processing_end = System.monotonic_time(:microsecond)
    processing_time = processing_end - processing_start
    
    action
    |> Map.put(:computation_result, computation_result)
    |> Map.put(:processing_time_us, processing_time)
    |> Map.put(:processing_heavy, processing_time > 5000)
    |> Map.put(:gpu_filtered_at, processing_end)
  end

  defp process_gpu_sink(action) do
    # Sink stage for GPU convergence - finalize results
    %{
      id: Map.get(action, :id, :unknown),
      action: Map.get(action, :action, :unknown),
      result: :gpu_converged,
      computation_cost: Map.get(action, :processing_time_us, 1000),
      processing_time_us: Map.get(action, :processing_time_us, 0),
      backpressure_detected: Map.get(action, :processing_heavy, false),
      convergence_completed_at: System.monotonic_time(:microsecond),
      computation_result: Map.get(action, :computation_result, 0.0)
    }
  end

  defp generate_gpu_convergence_actions(count, worker_count) do
    field_size = 100  # Large field for spatial variety
    
    Enum.map(1..count, fn i ->
      action_type = case rem(i, 4) do
        0 -> :move_to
        1 -> :attack
        2 -> :skill_cast
        3 -> :interact
      end
      
      worker_target = rem(i, worker_count)
      
      %{
        id: i,
        action: action_type,
        x: :rand.uniform(field_size) - 1,
        y: :rand.uniform(field_size) - 1,
        worker_target: worker_target,
        timestamp: System.monotonic_time(:microsecond),
        priority: rem(i, 3) + 1  # Priority 1-3
      }
    end)
  end

  defp calculate_work_stealing_efficiency(result, worker_count) do
    # Calculate work stealing efficiency based on load distribution
    total_time = Map.get(result.metrics, :total_processing_time, 1)
    expected_time_per_worker = total_time / worker_count
    
    # Higher efficiency means better work distribution
    if total_time > 0 do
      min(1.0, expected_time_per_worker / total_time * worker_count)
    else
      1.0
    end
  end

  # Private helper functions

  defp generate_test_actions(count) do
    for i <- 1..count do
      action_type = Enum.random([:move, :attack, :wait, :plan])
      {action_type, %{id: i, x: :rand.uniform(100), y: :rand.uniform(100)}}
    end
  end
end
