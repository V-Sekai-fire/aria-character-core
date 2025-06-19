# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngine.ConvergenceBenchmark do
  @moduledoc """
  Comprehensive benchmarking suite for convergence algorithms.
  
  This module provides benchmarking capabilities for various convergence approaches
  including traditional Flow-based methods, pure Nx tensor operations, and async Task concurrency.
  """

  require Logger
  
  alias AriaEngine.ConvergenceBenchmark.TraditionalApproaches
  alias AriaEngine.ConvergenceBenchmark.NxApproaches
  alias AriaEngine.ConvergenceBenchmark.TaskApproaches

  @doc """
  Run comprehensive convergence benchmarks with all available approaches.
  """
  def run_benchmarks(opts \\ []) do
    # Log system information for debugging
    schedulers = System.schedulers_online()
    total_schedulers = :erlang.system_info(:schedulers)
    Logger.info("Starting convergence benchmarks...")
    Logger.info("System cores: #{schedulers} online, #{total_schedulers} total")
    Logger.info("Max concurrency will be: #{schedulers * 16}")
    
    # Generate test data sets
    test_data = generate_test_data()
    
    # Warm up the system first
    warmup_system(test_data, opts)
    
    # Run benchmarks for each approach category
    results = %{}
    |> run_traditional_approaches(test_data, opts)
    |> run_nx_approaches(test_data, opts)
    |> run_task_approaches(test_data, opts)
    
    # Analyze and report results
    analyze_results(results)
  end

  @doc """
  Run statistical benchmarks with multiple runs for analysis.
  """
  def run_statistical_benchmarks(opts \\ []) do
    runs = Keyword.get(opts, :runs, 20)
    problem_sizes = Keyword.get(opts, :problem_sizes, [:tiny, :small, :medium, :large])
    
    Logger.info("Starting statistical convergence benchmarks...")
    Logger.info("Runs per test: #{runs}")
    Logger.info("Problem sizes: #{inspect(problem_sizes)}")
    
    # Generate test data for all problem sizes
    all_test_data = generate_scaled_test_data(problem_sizes)
    
    # Run statistical benchmarks
    statistical_results = run_multiple_benchmark_runs(all_test_data, runs, opts)
    
    # Generate statistical analysis and visualizations
    generate_statistical_report(statistical_results, opts)
  end

  # Traditional approaches (Pure Flow, Pure Task, Hybrid, Memory-mapped)
  defp run_traditional_approaches(results, test_data, opts) do
    Logger.info("=== Running Traditional Approaches ===")
    
    traditional_results = %{
      pure_flow: TraditionalApproaches.benchmark_pure_flow(test_data, opts),
      pure_task: TraditionalApproaches.benchmark_pure_task(test_data, opts),
      hybrid_warp_flow: TraditionalApproaches.benchmark_hybrid_warp_flow(test_data, opts),
      memory_mapped: TraditionalApproaches.benchmark_memory_mapped(test_data, opts)
    }
    
    Map.merge(results, traditional_results)
  end

  # Nx approaches (Pure tensors, optimized, batched)
  defp run_nx_approaches(results, test_data, opts) do
    Logger.info("=== Running Nx Tensor Approaches ===")
    
    nx_results = %{
      nx_tensors: NxApproaches.benchmark_nx_tensors(test_data, opts),
      nx_optimized: NxApproaches.benchmark_nx_optimized(test_data, opts),
      nx_batched: NxApproaches.benchmark_nx_batched(test_data, opts)
    }
    
    Map.merge(results, nx_results)
  end

  # Task approaches (Async tasks, task streams, supervised tasks)
  defp run_task_approaches(results, test_data, opts) do
    Logger.info("=== Running Async Task Approaches ===")
    
    task_results = %{
      async_tasks: TaskApproaches.benchmark_async_tasks(test_data, opts),
      task_stream: TaskApproaches.benchmark_task_stream(test_data, opts),
      supervised_tasks: TaskApproaches.benchmark_supervised_tasks(test_data, opts)
    }
    
    Map.merge(results, task_results)
  end

  @doc """
  Generate test data sets of varying sizes.
  """
  def generate_test_data do
    %{
      small_stn: generate_stn_constraints(50, 20),
      medium_stn: generate_stn_constraints(500, 100),
      large_stn: generate_stn_constraints(1000, 200),
      small_activities: generate_activities(100),
      medium_activities: generate_activities(1000),
      large_activities: generate_activities(2000)
    }
  end

  @doc """
  Generate test data for multiple problem sizes.
  """
  def generate_scaled_test_data(problem_sizes) do
    size_configs = %{
      tiny: %{stn_constraints: 10, stn_timepoints: 5, activities: 25},
      small: %{stn_constraints: 50, stn_timepoints: 20, activities: 100},
      medium: %{stn_constraints: 500, stn_timepoints: 100, activities: 1000},
      large: %{stn_constraints: 1000, stn_timepoints: 200, activities: 2000},
      xl: %{stn_constraints: 2000, stn_timepoints: 400, activities: 5000}
    }
    
    Enum.reduce(problem_sizes, %{}, fn size, acc ->
      config = size_configs[size]
      
      test_data = %{
        "#{size}_stn" => generate_stn_constraints(config.stn_constraints, config.stn_timepoints),
        "#{size}_activities" => generate_activities(config.activities)
      }
      
      Map.merge(acc, test_data)
    end)
  end

  @doc """
  Run multiple benchmark runs for statistical analysis.
  """
  def run_multiple_benchmark_runs(test_data, runs, opts) do
    approaches = [:pure_flow, :nx_tensors, :nx_optimized, :async_tasks, :task_stream]
    
    Logger.info("Running #{runs} benchmark runs for statistical analysis...")
    
    # Collect all timing data
    all_results = for run <- 1..runs do
      Logger.info("Statistical run #{run}/#{runs}")
      
      # Run each approach on each test case
      run_results = for approach <- approaches do
        approach_results = for {test_name, data} <- test_data do
          {time_us, result} = :timer.tc(fn ->
            case approach do
              :pure_flow ->
                TraditionalApproaches.benchmark_pure_flow(%{test_name => data}, opts)[test_name]
              :nx_tensors ->
                NxApproaches.benchmark_nx_tensors(%{test_name => data}, opts)[test_name]
              :nx_optimized ->
                NxApproaches.benchmark_nx_optimized(%{test_name => data}, opts)[test_name]
              :async_tasks ->
                TaskApproaches.benchmark_async_tasks(%{test_name => data}, opts)[test_name]
              :task_stream ->
                TaskApproaches.benchmark_task_stream(%{test_name => data}, opts)[test_name]
            end
          end)
          
          {test_name, %{
            approach: approach,
            run: run,
            time_us: time_us,
            time_ms: time_us / 1000,
            result_size: estimate_result_size(result),
            problem_size: extract_problem_size(test_name, data)
          }}
        end
        
        {approach, approach_results}
      end
      
      # Small delay between runs
      Process.sleep(50)
      :erlang.garbage_collect()
      
      run_results
    end
    
    # Flatten and organize results
    organize_statistical_results(all_results)
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

  # System warmup to ensure accurate benchmarking
  defp warmup_system(test_data, opts) do
    Logger.info("Warming up system for accurate benchmarking...")
    
    # Get a subset of test data for warmup
    warmup_data = %{
      warmup_stn: test_data.medium_stn,
      warmup_activities: test_data.medium_activities
    }
    
    # Run each approach multiple times to warm up JIT, caches, etc.
    warmup_rounds = Keyword.get(opts, :warmup_rounds, 3)
    
    Logger.info("Running #{warmup_rounds} warmup rounds...")
    
    for round <- 1..warmup_rounds do
      Logger.info("Warmup round #{round}/#{warmup_rounds}")
      
      # Warmup Pure Flow
      TraditionalApproaches.benchmark_pure_flow(warmup_data, Keyword.put(opts, :max_iterations, 3))
      
      # Warmup Nx Tensors
      NxApproaches.benchmark_nx_tensors(warmup_data, Keyword.put(opts, :max_iterations, 3))
      
      # Warmup Async Tasks
      TaskApproaches.benchmark_async_tasks(warmup_data, Keyword.put(opts, :max_iterations, 3))
      
      # Force garbage collection between rounds
      :erlang.garbage_collect()
      
      # Small delay to let system stabilize
      Process.sleep(100)
    end
    
    # Final garbage collection before benchmarks
    :erlang.garbage_collect()
    Process.sleep(500)
    
    Logger.info("System warmup complete. Starting benchmarks...")
  end

  # Statistical analysis helper functions
  defp extract_problem_size(test_name, data) do
    case data do
      %{constraints: constraints} -> map_size(constraints)
      activities when is_list(activities) -> length(activities)
      _ -> 1
    end
  end

  defp organize_statistical_results(all_results) do
    # Flatten all results into a single list
    flattened = all_results
    |> List.flatten()
    |> Enum.flat_map(fn {_approach, results} -> results end)
    
    # Group by test_name and approach
    flattened
    |> Enum.group_by(fn {test_name, _metrics} -> test_name end)
    |> Enum.map(fn {test_name, test_results} ->
      by_approach = test_results
      |> Enum.map(fn {_test_name, metrics} -> metrics end)
      |> Enum.group_by(& &1.approach)
      
      {test_name, by_approach}
    end)
    |> Map.new()
  end

  @doc """
  Generate statistical report with analysis.
  """
  def generate_statistical_report(statistical_results, _opts) do
    Logger.info("=== STATISTICAL CONVERGENCE ANALYSIS ===")
    
    # Calculate statistics for each test and approach
    stats_by_test = Enum.map(statistical_results, fn {test_name, by_approach} ->
      test_stats = Enum.map(by_approach, fn {approach, runs} ->
        times = Enum.map(runs, & &1.time_ms)
        problem_size = hd(runs).problem_size
        
        stats = calculate_statistics(times)
        
        {approach, Map.put(stats, :problem_size, problem_size)}
      end) |> Map.new()
      
      {test_name, test_stats}
    end) |> Map.new()
    
    # Generate performance comparison
    generate_performance_comparison(stats_by_test)
    
    # Generate scaling analysis
    generate_scaling_analysis(stats_by_test)
    
    stats_by_test
  end

  defp calculate_statistics(times) do
    sorted_times = Enum.sort(times)
    n = length(times)
    
    mean = Enum.sum(times) / n
    median = calculate_median(sorted_times)
    {q1, q3} = calculate_quartiles(sorted_times)
    
    variance = times
    |> Enum.map(fn t -> :math.pow(t - mean, 2) end)
    |> Enum.sum()
    |> Kernel./(n - 1)
    
    std_dev = :math.sqrt(variance)
    
    min_val = Enum.min(times)
    max_val = Enum.max(times)
    
    # Calculate outliers (values beyond 1.5 * IQR from quartiles)
    iqr = q3 - q1
    lower_fence = q1 - 1.5 * iqr
    upper_fence = q3 + 1.5 * iqr
    outliers = Enum.filter(times, fn t -> t < lower_fence or t > upper_fence end)
    
    %{
      mean: mean,
      median: median,
      std_dev: std_dev,
      min: min_val,
      max: max_val,
      q1: q1,
      q3: q3,
      iqr: iqr,
      outliers: outliers,
      count: n,
      raw_times: times
    }
  end

  defp calculate_median(sorted_times) do
    n = length(sorted_times)
    
    if rem(n, 2) == 0 do
      mid1 = Enum.at(sorted_times, div(n, 2) - 1)
      mid2 = Enum.at(sorted_times, div(n, 2))
      (mid1 + mid2) / 2
    else
      Enum.at(sorted_times, div(n, 2))
    end
  end

  defp calculate_quartiles(sorted_times) do
    n = length(sorted_times)
    
    q1_pos = div(n, 4)
    q3_pos = div(3 * n, 4)
    
    q1 = Enum.at(sorted_times, q1_pos)
    q3 = Enum.at(sorted_times, q3_pos)
    
    {q1, q3}
  end

  defp generate_performance_comparison(stats_by_test) do
    Logger.info("\n=== PERFORMANCE COMPARISON BY PROBLEM SIZE ===")
    
    # Group by problem size
    by_size = stats_by_test
    |> Enum.flat_map(fn {test_name, approaches} ->
      Enum.map(approaches, fn {approach, stats} ->
        {stats.problem_size, approach, stats.median, test_name}
      end)
    end)
    |> Enum.group_by(&elem(&1, 0))
    
    Enum.each(by_size, fn {size, results} ->
      Logger.info("\n--- Problem Size: #{size} ---")
      
      results
      |> Enum.group_by(&elem(&1, 3))  # Group by test name
      |> Enum.each(fn {test_name, test_results} ->
        Logger.info("#{test_name}:")
        
        test_results
        |> Enum.sort_by(&elem(&1, 2))  # Sort by median time
        |> Enum.each(fn {_size, approach, median, _test} ->
          Logger.info("  #{approach}: #{Float.round(median, 3)}ms (median)")
        end)
        
        # Find winner
        {_size, winner, best_time, _test} = Enum.min_by(test_results, &elem(&1, 2))
        Logger.info("  🏆 Winner: #{winner} (#{Float.round(best_time, 3)}ms)")
      end)
    end)
  end

  defp generate_scaling_analysis(stats_by_test) do
    Logger.info("\n=== SCALING ANALYSIS ===")
    
    # Analyze how each approach scales with problem size
    approaches = [:pure_flow, :nx_tensors, :nx_optimized, :async_tasks, :task_stream]
    
    Enum.each(approaches, fn approach ->
      Logger.info("\n--- #{String.upcase(to_string(approach))} SCALING ---")
      
      scaling_data = stats_by_test
      |> Enum.flat_map(fn {test_name, approach_stats} ->
        case approach_stats[approach] do
          nil -> []
          stats -> [{stats.problem_size, stats.median, test_name}]
        end
      end)
      |> Enum.sort_by(&elem(&1, 0))
      
      Enum.each(scaling_data, fn {size, median, test_name} ->
        Logger.info("Size #{size} (#{test_name}): #{Float.round(median, 3)}ms")
      end)
      
      # Calculate scaling factor
      if length(scaling_data) >= 2 do
        {min_size, min_time, _} = Enum.min_by(scaling_data, &elem(&1, 0))
        {max_size, max_time, _} = Enum.max_by(scaling_data, &elem(&1, 0))
        
        size_ratio = max_size / min_size
        time_ratio = max_time / min_time
        scaling_factor = time_ratio / size_ratio
        
        Logger.info("Scaling factor: #{Float.round(scaling_factor, 3)}x (time growth per size growth)")
      end
    end)
  end
end
