#!/usr/bin/env elixir

# Production-ready BatchProcessor test with both core allocation strategies

Mix.install([
  {:flow, "~> 1.2"}
])

Code.require_file("../lib/aria_engine/convergence_flow.ex", __DIR__)
Code.require_file("../lib/aria_engine/batch_processor.ex", __DIR__)
Code.require_file("../lib/aria_engine/convergence.ex", __DIR__)

defmodule ProductionBatchTest do
  @moduledoc """
  Production-ready test of BatchProcessor functionality.
  
  Tests both core allocation strategies:
  1. All cores distributed across problems (default)
  2. Single core per problem (maximum cross-problem parallelism)
  """

  require Logger

  def run_production_test do
    Logger.configure(level: :info)
    
    IO.puts("=== Production BatchProcessor Test ===")
    IO.puts("System: #{System.schedulers_online()} cores available")
    IO.puts("")
    
    # Production-scale test problems
    problem_count = 8
    activities_per_problem = 500
    
    IO.puts("Generating #{problem_count} problems with #{activities_per_problem} activities each...")
    problems = AriaEngine.BatchProcessor.generate_test_problems(problem_count, activities_per_problem)
    IO.puts("✅ Generated #{length(problems)} problems")
    IO.puts("")
    
    # Test 1: Sequential processing (baseline)
    seq_time = test_sequential_processing(problems)
    
    # Test 2: BatchProcessor with all cores distributed
    batch_all_time = test_batch_all_cores(problems)
    
    # Test 3: BatchProcessor with single core per problem
    batch_single_time = test_batch_single_core(problems)
    
    # Test 4: Use the new Convergence API
    api_time = test_convergence_api(problems)
    
    # Display performance summary
    display_performance_summary(seq_time, batch_all_time, batch_single_time, api_time)
    
    IO.puts("")
    IO.puts("🎉 Production BatchProcessor test complete!")
  end
  
  defp test_sequential_processing(problems) do
    IO.puts("--- Test 1: Sequential Processing (Baseline) ---")
    
    {time_us, results} = :timer.tc(fn ->
      Enum.map(problems, fn problem ->
        AriaEngine.ConvergenceFlow.solve_activities_with_convergence(problem)
      end)
    end)
    
    time_ms = div(time_us, 1000)
    IO.puts("Sequential processing: #{time_ms}ms")
    IO.puts("Results: #{length(results)} solutions")
    IO.puts("")
    
    time_ms
  end
  
  defp test_batch_all_cores(problems) do
    IO.puts("--- Test 2: BatchProcessor All Cores Distributed ---")
    
    {time_us, results} = :timer.tc(fn ->
      AriaEngine.BatchProcessor.solve_multiple_problems_all_cores(problems)
    end)
    
    time_ms = div(time_us, 1000)
    IO.puts("Batch all cores: #{time_ms}ms")
    IO.puts("Results: #{length(results)} solutions")
    IO.puts("")
    
    time_ms
  end
  
  defp test_batch_single_core(problems) do
    IO.puts("--- Test 3: BatchProcessor Single Core Per Problem ---")
    
    {time_us, results} = :timer.tc(fn ->
      AriaEngine.BatchProcessor.solve_multiple_problems_single_core(problems)
    end)
    
    time_ms = div(time_us, 1000)
    IO.puts("Batch single core: #{time_ms}ms")
    IO.puts("Results: #{length(results)} solutions")
    IO.puts("")
    
    time_ms
  end
  
  defp test_convergence_api(problems) do
    IO.puts("--- Test 4: New Convergence API ---")
    
    # Convert problems to activity sets format
    activity_sets = Enum.with_index(problems, 1)
    |> Enum.map(fn {activities, index} ->
      %{id: "project_#{index}", activities: activities}
    end)
    
    {time_us, result} = :timer.tc(fn ->
      AriaEngine.Convergence.solve_activities_batch(activity_sets)
    end)
    
    time_ms = div(time_us, 1000)
    IO.puts("Convergence API: #{time_ms}ms")
    IO.puts("Batch solved: #{result.batch_solved}")
    IO.puts("Total count: #{result.total_count}")
    IO.puts("Successful count: #{result.successful_count}")
    IO.puts("")
    
    time_ms
  end
  
  defp display_performance_summary(seq_time, batch_all_time, batch_single_time, api_time) do
    IO.puts("=== Performance Summary ===")
    IO.puts("Sequential:        #{seq_time}ms")
    IO.puts("Batch All Cores:   #{batch_all_time}ms (#{Float.round(seq_time / max(batch_all_time, 1), 2)}x speedup)")
    IO.puts("Batch Single Core: #{batch_single_time}ms (#{Float.round(seq_time / max(batch_single_time, 1), 2)}x speedup)")
    IO.puts("Convergence API:   #{api_time}ms (#{Float.round(seq_time / max(api_time, 1), 2)}x speedup)")
    
    best_time = Enum.min([batch_all_time, batch_single_time, api_time])
    best_speedup = seq_time / max(best_time, 1)
    
    cond do
      best_speedup > 5.0 -> IO.puts("🔥 Excellent speedup achieved!")
      best_speedup > 2.0 -> IO.puts("✅ Good speedup achieved")
      best_speedup > 1.2 -> IO.puts("⚡ Moderate improvement")
      true -> IO.puts("📊 Performance baseline established")
    end
  end
end

# Run the production test
ProductionBatchTest.run_production_test()
