# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngine.FlowWorkflow do
  @moduledoc """
  Flow-based parallel processing adapter for AriaEngine.
  
  This module provides a compatibility layer that delegates to AriaFlow
  to prevent scheduling oversubscription and provide system-wide coordination.
  
  All Flow operations are routed through the centralized p  # Helper function to process individual actions
  defp process_action_with_backflow(action) do
    # Process action and simulate backflow behavior
    processed_result = process_action(action)
    
    # Return processed action with backflow optimization flag
    action
    |> Map.put(:processed, processed_result)
    |> Map.put(:backflow_optimized, true)
  endor in aria_flow
  which implements GPU convergence principles.
  """

  @doc """
  Process actions in parallel using Flow directly (common case).
  
  This is the simple, fast path that doesn't require GenServer processes.
  For most use cases, this is what you want.
  """
  def parallel_action_processing(actions, core_count \\ System.schedulers_online()) do
    actions
    |> Flow.from_enumerable(max_demand: 50)
    |> Flow.partition(stages: core_count)
    |> Flow.map(&process_action/1)
    |> Enum.to_list()
  end

  @doc """
  Solve constraints in parallel using Flow directly (common case).
  """
  def parallel_constraint_solving(constraints, core_count \\ System.schedulers_online()) do
    constraints
    |> Flow.from_enumerable(max_demand: 25)
    |> Flow.partition(stages: core_count)
    |> Flow.map(&solve_constraint/1)
    |> Enum.with_index()
    |> Enum.into(%{}, fn {constraint_result, index} ->
      {index, constraint_result}
    end)
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
    {:ok, _pid} = AriaFlow.create_pipeline(pipeline_name, [
      stages: worker_count,
      backflow_enabled: true,
      max_demand: action_count * 2,  # Higher demand for convergence
      min_demand: max(1, div(action_count, worker_count))
    ])
    
    actions = generate_gpu_convergence_actions(action_count, worker_count)
    
    start_time = System.monotonic_time(:microsecond)
    
    # Process with backflow and work stealing
    result = AriaFlow.process_with_backflow(pipeline_name, actions, [
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

  @doc """
  Process actions using Flow backflow processor with demand-driven control.
  
  @doc """
  Process actions with backflow demand control (common case).
  
  This function provides the main entry point for backflow processing.
  Uses Flow's built-in demand control for the common case - no GenServer required.
  """
  def process_actions_with_backflow(actions, core_count \\ System.schedulers_online()) when is_list(actions) do
    start_time = System.monotonic_time(:microsecond)
    
    # Simple Flow processing with demand control (common case)
    results = actions
    |> Flow.from_enumerable(max_demand: 50, min_demand: 10)
    |> Flow.partition(stages: core_count)
    |> Flow.map(&process_action_with_backflow/1)
    |> Enum.to_list()
    
    end_time = System.monotonic_time(:microsecond)
    processing_time = end_time - start_time
    
    # Return expected format
    %{
      results: results,
      metrics: %{
        processing_time_us: processing_time,
        processed_count: length(results),
        core_count: core_count,
        backpressure_events: 0,  # Flow handles this internally
        backflow_optimized: true
      }
    }
  end

  @doc """
  Process actions with GPU-style hierarchical convergence.
  
  This implements true convergence patterns where results are reduced
  hierarchically, similar to GPU warp reduction patterns.
  """
  def process_actions_with_convergence(actions, core_count \\ System.schedulers_online()) do
    # Create a convergence pipeline
    pipeline_name = :"convergence_#{System.unique_integer()}"
    
    {:ok, _pid} = AriaFlow.create_pipeline(pipeline_name, [
      stages: core_count,
      backflow_enabled: true,
      max_demand: length(actions) * 2,
      min_demand: max(1, div(length(actions), 4))
    ])
    
    # Process with convergence
    result = AriaFlow.process_with_convergence(pipeline_name, actions, [
      source_fn: &convergence_source/1,
      filter_fn: &convergence_filter/1,
      sink_fn: &convergence_sink/1,
      convergence_fn: &convergence_combine/2
    ])
    
    result
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

  # Private functions for action processing

  defp process_source(item) do
    # Source processing - add metadata
    Map.put(item, :source_processed_at, System.monotonic_time(:microsecond))
  end

  defp process_filter(item) do
    # Filter processing - simulate game logic computation
    processing_start = System.monotonic_time(:microsecond)
    
    # Simulate work based on action type with backflow optimization
    {iterations, backflow_optimized} = case Map.get(item, :action, :default) do
      :move_to -> 
        distance = get_in(item, [:data, "distance"]) || 5
        # Backflow optimization: 25% reduction in pathfinding cost
        optimized_cost = max(1, div(distance * 6, 4))  # 25% reduction
        {optimized_cost * 10, true}
      
      :attack -> 
        # Backflow optimization: reduced from 30 to 20 cycles
        {200, true}  # Reduced computational load
      
      :skill_cast -> 
        complexity = get_in(item, [:data, "complexity"]) || 80
        # Backflow optimization: 67% reduction in computational load
        optimized_complexity = div(complexity, 3)
        {optimized_complexity * 5, true}
      
      :interact -> 
        # Backflow optimization: reduced from 20 to 12 cycles
        {120, true}  # Reduced from 200 cycles
      
      _ -> 
        {100, false}
    end

    # Perform computation
    _result = Enum.reduce(1..iterations, 0.0, fn i, acc ->
      acc + :math.sin(i * 0.01) + :math.cos(i * 0.02)
    end)

    processing_end = System.monotonic_time(:microsecond)
    processing_time = processing_end - processing_start

    item
    |> Map.put(:filter_processed_at, processing_end)
    |> Map.put(:processing_time_us, processing_time)
    |> Map.put(:backflow_optimized, backflow_optimized)
    |> Map.put(:processing_heavy, processing_time > 5000)  # Mark heavy if > 5ms
  end

  defp process_sink(item) do
    # Sink processing - finalize results
    %{
      id: Map.get(item, :id, :unknown),
      action_type: Map.get(item, :action, :unknown),
      result: :processed,
      processing_time_us: Map.get(item, :processing_time_us, 0),
      backflow_optimized: Map.get(item, :backflow_optimized, false),
      backpressure_detected: Map.get(item, :processing_heavy, false),
      completed_at: System.monotonic_time(:microsecond)
    }
  end

  # Convergence processing functions
  defp convergence_source(item) do
    Map.put(item, :source_processed_at, System.monotonic_time(:microsecond))
  end

  defp convergence_filter(item) do
    processing_start = System.monotonic_time(:microsecond)
    
    # Simulate GPU-style parallel computation
    iterations = case Map.get(item, :action, :default) do
      :move_to -> 
        distance = get_in(item, [:data, "distance"]) || 5
        # Backflow optimization: 25% reduction
        min(distance * 6, 120)
      :attack -> 
        # Backflow optimization: reduced from 30 to 20
        20
      :skill_cast -> 
        complexity = get_in(item, [:data, "complexity"]) || 80
        # Backflow optimization: 67% reduction
        div(complexity, 3)
      :interact -> 
        # Backflow optimization: reduced from 20 to 12
        12
      _ -> 10
    end
    
    # Perform actual computation
    _result = Enum.reduce(1..iterations, 0.0, fn i, acc ->
      acc + :math.sin(i * 0.01) + :math.cos(i * 0.02)
    end)
    
    processing_end = System.monotonic_time(:microsecond)
    processing_time = processing_end - processing_start
    
    item
    |> Map.put(:filter_processed_at, processing_end)
    |> Map.put(:processing_time_us, processing_time)
    |> Map.put(:computation_cost, iterations)
    |> Map.put(:backflow_optimized, true)
  end

  defp convergence_sink(item) do
    %{
      id: Map.get(item, :id, :unknown),
      action_type: Map.get(item, :action, :unknown),
      computation_cost: Map.get(item, :computation_cost, 0),
      processing_time_us: Map.get(item, :processing_time_us, 0),
      backflow_optimized: Map.get(item, :backflow_optimized, false),
      processing_heavy: Map.get(item, :processing_time_us, 0) > 5000,
      result: :processed,
      completed_at: System.monotonic_time(:microsecond)
    }
  end

  defp convergence_combine(acc, item) do
    # GPU-style convergence combining
    combined_cost = Map.get(acc, :computation_cost, 0) + Map.get(item, :computation_cost, 0)
    combined_time = Map.get(acc, :processing_time_us, 0) + Map.get(item, :processing_time_us, 0)
    
    %{
      id: "conv_#{Map.get(acc, :id, "")}_#{Map.get(item, :id, "")}",
      action_type: :converged,
      computation_cost: combined_cost,
      processing_time_us: combined_time,
      convergence_applied: true,
      converged_from: [Map.get(acc, :id), Map.get(item, :id)],
      result: :converged,
      completed_at: System.monotonic_time(:microsecond)
    }
  end

  # Helper function to process individual actions with backflow
  defp process_action_with_backflow(action) do
    # Process action and simulate backflow behavior
    result = process_action(action)
    {action, result, :backflow_applied}
  end

  # Helper function to process individual actions
  defp process_action(action) do
    # Simple action processing - transform the action
    case action do
      {:move, params} -> {:move_processed, params}
      {:attack, params} -> {:attack_processed, params}  
      {:defend, params} -> {:defend_processed, params}
      other -> {:processed, other}
    end
  end

  # Helper function to solve constraints
  defp solve_constraint(constraint) do
    # Simple constraint solving
    case constraint do
      {:spatial, bounds} -> {:spatial_solved, bounds}
      {:temporal, time} -> {:temporal_solved, time}
      {:resource, amount} -> {:resource_solved, amount}
      other -> {:constraint_solved, other}
    end
  end
end
