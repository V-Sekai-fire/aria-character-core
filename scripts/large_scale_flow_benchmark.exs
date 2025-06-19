#!/usr/bin/env elixir

# Large Scale Flow Benchmark - Reveal performance gradients with realistic workloads

defmodule LargeScaleFlowBenchmark do
  @moduledoc """
  Large-scale Flow benchmark designed to reveal performance gradients between
  baseline and optimized Flow approaches using realistic activity counts and complexity.
  """

  require Logger

  def run do
    IO.puts "=== Large Scale Flow Performance Benchmark ==="
    IO.puts "Testing with realistic activity counts to reveal performance gradients"
    IO.puts ""
    
    # Test progressively larger problem sizes
    sizes = [500, 1_000, 2_500, 5_000, 10_000, 25_000]
    
    # Warmup run
    IO.puts "Warming up JIT compilation..."
    warmup_activities = generate_complex_activities(100)
    AriaEngine.ConvergenceFlow.solve_activities_with_convergence(warmup_activities, stages: 2)
    IO.puts "Warmup complete.\n"
    
    results = for size <- sizes do
      IO.puts "--- Testing size #{format_number(size)} ---"
      activities = generate_complex_activities(size)
      
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
    
    IO.puts "=== Performance Analysis ==="
    print_performance_analysis(results)
    IO.puts "=== Benchmark Complete ==="
  end
  
  defp test_baseline_flow(activities, size) do
    IO.write "Baseline Flow (#{format_number(size)}): "
    
    try do
      # Multiple runs for statistical significance
      times = for _ <- 1..3 do
        {time_us, result} = :timer.tc(fn ->
          AriaEngine.ConvergenceFlow.solve_activities_with_convergence(activities, stages: 2)
        end)
        
        activities_count = length(Map.get(result, :activities, []))
        {time_us, activities_count}
      end
      
      # Use median time for stability
      {median_time_us, activities_count} = times |> Enum.sort() |> Enum.at(1)
      time_ms = div(median_time_us, 1000)
      throughput = if time_ms > 0, do: round(activities_count * 1000 / time_ms), else: 999999
      
      IO.puts "#{time_ms}ms | #{format_number(activities_count)} activities | #{format_number(throughput)} activities/sec"
      {true, time_ms, throughput, activities_count}
    rescue
      e -> 
        IO.puts "FAILED - #{inspect(e)}"
        {false, 0, 0, 0}
    end
  end
  
  defp test_streaming_flow(activities, size) do
    IO.write "Streaming Flow (#{format_number(size)}): "
    
    try do
      times = for _ <- 1..3 do
        {time_us, result} = :timer.tc(fn ->
          AriaEngine.ConvergenceFlowOptimized.solve_activities_streaming(activities, stages: System.schedulers_online())
        end)
        
        activities_count = length(Map.get(result, :activities, []))
        {time_us, activities_count}
      end
      
      {median_time_us, activities_count} = times |> Enum.sort() |> Enum.at(1)
      time_ms = div(median_time_us, 1000)
      throughput = if time_ms > 0, do: round(activities_count * 1000 / time_ms), else: 999999
      
      IO.puts "#{time_ms}ms | #{format_number(activities_count)} activities | #{format_number(throughput)} activities/sec"
      {true, time_ms, throughput, activities_count}
    rescue
      e -> 
        IO.puts "FAILED - #{inspect(e)}"
        {false, 0, 0, 0}
    end
  end
  
  defp test_pipeline_flow(activities, size) do
    IO.write "Pipeline Flow (#{format_number(size)}): "
    
    try do
      times = for _ <- 1..3 do
        {time_us, result} = :timer.tc(fn ->
          AriaEngine.ConvergenceFlowOptimized.solve_activities_pipeline(activities, stages: System.schedulers_online())
        end)
        
        activities_count = length(Map.get(result, :activities, []))
        {time_us, activities_count}
      end
      
      {median_time_us, activities_count} = times |> Enum.sort() |> Enum.at(1)
      time_ms = div(median_time_us, 1000)
      throughput = if time_ms > 0, do: round(activities_count * 1000 / time_ms), else: 999999
      
      IO.puts "#{time_ms}ms | #{format_number(activities_count)} activities | #{format_number(throughput)} activities/sec"
      {true, time_ms, throughput, activities_count}
    rescue
      e -> 
        IO.puts "FAILED - #{inspect(e)}"
        {false, 0, 0, 0}
    end
  end
  
  defp test_adaptive_flow(activities, size) do
    IO.write "Adaptive Flow (#{format_number(size)}): "
    
    try do
      times = for _ <- 1..3 do
        {time_us, result} = :timer.tc(fn ->
          AriaEngine.ConvergenceFlowOptimized.solve_activities_adaptive(activities, stages: System.schedulers_online())
        end)
        
        activities_count = length(Map.get(result, :activities, []))
        {time_us, activities_count}
      end
      
      {median_time_us, activities_count} = times |> Enum.sort() |> Enum.at(1)
      time_ms = div(median_time_us, 1000)
      throughput = if time_ms > 0, do: round(activities_count * 1000 / time_ms), else: 999999
      
      IO.puts "#{time_ms}ms | #{format_number(activities_count)} activities | #{format_number(throughput)} activities/sec"
      {true, time_ms, throughput, activities_count}
    rescue
      e -> 
        IO.puts "FAILED - #{inspect(e)}"
        {false, 0, 0, 0}
    end
  end
  
  defp test_hybrid_flow(activities, size) do
    IO.write "Hybrid Flow (#{format_number(size)}): "
    
    try do
      times = for _ <- 1..3 do
        {time_us, result} = :timer.tc(fn ->
          AriaEngine.ConvergenceFlowOptimized.solve_activities_hybrid(activities, stages: System.schedulers_online())
        end)
        
        activities_count = length(Map.get(result, :activities, []))
        {time_us, activities_count}
      end
      
      {median_time_us, activities_count} = times |> Enum.sort() |> Enum.at(1)
      time_ms = div(median_time_us, 1000)
      throughput = if time_ms > 0, do: round(activities_count * 1000 / time_ms), else: 999999
      
      IO.puts "#{time_ms}ms | #{format_number(activities_count)} activities | #{format_number(throughput)} activities/sec"
      {true, time_ms, throughput, activities_count}
    rescue
      e -> 
        IO.puts "FAILED - #{inspect(e)}"
        {false, 0, 0, 0}
    end
  end
  
  defp generate_complex_activities(count) do
    # Generate realistic complex activities with dependencies and resource conflicts
    resource_pool = ["cpu", "memory", "disk", "network", "gpu", "database", "cache", "queue", "storage", "api"]
    
    for id <- 1..count do
      # Create realistic activity complexity
      num_resources = :rand.uniform(3) + 1  # 2-4 resources per activity
      resources = resource_pool |> Enum.shuffle() |> Enum.take(num_resources)
      
      # Create dependency chains (20% of activities have dependencies)
      dependencies = if :rand.uniform(100) <= 20 and id > 1 do
        dep_count = :rand.uniform(min(3, id - 1))
        for _ <- 1..dep_count, do: :rand.uniform(id - 1)
      else
        []
      end
      
      # Realistic durations and priorities
      duration = :rand.uniform(100) + 10  # 11-110 time units
      priority = :rand.uniform(10)
      
      %{
        id: id,
        name: "activity_#{id}",
        duration: duration,
        resources: resources,
        dependencies: dependencies,
        priority: priority,
        constraints: generate_constraints(id),
        metadata: %{
          complexity: length(resources) + length(dependencies),
          created_at: System.system_time(:millisecond)
        }
      }
    end
  end
  
  defp generate_constraints(id) do
    # Generate realistic temporal constraints
    base_constraints = [
      %{type: :start_after, time: :rand.uniform(50)},
      %{type: :finish_before, time: :rand.uniform(200) + 100}
    ]
    
    # Add resource constraints for some activities
    if rem(id, 5) == 0 do
      resource_constraint = %{
        type: :resource_limit,
        resource: Enum.random(["cpu", "memory", "disk"]),
        limit: :rand.uniform(100)
      }
      [resource_constraint | base_constraints]
    else
      base_constraints
    end
  end
  
  defp print_performance_analysis(results) do
    IO.puts "\nThroughput Comparison (activities/sec):"
    IO.puts "Size      | Baseline  | Streaming | Pipeline  | Adaptive  | Hybrid    | Best"
    IO.puts "----------|-----------|-----------|-----------|-----------|-----------|----------"
    
    for result <- results do
      size_str = format_number(result.size) |> String.pad_leading(8)
      
      baseline_throughput = format_throughput(result.baseline)
      streaming_throughput = format_throughput(result.streaming)
      pipeline_throughput = format_throughput(result.pipeline)
      adaptive_throughput = format_throughput(result.adaptive)
      hybrid_throughput = format_throughput(result.hybrid)
      
      # Find best performer
      throughputs = [
        {"Baseline", get_throughput(result.baseline)},
        {"Streaming", get_throughput(result.streaming)},
        {"Pipeline", get_throughput(result.pipeline)},
        {"Adaptive", get_throughput(result.adaptive)},
        {"Hybrid", get_throughput(result.hybrid)}
      ]
      
      {best_name, _best_throughput} = throughputs |> Enum.max_by(fn {_name, throughput} -> throughput end)
      
      IO.puts "#{size_str} | #{baseline_throughput} | #{streaming_throughput} | #{pipeline_throughput} | #{adaptive_throughput} | #{hybrid_throughput} | #{best_name}"
    end
    
    IO.puts "\nPerformance Improvements vs Baseline:"
    IO.puts "Size      | Streaming | Pipeline  | Adaptive  | Hybrid"
    IO.puts "----------|-----------|-----------|-----------|----------"
    
    for result <- results do
      size_str = format_number(result.size) |> String.pad_leading(8)
      baseline_tp = get_throughput(result.baseline)
      
      streaming_improvement = calculate_improvement(get_throughput(result.streaming), baseline_tp)
      pipeline_improvement = calculate_improvement(get_throughput(result.pipeline), baseline_tp)
      adaptive_improvement = calculate_improvement(get_throughput(result.adaptive), baseline_tp)
      hybrid_improvement = calculate_improvement(get_throughput(result.hybrid), baseline_tp)
      
      IO.puts "#{size_str} | #{streaming_improvement} | #{pipeline_improvement} | #{adaptive_improvement} | #{hybrid_improvement}"
    end
  end
  
  defp format_number(num) when num >= 1_000_000 do
    "#{Float.round(num / 1_000_000, 1)}M"
  end
  
  defp format_number(num) when num >= 1_000 do
    "#{Float.round(num / 1_000, 1)}K"
  end
  
  defp format_number(num) do
    Integer.to_string(num)
  end
  
  defp format_throughput({true, _time, throughput, _count}) do
    format_number(throughput) |> String.pad_leading(8)
  end
  
  defp format_throughput({false, _, _, _}) do
    "FAILED  "
  end
  
  defp get_throughput({true, _time, throughput, _count}), do: throughput
  defp get_throughput({false, _, _, _}), do: 0
  
  defp calculate_improvement(optimized_throughput, baseline_throughput) when baseline_throughput > 0 do
    improvement = round((optimized_throughput - baseline_throughput) / baseline_throughput * 100)
    improvement_str = if improvement > 0, do: "+#{improvement}%", else: "#{improvement}%"
    String.pad_leading(improvement_str, 8)
  end
  
  defp calculate_improvement(_optimized_throughput, _baseline_throughput) do
    "   N/A  "
  end
end

# Run the benchmark
LargeScaleFlowBenchmark.run()
