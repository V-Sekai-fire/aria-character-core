#!/usr/bin/env elixir

# Flow Baseline Benchmark
# Test baseline Flow vs optimized Flow approaches

defmodule FlowBaselineBenchmark do
  @moduledoc """
  Benchmark baseline Flow against optimized Flow implementations.
  Focus on approaches that can beat the baseline.
  """

  def run do
    IO.puts "=== Flow Baseline vs Optimized Benchmark ==="
    IO.puts "Testing optimized approaches against baseline Flow"
    IO.puts ""
    
    # Test different problem sizes
    sizes = [10, 25, 50, 100]
    
    results = for size <- sizes do
      IO.puts "--- Testing size #{size} ---"
      activities = generate_test_activities(size)
      
      baseline_result = test_baseline_flow(activities, size)
      streaming_result = test_streaming_flow(activities, size)
      pipeline_result = test_pipeline_flow(activities, size)
      adaptive_result = test_adaptive_flow(activities, size)
      hybrid_result = test_hybrid_flow(activities, size)
      
      IO.puts ""
      
      %{
        size: size,
        baseline: baseline_result,
        streaming: streaming_result,
        pipeline: pipeline_result,
        adaptive: adaptive_result,
        hybrid: hybrid_result
      }
    end
    
    IO.puts "=== Performance Summary ==="
    print_performance_summary(results)
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
      throughput = if time_ms > 0, do: round(activities_count * 1000 / time_ms), else: 999999
      
      IO.puts "#{time_ms}ms | #{activities_count} activities | #{throughput} activities/sec"
      {true, time_ms, throughput}
    rescue
      e -> 
        IO.puts "FAILED - #{inspect(e)}"
        {false, 0, 0}
    end
  end
  
  defp test_streaming_flow(activities, size) do
    IO.write "Streaming Flow (#{size}): "
    
    try do
      {time_us, result} = :timer.tc(fn ->
        AriaEngine.ConvergenceFlowOptimized.solve_activities_streaming(activities, stages: 4)
      end)
      
      time_ms = div(time_us, 1000)
      activities_count = length(Map.get(result, :activities, []))
      throughput = if time_ms > 0, do: round(activities_count * 1000 / time_ms), else: 999999
      
      IO.puts "#{time_ms}ms | #{activities_count} activities | #{throughput} activities/sec"
      {true, time_ms, throughput}
    rescue
      e -> 
        IO.puts "FAILED - #{inspect(e)}"
        {false, 0, 0}
    end
  end
  
  defp test_pipeline_flow(activities, size) do
    IO.write "Pipeline Flow (#{size}): "
    
    try do
      {time_us, result} = :timer.tc(fn ->
        AriaEngine.ConvergenceFlowOptimized.solve_activities_pipeline(activities, stages: 4)
      end)
      
      time_ms = div(time_us, 1000)
      activities_count = length(Map.get(result, :activities, []))
      throughput = if time_ms > 0, do: round(activities_count * 1000 / time_ms), else: 999999
      
      IO.puts "#{time_ms}ms | #{activities_count} activities | #{throughput} activities/sec"
      {true, time_ms, throughput}
    rescue
      e -> 
        IO.puts "FAILED - #{inspect(e)}"
        {false, 0, 0}
    end
  end
  
  defp test_adaptive_flow(activities, size) do
    IO.write "Adaptive Flow (#{size}): "
    
    try do
      {time_us, result} = :timer.tc(fn ->
        AriaEngine.ConvergenceFlowOptimized.solve_activities_adaptive(activities, stages: 4)
      end)
      
      time_ms = div(time_us, 1000)
      activities_count = length(Map.get(result, :activities, []))
      throughput = if time_ms > 0, do: round(activities_count * 1000 / time_ms), else: 999999
      
      IO.puts "#{time_ms}ms | #{activities_count} activities | #{throughput} activities/sec"
      {true, time_ms, throughput}
    rescue
      e -> 
        IO.puts "FAILED - #{inspect(e)}"
        {false, 0, 0}
    end
  end
  
  defp test_hybrid_flow(activities, size) do
    IO.write "Hybrid Flow (#{size}): "
    
    try do
      {time_us, result} = :timer.tc(fn ->
        AriaEngine.ConvergenceFlowOptimized.solve_activities_hybrid(activities, stages: 4)
      end)
      
      time_ms = div(time_us, 1000)
      activities_count = length(Map.get(result, :activities, []))
      throughput = if time_ms > 0, do: round(activities_count * 1000 / time_ms), else: 999999
      
      IO.puts "#{time_ms}ms | #{activities_count} activities | #{throughput} activities/sec"
      {true, time_ms, throughput}
    rescue
      e -> 
        IO.puts "FAILED - #{inspect(e)}"
        {false, 0, 0}
    end
  end
  
  defp print_performance_summary(results) do
    IO.puts ""
    IO.puts "Performance vs Baseline:"
    IO.puts "Size | Streaming | Pipeline | Adaptive | Hybrid"
    IO.puts "-----|-----------|----------|----------|--------"
    
    for result <- results do
      {_, baseline_time, baseline_throughput} = result.baseline
      
      streaming_improvement = calculate_improvement(result.streaming, {baseline_time, baseline_throughput})
      pipeline_improvement = calculate_improvement(result.pipeline, {baseline_time, baseline_throughput})
      adaptive_improvement = calculate_improvement(result.adaptive, {baseline_time, baseline_throughput})
      hybrid_improvement = calculate_improvement(result.hybrid, {baseline_time, baseline_throughput})
      
      IO.puts "#{String.pad_leading(to_string(result.size), 4)} | #{streaming_improvement} | #{pipeline_improvement} | #{adaptive_improvement} | #{hybrid_improvement}"
    end
  end
  
  defp calculate_improvement({success, time, throughput}, {baseline_time, baseline_throughput}) do
    if success and baseline_time > 0 and time > 0 do
      time_improvement = round((baseline_time - time) / baseline_time * 100)
      throughput_improvement = round((throughput - baseline_throughput) / baseline_throughput * 100)
      
      cond do
        time_improvement > 0 -> "+#{time_improvement}%"
        time_improvement < 0 -> "#{time_improvement}%"
        true -> "0%"
      end
    else
      "FAIL"
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
FlowBaselineBenchmark.run()
