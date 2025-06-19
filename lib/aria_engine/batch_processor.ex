# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngine.BatchProcessor do
  @moduledoc """
  Batch processing for multiple convergence problems with optimal core distribution.
  
  Distributes CPU cores across multiple problems to achieve maximum utilization
  when solving multiple independent convergence problems simultaneously.
  
  This approach addresses the core utilization bottleneck observed in single-problem
  Flow processing by running multiple problems in parallel, each with its allocated
  subset of CPU cores.
  
  Expected performance improvement: 3-4x for multiple problem scenarios.
  """

  require Logger

  @doc """
  Solve multiple problems in parallel with optimal core distribution.
  
  Distributes available CPU cores across problems to maximize utilization.
  Each problem gets its fair share of cores for internal Flow processing.
  
  ## Options
  
  - `:max_concurrency` - Maximum number of problems to process simultaneously (default: number of problems)
  - `:timeout` - Timeout per problem in milliseconds (default: 60_000)
  - `:ordered` - Whether to preserve problem order in results (default: false for performance)
  - `:cores_per_problem` - Explicit core allocation per problem (overrides automatic calculation)
  
  ## Examples
  
      problems = [activities_batch_1, activities_batch_2, activities_batch_3]
      results = BatchProcessor.solve_multiple_problems(problems)
      
      # With custom options
      results = BatchProcessor.solve_multiple_problems(problems, 
        max_concurrency: 4, 
        timeout: 30_000
      )
      
      # Force single core per problem
      results = BatchProcessor.solve_multiple_problems(problems, cores_per_problem: 1)
      
      # Use all cores for each problem (sequential processing)
      results = BatchProcessor.solve_multiple_problems(problems, 
        cores_per_problem: System.schedulers_online(),
        max_concurrency: 1
      )
  """
  def solve_multiple_problems(problems, opts \\ []) when is_list(problems) do
    if length(problems) == 0 do
      []
    else
      max_concurrency = Keyword.get(opts, :max_concurrency, length(problems))
      timeout = Keyword.get(opts, :timeout, 60_000)
      ordered = Keyword.get(opts, :ordered, false)
      
      total_cores = System.schedulers_online()
      cores_per_problem = case Keyword.get(opts, :cores_per_problem) do
        nil -> max(1, div(total_cores, max_concurrency))  # Auto-calculate
        explicit_cores -> max(1, explicit_cores)         # Use explicit value
      end
      
      Logger.debug("Batch processing #{length(problems)} problems with #{cores_per_problem} cores each (#{max_concurrency} concurrent)")
      
      start_time = System.monotonic_time(:millisecond)
      
      results = problems
      |> Task.async_stream(fn problem ->
          solve_single_problem_with_cores(problem, cores_per_problem)
        end, 
        max_concurrency: max_concurrency,
        timeout: timeout,
        ordered: ordered
      )
      |> Enum.map(fn {:ok, result} -> result end)
      
      end_time = System.monotonic_time(:millisecond)
      duration = end_time - start_time
      
      Logger.info("Batch processing completed: #{length(problems)} problems in #{duration}ms")
      
      results
    end
  end
  
  @doc """
  Solve multiple problems using all available cores (distributed approach).
  
  This is the default behavior - distributes all CPU cores across problems
  for optimal parallel processing within each problem.
  
  Best for: Complex problems that benefit from internal parallelization.
  """
  def solve_multiple_problems_all_cores(problems, opts \\ []) do
    # Use default behavior (auto-calculate cores per problem)
    solve_multiple_problems(problems, opts)
  end
  
  @doc """
  Solve multiple problems using single core per problem (wide parallelism).
  
  Forces each problem to use only 1 core, maximizing the number of problems
  that can run simultaneously. This approach prioritizes parallelism across
  problems rather than within problems.
  
  Best for: Many simple problems or when testing cross-problem parallelism.
  """
  def solve_multiple_problems_single_core(problems, opts \\ []) do
    # Force single core per problem, maximize concurrency
    opts_with_single_core = Keyword.put(opts, :cores_per_problem, 1)
    solve_multiple_problems(problems, opts_with_single_core)
  end
  
  @doc """
  Solve multiple activity batches in parallel.
  
  Convenience function specifically for activity batch processing.
  Each batch is treated as an independent problem.
  """
  def solve_multiple_activities_batches(activity_batches, opts \\ []) do
    solve_multiple_problems(activity_batches, opts)
  end
  
  @doc """
  Solve multiple STN problems in parallel.
  
  Convenience function for STN constraint solving across multiple problem instances.
  """
  def solve_multiple_stn_problems(stn_problems, opts \\ []) do
    solve_multiple_problems(stn_problems, opts)
  end
  
  @doc """
  Benchmark batch processing performance against single-problem processing.
  
  Useful for measuring the actual performance improvement achieved by batch processing.
  """
  def benchmark_batch_vs_single(problems, opts \\ []) do
    Logger.info("Benchmarking batch vs single processing for #{length(problems)} problems")
    
    # Single problem processing (sequential)
    {single_time, single_results} = :timer.tc(fn ->
      Enum.map(problems, fn problem ->
        AriaEngine.ConvergenceFlow.solve_activities_with_convergence(problem)
      end)
    end)
    
    # Batch processing (parallel)
    {batch_time, batch_results} = :timer.tc(fn ->
      solve_multiple_problems(problems, opts)
    end)
    
    single_time_ms = div(single_time, 1000)
    batch_time_ms = div(batch_time, 1000)
    speedup = single_time_ms / max(batch_time_ms, 1)
    
    Logger.info("Performance comparison:")
    Logger.info("  Single processing: #{single_time_ms}ms")
    Logger.info("  Batch processing:  #{batch_time_ms}ms")
    Logger.info("  Speedup: #{Float.round(speedup, 2)}x")
    
    %{
      single_time_ms: single_time_ms,
      batch_time_ms: batch_time_ms,
      speedup: speedup,
      single_results: single_results,
      batch_results: batch_results
    }
  end
  
  @doc """
  Generate test problems for batch processing benchmarks.
  
  Creates multiple independent activity sets for testing batch processing performance.
  """
  def generate_test_problems(problem_count, activities_per_problem \\ 1000) do
    Logger.debug("Generating #{problem_count} test problems with #{activities_per_problem} activities each")
    
    for problem_id <- 1..problem_count do
      generate_single_test_problem(problem_id, activities_per_problem)
    end
  end
  
  # Private functions
  
  defp solve_single_problem_with_cores(problem, cores) do
    # Use the best-performing Flow approach with allocated cores
    case problem do
      activities when is_list(activities) ->
        AriaEngine.ConvergenceFlow.solve_activities_with_convergence(activities, stages: cores)
      
      %{activities: activities} ->
        result = AriaEngine.ConvergenceFlow.solve_activities_with_convergence(activities, stages: cores)
        Map.put(problem, :solution, result)
      
      stn_data ->
        # Handle STN problems or other data structures
        AriaEngine.ConvergenceFlow.solve_activities_with_convergence([stn_data], stages: cores)
    end
  end
  
  defp generate_single_test_problem(problem_id, activity_count) do
    # Generate realistic test activities for a single problem
    base_seed = problem_id * 1000
    :rand.seed(:exsss, {base_seed, base_seed + 1, base_seed + 2})
    
    for activity_id <- 1..activity_count do
      %{
        id: activity_id,
        problem_id: problem_id,
        name: "problem_#{problem_id}_activity_#{activity_id}",
        duration: :rand.uniform(50) + 10,
        resources: generate_test_resources(activity_id, problem_id),
        dependencies: generate_test_dependencies(activity_id, activity_count),
        priority: :rand.uniform(10),
        constraints: generate_test_constraints(activity_id)
      }
    end
  end
  
  defp generate_test_resources(activity_id, problem_id) do
    # Generate 1-3 resources per activity, scoped to the problem
    resource_count = :rand.uniform(3)
    resource_pool = ["cpu", "memory", "disk", "network", "gpu"]
    
    for i <- 1..resource_count do
      resource_type = Enum.at(resource_pool, rem(activity_id + i, length(resource_pool)))
      "#{resource_type}_p#{problem_id}"
    end
  end
  
  defp generate_test_dependencies(activity_id, _max_activities) do
    # Generate 0-2 dependencies per activity
    if activity_id > 1 and :rand.uniform(3) == 1 do
      dep_count = min(2, activity_id - 1)
      for _ <- 1..dep_count, do: :rand.uniform(activity_id - 1)
    else
      []
    end
  end
  
  defp generate_test_constraints(_activity_id) do
    # Generate realistic temporal constraints
    [
      %{type: :start_after, time: :rand.uniform(20)},
      %{type: :finish_before, time: :rand.uniform(100) + 50}
    ]
  end
end
