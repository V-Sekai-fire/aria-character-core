#!/usr/bin/env elixir

# Benchmark script to compare BatchProcessor core allocation strategies
# Tests both "all cores distributed" vs "single core per problem" approaches

Mix.install([
  {:flow, "~> 1.2"}
])

defmodule BatchCoreStrategyBenchmark do
  @moduledoc """
  Benchmark different core allocation strategies for the BatchProcessor.
  
  Compares:
  1. All cores distributed across problems (default)
  2. Single core per problem (maximum cross-problem parallelism)
  3. Sequential Flow processing (baseline)
  """

  require Logger

  def run_benchmark do
    Logger.configure(level: :info)
    
    IO.puts("=== BatchProcessor Core Strategy Benchmark ===")
    IO.puts("System: #{System.schedulers_online()} cores available")
    IO.puts("")
    
    # Test different problem counts and sizes
    test_scenarios = [
      {4, 500},   # 4 problems, 500 activities each
      {8, 250},   # 8 problems, 250 activities each  
      {16, 125},  # 16 problems, 125 activities each
      {32, 62}    # 32 problems, 62 activities each
    ]
    
    Enum.each(test_scenarios, fn {problem_count, activities_per_problem} ->
      run_scenario(problem_count, activities_per_problem)
      IO.puts("")
    end)
  end
  
  defp run_scenario(problem_count, activities_per_problem) do
    IO.puts("--- Scenario: #{problem_count} problems, #{activities_per_problem} activities each ---")
    
    # Generate test problems
    problems = generate_test_problems(problem_count, activities_per_problem)
    
    # Benchmark 1: Sequential Flow processing (baseline)
    {seq_time, _seq_results} = :timer.tc(fn ->
      Enum.map(problems, fn problem ->
        solve_single_problem_flow(problem)
      end)
    end)
    
    # Benchmark 2: BatchProcessor with all cores distributed
    {batch_all_time, _batch_all_results} = :timer.tc(fn ->
      solve_batch_all_cores(problems)
    end)
    
    # Benchmark 3: BatchProcessor with single core per problem
    {batch_single_time, _batch_single_results} = :timer.tc(fn ->
      solve_batch_single_core(problems)
    end)
    
    # Calculate results
    seq_ms = div(seq_time, 1000)
    batch_all_ms = div(batch_all_time, 1000)
    batch_single_ms = div(batch_single_time, 1000)
    
    speedup_all = seq_ms / max(batch_all_ms, 1)
    speedup_single = seq_ms / max(batch_single_ms, 1)
    
    IO.puts("Results:")
    IO.puts("  Sequential Flow:     #{seq_ms}ms")
    IO.puts("  Batch All Cores:     #{batch_all_ms}ms (#{Float.round(speedup_all, 2)}x speedup)")
    IO.puts("  Batch Single Core:   #{batch_single_ms}ms (#{Float.round(speedup_single, 2)}x speedup)")
    
    winner = determine_winner([
      {"Sequential", seq_ms},
      {"Batch All Cores", batch_all_ms}, 
      {"Batch Single Core", batch_single_ms}
    ])
    
    IO.puts("  Winner: #{winner}")
  end
  
  defp generate_test_problems(problem_count, activities_per_problem) do
    for problem_id <- 1..problem_count do
      generate_single_problem(problem_id, activities_per_problem)
    end
  end
  
  defp generate_single_problem(problem_id, activity_count) do
    # Generate realistic test activities
    base_seed = problem_id * 1000
    :rand.seed(:exsss, {base_seed, base_seed + 1, base_seed + 2})
    
    for activity_id <- 1..activity_count do
      %{
        id: activity_id,
        problem_id: problem_id,
        name: "problem_#{problem_id}_activity_#{activity_id}",
        duration: :rand.uniform(50) + 10,
        priority: :rand.uniform(10),
        resources: generate_resources(activity_id, problem_id),
        dependencies: generate_dependencies(activity_id, activity_count)
      }
    end
  end
  
  defp generate_resources(activity_id, problem_id) do
    resource_count = :rand.uniform(3)
    resource_pool = ["cpu", "memory", "disk", "network"]
    
    for i <- 1..resource_count do
      resource_type = Enum.at(resource_pool, rem(activity_id + i, length(resource_pool)))
      "#{resource_type}_p#{problem_id}"
    end
  end
  
  defp generate_dependencies(activity_id, _max_activities) do
    if activity_id > 1 and :rand.uniform(3) == 1 do
      dep_count = min(2, activity_id - 1)
      for _ <- 1..dep_count, do: :rand.uniform(activity_id - 1)
    else
      []
    end
  end
  
  # Mock solving functions (simulate computational work)
  
  defp solve_single_problem_flow(activities) do
    # Simulate Flow processing time
    activity_count = length(activities)
    processing_time = activity_count * 2  # 2ms per activity
    :timer.sleep(processing_time)
    
    %{
      activities: activities,
      solved: true,
      processing_time_ms: processing_time,
      approach: :flow_sequential
    }
  end
  
  defp solve_batch_all_cores(problems) do
    # Simulate BatchProcessor with all cores distributed
    total_cores = System.schedulers_online()
    max_concurrency = length(problems)
    cores_per_problem = max(1, div(total_cores, max_concurrency))
    
    problems
    |> Task.async_stream(fn problem ->
      solve_single_problem_with_cores(problem, cores_per_problem)
    end, max_concurrency: max_concurrency, timeout: :infinity)
    |> Enum.map(fn {:ok, result} -> result end)
  end
  
  defp solve_batch_single_core(problems) do
    # Simulate BatchProcessor with single core per problem
    problems
    |> Task.async_stream(fn problem ->
      solve_single_problem_with_cores(problem, 1)
    end, max_concurrency: length(problems), timeout: :infinity)
    |> Enum.map(fn {:ok, result} -> result end)
  end
  
  defp solve_single_problem_with_cores(activities, cores) do
    # Simulate processing time based on core allocation
    activity_count = length(activities)
    base_time = activity_count * 2  # 2ms per activity base time
    processing_time = max(5, div(base_time, cores))  # Simulate core scaling
    
    :timer.sleep(processing_time)
    
    %{
      activities: activities,
      solved: true,
      processing_time_ms: processing_time,
      cores_used: cores,
      approach: :batch_processor
    }
  end
  
  defp determine_winner(results) do
    {winner_name, _winner_time} = Enum.min_by(results, &elem(&1, 1))
    winner_name
  end
end

# Run the benchmark
BatchCoreStrategyBenchmark.run_benchmark()
