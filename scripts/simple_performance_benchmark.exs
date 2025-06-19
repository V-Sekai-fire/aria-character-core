#!/usr/bin/env elixir

# Simple Performance Benchmark
# Focus on working approaches to generate actual scores

defmodule SimplePerformanceBenchmark do
  @moduledoc """
  Simple benchmark focusing on stable, working approaches to generate concrete performance scores.
  """

  def run do
    IO.puts "=== Simple Performance Benchmark ==="
    IO.puts "Testing stable approaches for concrete performance scores"
    IO.puts ""
    
    # Test different problem sizes
    sizes = [10, 25, 50]
    
    for size <- sizes do
      IO.puts "--- Testing size #{size} ---"
      activities = generate_test_activities(size)
      
      test_baseline_flow(activities, size)
      test_nx_approach(activities, size)
      test_traditional_approach(activities, size)
      
      IO.puts ""
    end
    
    IO.puts "=== Benchmark Complete ==="
  end
  
  defp test_baseline_flow(activities, size) do
    IO.write "Baseline Flow (#{size}): "
    
    try do
      {time_us, result} = :timer.tc(fn ->
        AriaEngine.ConvergenceFlow.solve_activities_with_convergence(activities, stages: 4)
      end)
      
      time_ms = div(time_us, 1000)
      activities_count = length(Map.get(result, :activities, []))
      throughput = if time_ms > 0, do: round(activities_count * 1000 / time_ms), else: "∞"
      
      IO.puts "#{time_ms}ms | #{activities_count} activities | #{throughput} activities/sec"
    rescue
      e -> 
        IO.puts "FAILED - #{inspect(e)}"
    end
  end
  
  defp test_nx_approach(activities, size) do
    IO.write "Nx Approach (#{size}): "
    
    try do
      {time_us, result} = :timer.tc(fn ->
        AriaEngine.ConvergenceNx.solve_activities(activities, backend: :cpu)
      end)
      
      time_ms = div(time_us, 1000)
      activities_count = length(Map.get(result, :activities, []))
      throughput = if time_ms > 0, do: round(activities_count * 1000 / time_ms), else: "∞"
      
      IO.puts "#{time_ms}ms | #{activities_count} activities | #{throughput} activities/sec"
    rescue
      e -> 
        IO.puts "FAILED - #{inspect(e)}"
    end
  end
  
  defp test_traditional_approach(activities, size) do
    IO.write "Traditional (#{size}): "
    
    try do
      {time_us, result} = :timer.tc(fn ->
        AriaEngine.Convergence.solve_activities(activities)
      end)
      
      time_ms = div(time_us, 1000)
      activities_count = length(Map.get(result, :activities, []))
      throughput = if time_ms > 0, do: round(activities_count * 1000 / time_ms), else: "∞"
      
      IO.puts "#{time_ms}ms | #{activities_count} activities | #{throughput} activities/sec"
    rescue
      e -> 
        IO.puts "FAILED - #{inspect(e)}"
    end
  end
  
  defp generate_test_activities(count) do
    for i <- 1..count do
      %{
        id: "activity_#{i}",
        duration: :rand.uniform(10),
        resources: generate_resources(:rand.uniform(3)),
        dependencies: generate_dependencies(i, count),
        priority: :rand.uniform(5)
      }
    end
  end
  
  defp generate_resources(count) do
    available_resources = [:cpu, :memory, :disk, :network, :gpu]
    available_resources
    |> Enum.take_random(count)
  end
  
  defp generate_dependencies(current_id, total_count) do
    # Generate 0-2 dependencies on earlier activities
    dependency_count = :rand.uniform(3) - 1  # 0, 1, or 2
    
    if dependency_count > 0 and current_id > 1 do
      1..(current_id - 1)
      |> Enum.take_random(min(dependency_count, current_id - 1))
      |> Enum.map(&"activity_#{&1}")
    else
      []
    end
  end
end

# Run the benchmark
SimplePerformanceBenchmark.run()
