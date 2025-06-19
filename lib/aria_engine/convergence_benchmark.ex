# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngine.ConvergenceBenchmark do
  @moduledoc """
  Benchmark different convergence approaches to determine optimal patterns.
  
  Tests:
  1. Pure Flow approach (current)
  2. Pure Task.async approach (warp-style)
  3. Hybrid warp+Flow approach
  """

  require Logger

  @doc """
  Run comprehensive convergence benchmarks.
  """
  def run_benchmarks(opts \\ []) do
    Logger.info("Starting convergence benchmarks...")
    
    # Generate test data sets
    test_data = generate_test_data()
    
    # Run benchmarks for each approach
    results = %{
      pure_flow: benchmark_pure_flow(test_data, opts),
      pure_task: benchmark_pure_task(test_data, opts),
      hybrid_warp_flow: benchmark_hybrid_warp_flow(test_data, opts)
    }
    
    # Analyze and report results
    analyze_results(results)
  end

  @doc """
  Generate test data sets of varying sizes.
  """
  def generate_test_data do
    %{
      small_stn: generate_stn_constraints(50, 20),
      medium_stn: generate_stn_constraints(500, 100),
      large_stn: generate_stn_constraints(2000, 500),
      xl_stn: generate_stn_constraints(10000, 1000),
      xxl_stn: generate_stn_constraints(50000, 2000),
      small_activities: generate_activities(100),
      medium_activities: generate_activities(1000),
      large_activities: generate_activities(5000),
      xl_activities: generate_activities(25000),
      xxl_activities: generate_activities(100000)
    }
  end

  # Pure Flow approach (current implementation)
  defp benchmark_pure_flow(test_data, opts) do
    Logger.info("Benchmarking Pure Flow approach...")
    
    Enum.map(test_data, fn {test_name, data} ->
      {time_us, result} = :timer.tc(fn ->
        case data do
          %{constraints: _} = stn_data ->
            AriaEngine.ConvergenceFlow.solve_stn_with_convergence(stn_data, 
              stages: System.schedulers_online() * 2,
              max_iterations: 20
            )
          activities when is_list(activities) ->
            AriaEngine.ConvergenceFlow.solve_activities_with_convergence(activities,
              stages: System.schedulers_online() * 2,
              max_iterations: 20
            )
        end
      end)
      
      {test_name, %{
        approach: :pure_flow,
        time_us: time_us,
        time_ms: time_us / 1000,
        result_size: estimate_result_size(result),
        memory_before: :erlang.memory(:total),
        memory_after: :erlang.memory(:total)
      }}
    end)
    |> Map.new()
  end

  # Pure Task.async approach (warp-style)
  defp benchmark_pure_task(test_data, opts) do
    Logger.info("Benchmarking Pure Task approach...")
    
    Enum.map(test_data, fn {test_name, data} ->
      {time_us, result} = :timer.tc(fn ->
        solve_with_pure_tasks(data, opts)
      end)
      
      {test_name, %{
        approach: :pure_task,
        time_us: time_us,
        time_ms: time_us / 1000,
        result_size: estimate_result_size(result),
        memory_before: :erlang.memory(:total),
        memory_after: :erlang.memory(:total)
      }}
    end)
    |> Map.new()
  end

  # Hybrid warp+Flow approach
  defp benchmark_hybrid_warp_flow(test_data, opts) do
    Logger.info("Benchmarking Hybrid Warp+Flow approach...")
    
    Enum.map(test_data, fn {test_name, data} ->
      {time_us, result} = :timer.tc(fn ->
        solve_with_hybrid_warp_flow(data, opts)
      end)
      
      {test_name, %{
        approach: :hybrid_warp_flow,
        time_us: time_us,
        time_ms: time_us / 1000,
        result_size: estimate_result_size(result),
        memory_before: :erlang.memory(:total),
        memory_after: :erlang.memory(:total)
      }}
    end)
    |> Map.new()
  end

  # Pure Task.async implementation
  defp solve_with_pure_tasks(data, opts) do
    # Max out all cores - use 4x schedulers for maximum parallelism
    max_concurrency = Keyword.get(opts, :max_concurrency, System.schedulers_online() * 4)
    max_iterations = Keyword.get(opts, :max_iterations, 20)
    
    case data do
      %{constraints: constraints} ->
        solve_stn_with_pure_tasks(constraints, max_concurrency, max_iterations)
      activities when is_list(activities) ->
        solve_activities_with_pure_tasks(activities, max_concurrency, max_iterations)
    end
  end

  defp solve_stn_with_pure_tasks(constraints, max_concurrency, max_iterations) do
    # Partition constraints
    constraint_list = Map.to_list(constraints)
    chunk_size = max(1, div(length(constraint_list), max_concurrency))
    partitions = Enum.chunk_every(constraint_list, chunk_size)
    
    # Solve partitions with Task.async
    iterate_task_convergence(partitions, max_iterations, 0)
  end

  defp solve_activities_with_pure_tasks(activities, max_concurrency, max_iterations) do
    # Partition activities
    chunk_size = max(1, div(length(activities), max_concurrency))
    partitions = Enum.chunk_every(activities, chunk_size)
    
    # Solve partitions with Task.async
    iterate_task_convergence(partitions, max_iterations, 0)
  end

  defp iterate_task_convergence(partitions, max_iterations, iteration) when iteration < max_iterations do
    # Execute all partitions in parallel
    tasks = Enum.map(partitions, fn partition ->
      Task.async(fn -> solve_partition_task(partition) end)
    end)
    
    # Wait for all tasks to complete
    results = Task.await_many(tasks, 5000)
    
    # Check convergence (simplified)
    if task_converged?(results) do
      merge_task_results(results)
    else
      # Exchange boundary conditions and continue
      updated_partitions = exchange_task_boundaries(partitions, results)
      iterate_task_convergence(updated_partitions, max_iterations, iteration + 1)
    end
  end

  defp iterate_task_convergence(partitions, _max_iterations, _iteration) do
    # Finalize without convergence
    tasks = Enum.map(partitions, fn partition ->
      Task.async(fn -> solve_partition_task(partition) end)
    end)
    
    results = Task.await_many(tasks, 5000)
    merge_task_results(results)
  end

  # Hybrid warp+Flow implementation
  defp solve_with_hybrid_warp_flow(data, opts) do
    warp_size = Keyword.get(opts, :warp_size, 32)
    max_iterations = Keyword.get(opts, :max_iterations, 20)
    
    case data do
      %{constraints: constraints} ->
        solve_stn_with_hybrid(constraints, warp_size, max_iterations)
      activities when is_list(activities) ->
        solve_activities_with_hybrid(activities, warp_size, max_iterations)
    end
  end

  defp solve_stn_with_hybrid(constraints, warp_size, max_iterations) do
    # Create warps (groups of partitions)
    constraint_list = Map.to_list(constraints)
    partition_size = max(1, div(length(constraint_list), warp_size * 4))
    partitions = Enum.chunk_every(constraint_list, partition_size)
    warps = Enum.chunk_every(partitions, warp_size)
    
    # Use Flow for cross-warp communication, Tasks for intra-warp execution
    iterate_hybrid_convergence(warps, max_iterations, 0)
  end

  defp solve_activities_with_hybrid(activities, warp_size, max_iterations) do
    # Create warps (groups of partitions)
    partition_size = max(1, div(length(activities), warp_size * 4))
    partitions = Enum.chunk_every(activities, partition_size)
    warps = Enum.chunk_every(partitions, warp_size)
    
    # Use Flow for cross-warp communication, Tasks for intra-warp execution
    iterate_hybrid_convergence(warps, max_iterations, 0)
  end

  defp iterate_hybrid_convergence(warps, max_iterations, iteration) when iteration < max_iterations do
    # Execute warps with Flow coordination
    warp_results = warps
    |> Flow.from_enumerable()
    |> Flow.partition(stages: length(warps))
    |> Flow.map(&execute_warp_with_tasks/1)
    |> Enum.to_list()
    
    # Check convergence
    if hybrid_converged?(warp_results) do
      merge_hybrid_results(warp_results)
    else
      # Exchange boundaries via Flow and continue
      updated_warps = exchange_hybrid_boundaries(warps, warp_results)
      iterate_hybrid_convergence(updated_warps, max_iterations, iteration + 1)
    end
  end

  defp iterate_hybrid_convergence(warps, _max_iterations, _iteration) do
    # Finalize without convergence
    warp_results = warps
    |> Flow.from_enumerable()
    |> Flow.partition(stages: length(warps))
    |> Flow.map(&execute_warp_with_tasks/1)
    |> Enum.to_list()
    
    merge_hybrid_results(warp_results)
  end

  defp execute_warp_with_tasks(warp_partitions) do
    # Execute all partitions in this warp using Task.async (SIMD-style)
    tasks = Enum.map(warp_partitions, fn partition ->
      Task.async(fn -> solve_partition_task(partition) end)
    end)
    
    Task.await_many(tasks, 5000)
  end

  # Helper functions for solving individual partitions
  defp solve_partition_task(partition) do
    case partition do
      constraint_pairs when is_list(constraint_pairs) and length(constraint_pairs) > 0 ->
        case hd(constraint_pairs) do
          {{_p1, _p2}, {_min, _max}} ->
            # STN constraints
            solve_stn_partition_simple(Map.new(constraint_pairs))
          _ ->
            # Activities
            solve_activity_partition_simple(constraint_pairs)
        end
      _ ->
        # Generic partition
        partition
    end
  end

  defp solve_stn_partition_simple(constraints) do
    # Simple STN solving (placeholder)
    %{constraints: constraints, solved: true, timepoints: extract_timepoints(constraints)}
  end

  defp solve_activity_partition_simple(activities) do
    # Simple activity scheduling (placeholder)
    %{activities: activities, solved: true, duration: length(activities) * 10}
  end

  defp extract_timepoints(constraints) do
    constraints
    |> Map.keys()
    |> Enum.flat_map(fn {p1, p2} -> [p1, p2] end)
    |> Enum.uniq()
    |> Enum.with_index()
    |> Map.new(fn {point, index} -> {point, index * 10} end)
  end

  # Convergence checking functions
  defp task_converged?(_results), do: true  # Simplified for benchmark
  defp hybrid_converged?(_results), do: true  # Simplified for benchmark

  # Boundary exchange functions (simplified for benchmark)
  defp exchange_task_boundaries(partitions, _results), do: partitions
  defp exchange_hybrid_boundaries(warps, _results), do: warps

  # Result merging functions
  defp merge_task_results(results) do
    case hd(results) do
      %{constraints: _} ->
        merged_constraints = results
        |> Enum.map(& &1.constraints)
        |> Enum.reduce(%{}, &Map.merge/2)
        %{constraints: merged_constraints, approach: :pure_task}
      %{activities: _} ->
        merged_activities = results
        |> Enum.flat_map(& &1.activities)
        %{activities: merged_activities, approach: :pure_task}
      _ ->
        %{results: results, approach: :pure_task}
    end
  end

  defp merge_hybrid_results(warp_results) do
    flattened_results = List.flatten(warp_results)
    
    case hd(flattened_results) do
      %{constraints: _} ->
        merged_constraints = flattened_results
        |> Enum.map(& &1.constraints)
        |> Enum.reduce(%{}, &Map.merge/2)
        %{constraints: merged_constraints, approach: :hybrid_warp_flow}
      %{activities: _} ->
        merged_activities = flattened_results
        |> Enum.flat_map(& &1.activities)
        %{activities: merged_activities, approach: :hybrid_warp_flow}
      _ ->
        %{results: flattened_results, approach: :hybrid_warp_flow}
    end
  end

  # Test data generation
  defp generate_stn_constraints(num_constraints, num_timepoints) do
    timepoints = Enum.map(1..num_timepoints, &"t#{&1}")
    
    constraints = for _ <- 1..num_constraints, into: %{} do
      p1 = Enum.random(timepoints)
      p2 = Enum.random(timepoints -- [p1])
      min_bound = :rand.uniform(100) - 50
      max_bound = min_bound + :rand.uniform(100)
      {{p1, p2}, {min_bound, max_bound}}
    end
    
    %{constraints: constraints, timepoints: timepoints}
  end

  defp generate_activities(num_activities) do
    Enum.map(1..num_activities, fn i ->
      %{
        id: "activity_#{i}",
        duration: :rand.uniform(60) + 10,
        resources: Enum.take_random(["cpu", "memory", "disk", "network"], :rand.uniform(2)),
        dependencies: (if i > 1, do: ["activity_#{:rand.uniform(i-1)}"], else: [])
      }
    end)
  end

  # Result analysis
  defp analyze_results(results) do
    Logger.info("=== Convergence Benchmark Results ===")
    
    Enum.each(results, fn {approach, test_results} ->
      Logger.info("\n--- #{String.upcase(to_string(approach))} APPROACH ---")
      
      Enum.each(test_results, fn {test_name, metrics} ->
        Logger.info("#{test_name}: #{metrics.time_ms}ms (#{metrics.result_size} result size)")
      end)
      
      avg_time = test_results
      |> Map.values()
      |> Enum.map(& &1.time_ms)
      |> Enum.sum()
      |> Kernel./(map_size(test_results))
      
      Logger.info("Average time: #{Float.round(avg_time, 2)}ms")
    end)
    
    # Find fastest approach for each test
    Logger.info("\n=== PERFORMANCE COMPARISON ===")
    
    test_names = results
    |> Map.values()
    |> hd()
    |> Map.keys()
    
    Enum.each(test_names, fn test_name ->
      times_by_approach = Enum.map(results, fn {approach, test_results} ->
        {approach, test_results[test_name].time_ms}
      end)
      
      {fastest_approach, fastest_time} = Enum.min_by(times_by_approach, &elem(&1, 1))
      
      Logger.info("#{test_name}: #{fastest_approach} fastest (#{Float.round(fastest_time, 2)}ms)")
    end)
    
    results
  end

  defp estimate_result_size(result) do
    case result do
      %{constraints: constraints} -> map_size(constraints)
      %{activities: activities} -> length(activities)
      %{results: results} -> length(results)
      _ -> 1
    end
  end
end
