# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngine.ConvergenceBenchmark.TaskApproaches do
  @moduledoc """
  Async Task-based approaches for convergence benchmarking.
  
  This module implements algorithms using traditional Elixir concurrency
  with Task.async_stream and process-based parallelism.
  """

  require Logger

  @doc """
  Benchmark pure async Task approach.
  """
  def benchmark_async_tasks(test_data, opts \\ []) do
    Logger.info("Running async Task benchmarks...")
    
    Enum.map(test_data, fn {test_name, data} ->
      {time_us, result} = :timer.tc(fn ->
        case data do
          %{constraints: constraints} ->
            solve_stn_with_async_tasks(constraints, opts)
          activities when is_list(activities) ->
            solve_activities_with_async_tasks(activities, opts)
          _ ->
            solve_generic_with_async_tasks(data, opts)
        end
      end)
      
      {test_name, %{
        time_ms: time_us / 1000,
        time_us: time_us,
        result_size: estimate_result_size(result),
        approach: :async_tasks
      }}
    end)
    |> Map.new()
  end

  @doc """
  Benchmark Task.async_stream approach.
  """
  def benchmark_task_stream(test_data, opts \\ []) do
    Logger.info("Running Task.async_stream benchmarks...")
    
    max_concurrency = Keyword.get(opts, :max_concurrency, System.schedulers_online())
    
    Enum.map(test_data, fn {test_name, data} ->
      {time_us, result} = :timer.tc(fn ->
        case data do
          %{constraints: constraints} ->
            solve_stn_with_task_stream(constraints, max_concurrency, opts)
          activities when is_list(activities) ->
            solve_activities_with_task_stream(activities, max_concurrency, opts)
          _ ->
            solve_generic_with_task_stream(data, max_concurrency, opts)
        end
      end)
      
      {test_name, %{
        time_ms: time_us / 1000,
        time_us: time_us,
        result_size: estimate_result_size(result),
        approach: :task_stream
      }}
    end)
    |> Map.new()
  end

  @doc """
  Benchmark supervised Task approach.
  """
  def benchmark_supervised_tasks(test_data, opts \\ []) do
    Logger.info("Running supervised Task benchmarks...")
    
    Enum.map(test_data, fn {test_name, data} ->
      {time_us, result} = :timer.tc(fn ->
        case data do
          %{constraints: constraints} ->
            solve_stn_with_supervised_tasks(constraints, opts)
          activities when is_list(activities) ->
            solve_activities_with_supervised_tasks(activities, opts)
          _ ->
            solve_generic_with_supervised_tasks(data, opts)
        end
      end)
      
      {test_name, %{
        time_ms: time_us / 1000,
        time_us: time_us,
        result_size: estimate_result_size(result),
        approach: :supervised_tasks
      }}
    end)
    |> Map.new()
  end

  # STN solving with async Tasks

  defp solve_stn_with_async_tasks(constraints, opts) do
    max_iterations = Keyword.get(opts, :max_iterations, 100)
    concurrency = Keyword.get(opts, :max_concurrency, System.schedulers_online())
    
    # Partition constraints for parallel processing
    constraint_partitions = partition_constraints_for_tasks(constraints, concurrency)
    
    # Solve partitions in parallel using async tasks
    partition_tasks = Enum.map(constraint_partitions, fn partition ->
      Task.async(fn ->
        solve_constraint_partition_iteratively(partition, max_iterations)
      end)
    end)
    
    # Collect results and merge
    partition_results = Task.await_many(partition_tasks, :infinity)
    
    # Merge constraint solutions
    merge_constraint_partitions(partition_results)
  end

  defp solve_stn_with_task_stream(constraints, max_concurrency, opts) do
    max_iterations = Keyword.get(opts, :max_iterations, 100)
    
    # Convert constraints to list for streaming
    constraint_list = Map.to_list(constraints)
    
    # Process constraints using Task.async_stream
    solved_constraints = constraint_list
    |> Task.async_stream(
      fn constraint ->
        solve_single_constraint_iteratively(constraint, max_iterations)
      end,
      max_concurrency: max_concurrency,
      timeout: :infinity
    )
    |> Enum.map(fn {:ok, result} -> result end)
    |> Map.new()
    
    %{constraints: solved_constraints, solved: true}
  end

  defp solve_stn_with_supervised_tasks(constraints, opts) do
    max_iterations = Keyword.get(opts, :max_iterations, 100)
    
    # Use Task.Supervisor for better fault tolerance
    {:ok, supervisor} = Task.Supervisor.start_link()
    
    try do
      # Partition constraints
      constraint_partitions = partition_constraints_for_tasks(constraints, System.schedulers_online())
      
      # Solve using supervised tasks
      partition_tasks = Enum.map(constraint_partitions, fn partition ->
        Task.Supervisor.async(supervisor, fn ->
          solve_constraint_partition_iteratively(partition, max_iterations)
        end)
      end)
      
      # Await results
      partition_results = Task.await_many(partition_tasks, :infinity)
      
      # Merge results
      merge_constraint_partitions(partition_results)
    after
      # Clean up supervisor
      Process.exit(supervisor, :normal)
    end
  end

  # Activity scheduling with async Tasks

  defp solve_activities_with_async_tasks(activities, opts) do
    max_iterations = Keyword.get(opts, :max_iterations, 50)
    concurrency = Keyword.get(opts, :max_concurrency, System.schedulers_online())
    
    # Partition activities for parallel processing
    activity_partitions = Enum.chunk_every(activities, div(length(activities), concurrency) + 1)
    
    # Solve partitions in parallel
    partition_tasks = Enum.map(activity_partitions, fn partition ->
      Task.async(fn ->
        solve_activity_partition_iteratively(partition, max_iterations)
      end)
    end)
    
    # Collect and merge results
    partition_results = Task.await_many(partition_tasks, :infinity)
    
    merge_activity_partitions(partition_results)
  end

  defp solve_activities_with_task_stream(activities, max_concurrency, opts) do
    max_iterations = Keyword.get(opts, :max_iterations, 50)
    
    # Process activities using Task.async_stream
    scheduled_activities = activities
    |> Task.async_stream(
      fn activity ->
        schedule_single_activity_iteratively(activity, max_iterations)
      end,
      max_concurrency: max_concurrency,
      timeout: :infinity
    )
    |> Enum.map(fn {:ok, result} -> result end)
    
    %{activities: scheduled_activities, solved: true}
  end

  defp solve_activities_with_supervised_tasks(activities, opts) do
    max_iterations = Keyword.get(opts, :max_iterations, 50)
    
    # Use supervised tasks for activity scheduling
    {:ok, supervisor} = Task.Supervisor.start_link()
    
    try do
      # Partition activities
      activity_partitions = Enum.chunk_every(activities, div(length(activities), System.schedulers_online()) + 1)
      
      # Solve using supervised tasks
      partition_tasks = Enum.map(activity_partitions, fn partition ->
        Task.Supervisor.async(supervisor, fn ->
          solve_activity_partition_iteratively(partition, max_iterations)
        end)
      end)
      
      # Await and merge results
      partition_results = Task.await_many(partition_tasks, :infinity)
      merge_activity_partitions(partition_results)
    after
      Process.exit(supervisor, :normal)
    end
  end

  # Generic problem solving with async Tasks

  defp solve_generic_with_async_tasks(data, opts) do
    concurrency = Keyword.get(opts, :max_concurrency, System.schedulers_online())
    
    case data do
      list when is_list(list) ->
        # Process list items in parallel
        list
        |> Enum.chunk_every(div(length(list), concurrency) + 1)
        |> Enum.map(fn chunk ->
          Task.async(fn ->
            Enum.map(chunk, fn item -> process_generic_item(item) end)
          end)
        end)
        |> Task.await_many(:infinity)
        |> List.flatten()
      
      map when is_map(map) ->
        # Process map entries in parallel
        map
        |> Map.to_list()
        |> Enum.chunk_every(div(map_size(map), concurrency) + 1)
        |> Enum.map(fn chunk ->
          Task.async(fn ->
            Enum.map(chunk, fn {k, v} -> {k, process_generic_item(v)} end)
          end)
        end)
        |> Task.await_many(:infinity)
        |> List.flatten()
        |> Map.new()
      
      _ ->
        data
    end
  end

  defp solve_generic_with_task_stream(data, max_concurrency, _opts) do
    case data do
      list when is_list(list) ->
        list
        |> Task.async_stream(&process_generic_item/1, max_concurrency: max_concurrency)
        |> Enum.map(fn {:ok, result} -> result end)
      
      map when is_map(map) ->
        map
        |> Map.to_list()
        |> Task.async_stream(
          fn {k, v} -> {k, process_generic_item(v)} end,
          max_concurrency: max_concurrency
        )
        |> Enum.map(fn {:ok, result} -> result end)
        |> Map.new()
      
      _ ->
        data
    end
  end

  defp solve_generic_with_supervised_tasks(data, opts) do
    # Use supervised tasks for generic processing
    {:ok, supervisor} = Task.Supervisor.start_link()
    
    try do
      solve_generic_with_async_tasks(data, opts)
    after
      Process.exit(supervisor, :normal)
    end
  end

  # Core solving algorithms

  defp solve_constraint_partition_iteratively(constraints, max_iterations) do
    # Iterative constraint solving for a partition
    Enum.reduce(0..(max_iterations-1), constraints, fn iteration, current_constraints ->
      if rem(iteration, 20) == 0 do
        Logger.debug("Task constraint solving iteration #{iteration}")
      end
      
      # Apply constraint propagation
      updated_constraints = propagate_constraints_in_partition(current_constraints)
      
      # Check for convergence
      if constraints_converged?(current_constraints, updated_constraints) do
        Logger.debug("Task constraint partition converged at iteration #{iteration}")
        updated_constraints
      else
        updated_constraints
      end
    end)
  end

  defp solve_single_constraint_iteratively(constraint, max_iterations) do
    # Solve a single constraint iteratively
    {{p1, p2}, {min_val, max_val}} = constraint
    
    # Simple constraint tightening
    Enum.reduce(0..(max_iterations-1), {min_val, max_val}, fn _iteration, {current_min, current_max} ->
      # Tighten bounds slightly
      new_min = current_min * 0.99
      new_max = current_max * 0.99
      
      {new_min, new_max}
    end)
    |> then(fn {final_min, final_max} ->
      {{p1, p2}, {final_min, final_max}}
    end)
  end

  defp solve_activity_partition_iteratively(activities, max_iterations) do
    # Iterative activity scheduling for a partition
    Enum.reduce(0..(max_iterations-1), activities, fn iteration, current_activities ->
      if rem(iteration, 20) == 0 do
        Logger.debug("Task activity scheduling iteration #{iteration}")
      end
      
      # Update activity scheduling
      updated_activities = update_activity_scheduling_in_partition(current_activities)
      
      # Check for convergence
      if activities_converged?(current_activities, updated_activities) do
        Logger.debug("Task activity partition converged at iteration #{iteration}")
        updated_activities
      else
        updated_activities
      end
    end)
  end

  defp schedule_single_activity_iteratively(activity, max_iterations) do
    # Schedule a single activity iteratively
    base_duration = Map.get(activity, :duration, 10)
    
    # Iterative scheduling optimization
    optimized_duration = Enum.reduce(0..(max_iterations-1), base_duration, fn _iteration, current_duration ->
      # Simple duration optimization
      current_duration * 0.98
    end)
    
    Map.merge(activity, %{
      optimized_duration: optimized_duration,
      start_time: :rand.uniform(100),
      status: :scheduled
    })
  end

  # Helper functions

  defp partition_constraints_for_tasks(constraints, num_partitions) do
    # Partition constraints for parallel task processing
    constraint_list = Map.to_list(constraints)
    chunk_size = div(length(constraint_list), num_partitions) + 1
    
    constraint_list
    |> Enum.chunk_every(chunk_size)
    |> Enum.map(&Map.new/1)
  end

  defp propagate_constraints_in_partition(constraints) do
    # Simple constraint propagation within a partition
    Enum.map(constraints, fn {{p1, p2}, {min_val, max_val}} ->
      # Tighten constraints slightly
      new_min = min_val * 0.995
      new_max = max_val * 0.995
      
      {{p1, p2}, {new_min, new_max}}
    end)
    |> Map.new()
  end

  defp update_activity_scheduling_in_partition(activities) do
    # Update activity scheduling within a partition
    Enum.map(activities, fn activity ->
      current_duration = Map.get(activity, :duration, 10)
      
      Map.merge(activity, %{
        duration: current_duration * 0.99,
        last_updated: System.system_time(:millisecond)
      })
    end)
  end

  defp process_generic_item(item) do
    # Generic item processing
    case item do
      num when is_number(num) -> num * 2.0
      str when is_binary(str) -> String.upcase(str)
      list when is_list(list) -> Enum.reverse(list)
      map when is_map(map) -> Map.put(map, :processed, true)
      _ -> item
    end
  end

  # Convergence checking

  defp constraints_converged?(old_constraints, new_constraints) do
    # Check if constraints have converged
    if map_size(old_constraints) != map_size(new_constraints) do
      false
    else
      max_change = old_constraints
      |> Enum.map(fn {key, {old_min, old_max}} ->
        case new_constraints[key] do
          {new_min, new_max} ->
            abs(old_min - new_min) + abs(old_max - new_max)
          _ ->
            1000.0  # Large change if constraint missing
        end
      end)
      |> Enum.max(fn -> 0.0 end)
      
      max_change < 0.001
    end
  end

  defp activities_converged?(old_activities, new_activities) do
    # Check if activities have converged
    if length(old_activities) != length(new_activities) do
      false
    else
      max_change = Enum.zip(old_activities, new_activities)
      |> Enum.map(fn {old_activity, new_activity} ->
        old_duration = Map.get(old_activity, :duration, 0)
        new_duration = Map.get(new_activity, :duration, 0)
        abs(old_duration - new_duration)
      end)
      |> Enum.max(fn -> 0.0 end)
      
      max_change < 0.01
    end
  end

  # Result merging

  defp merge_constraint_partitions(partition_results) do
    # Merge constraint partition results
    merged_constraints = partition_results
    |> Enum.reduce(%{}, fn partition_result, acc ->
      Map.merge(acc, partition_result)
    end)
    
    %{constraints: merged_constraints, solved: true}
  end

  defp merge_activity_partitions(partition_results) do
    # Merge activity partition results
    merged_activities = partition_results
    |> List.flatten()
    
    %{activities: merged_activities, solved: true}
  end

  # Helper functions

  defp estimate_result_size(result) do
    case result do
      %{constraints: constraints} -> map_size(constraints)
      %{activities: activities} -> length(activities)
      list when is_list(list) -> length(list)
      _ -> 1
    end
  end
end
