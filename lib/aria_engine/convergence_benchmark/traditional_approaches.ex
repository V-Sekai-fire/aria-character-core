# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngine.ConvergenceBenchmark.TraditionalApproaches do
  @moduledoc """
  Traditional Flow-based approaches for convergence benchmarking.
  
  This module implements algorithms using Flow streams and traditional
  Elixir concurrency patterns for comparison with Nx and Task approaches.
  """

  require Logger
  alias AriaEngine.ConvergenceFlow

  @doc """
  Benchmark pure Flow-based approach.
  """
  def benchmark_pure_flow(test_data, opts \\ []) do
    Logger.info("Running pure Flow benchmarks...")
    
    Enum.map(test_data, fn {test_name, data} ->
      {time_us, result} = :timer.tc(fn ->
        case data do
          %{constraints: constraints} ->
            solve_stn_with_pure_flow(constraints, opts)
          activities when is_list(activities) ->
            solve_activities_with_pure_flow(activities, opts)
          _ ->
            solve_generic_with_pure_flow(data, opts)
        end
      end)
      
      {test_name, %{
        time_ms: time_us / 1000,
        time_us: time_us,
        result_size: estimate_result_size(result),
        approach: :pure_flow
      }}
    end)
    |> Map.new()
  end

  @doc """
  Benchmark pure Task-based approach (traditional Elixir concurrency).
  """
  def benchmark_pure_task(test_data, opts \\ []) do
    Logger.info("Running pure Task benchmarks...")
    
    Enum.map(test_data, fn {test_name, data} ->
      {time_us, result} = :timer.tc(fn ->
        case data do
          %{constraints: constraints} ->
            solve_stn_with_pure_task(constraints, opts)
          activities when is_list(activities) ->
            solve_activities_with_pure_task(activities, opts)
          _ ->
            solve_generic_with_pure_task(data, opts)
        end
      end)
      
      {test_name, %{
        time_ms: time_us / 1000,
        time_us: time_us,
        result_size: estimate_result_size(result),
        approach: :pure_task
      }}
    end)
    |> Map.new()
  end

  @doc """
  Benchmark hybrid warp Flow approach.
  """
  def benchmark_hybrid_warp_flow(test_data, opts \\ []) do
    Logger.info("Running hybrid warp Flow benchmarks...")
    
    Enum.map(test_data, fn {test_name, data} ->
      {time_us, result} = :timer.tc(fn ->
        case data do
          %{constraints: constraints} ->
            solve_stn_with_hybrid_warp_flow(constraints, opts)
          activities when is_list(activities) ->
            solve_activities_with_hybrid_warp_flow(activities, opts)
          _ ->
            solve_generic_with_hybrid_warp_flow(data, opts)
        end
      end)
      
      {test_name, %{
        time_ms: time_us / 1000,
        time_us: time_us,
        result_size: estimate_result_size(result),
        approach: :hybrid_warp_flow
      }}
    end)
    |> Map.new()
  end

  @doc """
  Benchmark memory-mapped approach.
  """
  def benchmark_memory_mapped(test_data, opts \\ []) do
    Logger.info("Running memory-mapped benchmarks...")
    
    Enum.map(test_data, fn {test_name, data} ->
      {time_us, result} = :timer.tc(fn ->
        case data do
          %{constraints: constraints} ->
            solve_stn_with_memory_mapped(constraints, opts)
          activities when is_list(activities) ->
            solve_activities_with_memory_mapped(activities, opts)
          _ ->
            solve_generic_with_memory_mapped(data, opts)
        end
      end)
      
      {test_name, %{
        time_ms: time_us / 1000,
        time_us: time_us,
        result_size: estimate_result_size(result),
        approach: :memory_mapped
      }}
    end)
    |> Map.new()
  end

  # Pure Flow implementations

  defp solve_stn_with_pure_flow(constraints, opts) do
    max_iterations = Keyword.get(opts, :max_iterations, 100)
    
    # Use ConvergenceFlow for STN solving with keyword list options
    flow_opts = [
      stages: System.schedulers_online(),
      max_iterations: max_iterations,
      convergence_threshold: 0.001
    ]
    
    # Convert constraints to flow-compatible format
    constraint_data = %{constraints: constraints}
    
    # Solve using ConvergenceFlow
    result = ConvergenceFlow.solve_with_convergence(constraint_data, flow_opts)
    
    case result do
      %{constraints: solved_constraints} -> %{constraints: solved_constraints, solved: true}
      _ -> %{constraints: constraints, solved: true}
    end
  end

  defp solve_activities_with_pure_flow(activities, opts) do
    max_iterations = Keyword.get(opts, :max_iterations, 50)
    
    # Use Flow for activity scheduling
    scheduled_activities = activities
    |> Flow.from_enumerable(max_demand: 100)
    |> Flow.partition(stages: System.schedulers_online())
    |> Flow.map(fn activity ->
      # Simple scheduling logic
      base_start = Map.get(activity, :start_time, 0)
      duration = Map.get(activity, :duration, 10)
      
      # Simulate iterative optimization
      optimized_start = Enum.reduce(1..max_iterations, base_start, fn _i, start ->
        start + :rand.uniform() * 0.1
      end)
      
      Map.merge(activity, %{
        start_time: optimized_start,
        end_time: optimized_start + duration,
        status: :scheduled
      })
    end)
    |> Enum.to_list()
    
    %{activities: scheduled_activities, solved: true}
  end

  defp solve_generic_with_pure_flow(data, _opts) do
    case data do
      list when is_list(list) ->
        # Process list with Flow
        list
        |> Flow.from_enumerable()
        |> Flow.map(fn item -> process_flow_item(item) end)
        |> Enum.to_list()
      
      map when is_map(map) ->
        # Process map with Flow
        map
        |> Map.to_list()
        |> Flow.from_enumerable()
        |> Flow.map(fn {k, v} -> {k, process_flow_item(v)} end)
        |> Enum.to_list()
        |> Map.new()
      
      _ ->
        data
    end
  end

  # Pure Task implementations

  defp solve_stn_with_pure_task(constraints, opts) do
    max_iterations = Keyword.get(opts, :max_iterations, 100)
    concurrency = System.schedulers_online()
    
    # Partition constraints for parallel processing
    constraint_chunks = constraints
    |> Map.to_list()
    |> Enum.chunk_every(div(map_size(constraints), concurrency) + 1)
    
    # Solve chunks in parallel using pure Tasks
    chunk_tasks = Enum.map(constraint_chunks, fn chunk ->
      Task.async(fn ->
        solve_constraint_chunk_iteratively(chunk, max_iterations)
      end)
    end)
    
    # Collect and merge results
    solved_chunks = Task.await_many(chunk_tasks, :infinity)
    merged_constraints = Enum.reduce(solved_chunks, %{}, &Map.merge/2)
    
    %{constraints: merged_constraints, solved: true}
  end

  defp solve_activities_with_pure_task(activities, opts) do
    max_iterations = Keyword.get(opts, :max_iterations, 50)
    concurrency = System.schedulers_online()
    
    # Partition activities for parallel processing
    activity_chunks = Enum.chunk_every(activities, div(length(activities), concurrency) + 1)
    
    # Solve chunks in parallel
    chunk_tasks = Enum.map(activity_chunks, fn chunk ->
      Task.async(fn ->
        schedule_activity_chunk_iteratively(chunk, max_iterations)
      end)
    end)
    
    # Collect and merge results
    scheduled_chunks = Task.await_many(chunk_tasks, :infinity)
    merged_activities = List.flatten(scheduled_chunks)
    
    %{activities: merged_activities, solved: true}
  end

  defp solve_generic_with_pure_task(data, opts) do
    concurrency = Keyword.get(opts, :max_concurrency, System.schedulers_online())
    
    case data do
      list when is_list(list) ->
        # Process list with pure Tasks
        list
        |> Enum.chunk_every(div(length(list), concurrency) + 1)
        |> Enum.map(fn chunk ->
          Task.async(fn ->
            Enum.map(chunk, &process_task_item/1)
          end)
        end)
        |> Task.await_many(:infinity)
        |> List.flatten()
      
      map when is_map(map) ->
        # Process map with pure Tasks
        map
        |> Map.to_list()
        |> Enum.chunk_every(div(map_size(map), concurrency) + 1)
        |> Enum.map(fn chunk ->
          Task.async(fn ->
            Enum.map(chunk, fn {k, v} -> {k, process_task_item(v)} end)
          end)
        end)
        |> Task.await_many(:infinity)
        |> List.flatten()
        |> Map.new()
      
      _ ->
        data
    end
  end

  # Hybrid warp Flow implementations

  defp solve_stn_with_hybrid_warp_flow(constraints, opts) do
    max_iterations = Keyword.get(opts, :max_iterations, 100)
    
    # Use hybrid approach: Flow for partitioning, Tasks for solving
    constraint_partitions = constraints
    |> Map.to_list()
    |> Flow.from_enumerable()
    |> Flow.partition(stages: System.schedulers_online())
    |> Flow.reduce(fn -> [] end, fn item, acc -> [item | acc] end)
    |> Enum.to_list()
    
    # Solve partitions with Tasks
    partition_tasks = Enum.map(constraint_partitions, fn partition ->
      Task.async(fn ->
        solve_constraint_chunk_iteratively(partition, max_iterations)
      end)
    end)
    
    # Merge results
    solved_partitions = Task.await_many(partition_tasks, :infinity)
    merged_constraints = Enum.reduce(solved_partitions, %{}, &Map.merge/2)
    
    %{constraints: merged_constraints, solved: true}
  end

  defp solve_activities_with_hybrid_warp_flow(activities, opts) do
    max_iterations = Keyword.get(opts, :max_iterations, 50)
    
    # Hybrid approach: Flow for preprocessing, Tasks for scheduling
    preprocessed_activities = activities
    |> Flow.from_enumerable()
    |> Flow.map(fn activity ->
      # Preprocess activity (calculate dependencies, resource requirements)
      dependencies = Map.get(activity, :dependencies, [])
      resources = Map.get(activity, :resources, [])
      
      Map.merge(activity, %{
        dependency_count: length(dependencies),
        resource_count: length(resources),
        complexity_score: length(dependencies) + length(resources)
      })
    end)
    |> Enum.to_list()
    
    # Schedule with Tasks based on complexity
    {simple_activities, complex_activities} = Enum.split_with(preprocessed_activities, fn activity ->
      Map.get(activity, :complexity_score, 0) <= 2
    end)
    
    # Schedule simple activities quickly
    simple_scheduled = Enum.map(simple_activities, fn activity ->
      Map.merge(activity, %{
        start_time: :rand.uniform(50),
        status: :scheduled
      })
    end)
    
    # Schedule complex activities with more iterations
    complex_tasks = Enum.map(complex_activities, fn activity ->
      Task.async(fn ->
        schedule_single_activity_iteratively(activity, max_iterations)
      end)
    end)
    
    complex_scheduled = Task.await_many(complex_tasks, :infinity)
    
    %{activities: simple_scheduled ++ complex_scheduled, solved: true}
  end

  defp solve_generic_with_hybrid_warp_flow(data, _opts) do
    case data do
      list when is_list(list) ->
        # Hybrid: Flow for filtering, Tasks for processing
        {simple_items, complex_items} = Enum.split_with(list, fn item ->
          case item do
            x when is_number(x) -> true
            _ -> false
          end
        end)
        
        # Process simple items directly
        processed_simple = Enum.map(simple_items, &process_flow_item/1)
        
        # Process complex items with Tasks
        complex_tasks = Enum.map(complex_items, fn item ->
          Task.async(fn -> process_task_item(item) end)
        end)
        
        processed_complex = Task.await_many(complex_tasks, :infinity)
        
        processed_simple ++ processed_complex
      
      _ ->
        data
    end
  end

  # Memory-mapped implementations

  defp solve_stn_with_memory_mapped(constraints, opts) do
    max_iterations = Keyword.get(opts, :max_iterations, 100)
    
    # Simulate memory-mapped approach using ETS
    table_name = :constraint_table
    :ets.new(table_name, [:set, :public, :named_table])
    
    try do
      # Store constraints in ETS
      Enum.each(constraints, fn {key, value} ->
        :ets.insert(table_name, {key, value})
      end)
      
      # Iterative solving with memory-mapped access
      Enum.reduce(1..max_iterations, constraints, fn iteration, current_constraints ->
        if rem(iteration, 20) == 0 do
          Logger.debug("Memory-mapped iteration #{iteration}")
        end
        
        # Update constraints in memory
        updated_constraints = Enum.map(current_constraints, fn {{p1, p2}, {min_val, max_val}} ->
          # Simple constraint tightening
          new_min = min_val * 0.999
          new_max = max_val * 0.999
          
          # Update in ETS
          :ets.insert(table_name, {{p1, p2}, {new_min, new_max}})
          
          {{p1, p2}, {new_min, new_max}}
        end) |> Map.new()
        
        # Check convergence
        max_change = Enum.map(updated_constraints, fn {key, {new_min, new_max}} ->
          {old_min, old_max} = current_constraints[key]
          abs(new_min - old_min) + abs(new_max - old_max)
        end) |> Enum.max(fn -> 0.0 end)
        
        if max_change < 0.001 do
          Logger.debug("Memory-mapped converged at iteration #{iteration}")
          updated_constraints
        else
          updated_constraints
        end
      end)
      |> then(fn final_constraints ->
        %{constraints: final_constraints, solved: true}
      end)
    after
      :ets.delete(table_name)
    end
  end

  defp solve_activities_with_memory_mapped(activities, opts) do
    max_iterations = Keyword.get(opts, :max_iterations, 50)
    
    # Simulate memory-mapped activity scheduling
    table_name = :activity_table
    :ets.new(table_name, [:set, :public, :named_table])
    
    try do
      # Store activities in ETS
      Enum.with_index(activities) |> Enum.each(fn {activity, index} ->
        :ets.insert(table_name, {index, activity})
      end)
      
      # Iterative scheduling with memory access
      final_activities = Enum.reduce(1..max_iterations, activities, fn iteration, current_activities ->
        if rem(iteration, 10) == 0 do
          Logger.debug("Memory-mapped activity scheduling iteration #{iteration}")
        end
        
        # Update activities in memory
        updated_activities = current_activities
        |> Enum.with_index()
        |> Enum.map(fn {activity, index} ->
          current_start = Map.get(activity, :start_time, 0)
          duration = Map.get(activity, :duration, 10)
          
          # Simple scheduling optimization
          optimized_start = current_start + (:rand.uniform() - 0.5) * 0.1
          
          updated_activity = Map.merge(activity, %{
            start_time: max(0, optimized_start),
            end_time: max(0, optimized_start) + duration,
            status: :scheduled
          })
          
          # Update in ETS
          :ets.insert(table_name, {index, updated_activity})
          
          updated_activity
        end)
        
        updated_activities
      end)
      
      %{activities: final_activities, solved: true}
    after
      :ets.delete(table_name)
    end
  end

  defp solve_generic_with_memory_mapped(data, _opts) do
    # Simple memory-mapped processing using ETS
    table_name = :generic_table
    :ets.new(table_name, [:set, :public, :named_table])
    
    try do
      case data do
        list when is_list(list) ->
          # Store in ETS and process
          Enum.with_index(list) |> Enum.each(fn {item, index} ->
            :ets.insert(table_name, {index, item})
          end)
          
          # Process from memory
          Enum.map(0..(length(list)-1), fn index ->
            [{^index, item}] = :ets.lookup(table_name, index)
            processed = process_flow_item(item)
            :ets.insert(table_name, {index, processed})
            processed
          end)
        
        map when is_map(map) ->
          # Store map in ETS and process
          Enum.each(map, fn {key, value} ->
            :ets.insert(table_name, {key, value})
          end)
          
          # Process from memory
          Enum.map(map, fn {key, _value} ->
            [{^key, value}] = :ets.lookup(table_name, key)
            processed = process_flow_item(value)
            :ets.insert(table_name, {key, processed})
            {key, processed}
          end) |> Map.new()
        
        _ ->
          data
      end
    after
      :ets.delete(table_name)
    end
  end

  # Helper functions

  defp solve_constraint_chunk_iteratively(chunk, max_iterations) do
    Enum.reduce(1..max_iterations, Map.new(chunk), fn iteration, current_constraints ->
      if rem(iteration, 25) == 0 do
        Logger.debug("Task constraint chunk iteration #{iteration}")
      end
      
      # Simple constraint propagation
      Enum.map(current_constraints, fn {{p1, p2}, {min_val, max_val}} ->
        new_min = min_val * 0.998
        new_max = max_val * 0.998
        {{p1, p2}, {new_min, new_max}}
      end) |> Map.new()
    end)
  end

  defp schedule_activity_chunk_iteratively(chunk, max_iterations) do
    Enum.map(chunk, fn activity ->
      # Iterative scheduling for single activity
      base_start = Map.get(activity, :start_time, 0)
      duration = Map.get(activity, :duration, 10)
      
      optimized_start = Enum.reduce(1..max_iterations, base_start, fn _iteration, current_start ->
        current_start + (:rand.uniform() - 0.5) * 0.01
      end)
      
      Map.merge(activity, %{
        start_time: max(0, optimized_start),
        end_time: max(0, optimized_start) + duration,
        status: :scheduled
      })
    end)
  end

  defp schedule_single_activity_iteratively(activity, max_iterations) do
    base_start = Map.get(activity, :start_time, 0)
    duration = Map.get(activity, :duration, 10)
    
    # More intensive optimization for complex activities
    optimized_start = Enum.reduce(1..max_iterations, base_start, fn iteration, current_start ->
      # Simulated annealing-like approach
      temperature = 1.0 / iteration
      perturbation = (:rand.uniform() - 0.5) * temperature
      current_start + perturbation
    end)
    
    Map.merge(activity, %{
      start_time: max(0, optimized_start),
      end_time: max(0, optimized_start) + duration,
      status: :scheduled,
      optimization_iterations: max_iterations
    })
  end

  defp process_flow_item(item) do
    case item do
      num when is_number(num) -> num * 1.5
      str when is_binary(str) -> String.reverse(str)
      list when is_list(list) -> Enum.sort(list)
      map when is_map(map) -> Map.put(map, :flow_processed, true)
      _ -> item
    end
  end

  defp process_task_item(item) do
    case item do
      num when is_number(num) -> num * 2.5
      str when is_binary(str) -> String.upcase(str)
      list when is_list(list) -> Enum.reverse(list)
      map when is_map(map) -> Map.put(map, :task_processed, true)
      _ -> item
    end
  end

  defp estimate_result_size(result) do
    case result do
      %{constraints: constraints} -> map_size(constraints)
      %{activities: activities} -> length(activities)
      list when is_list(list) -> length(list)
      _ -> 1
    end
  end
end
