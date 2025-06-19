#!/usr/bin/env elixir

# CPU Utilization Flow Benchmark - Monitor core usage during Flow operations

defmodule CPUUtilizationBenchmark do
  @moduledoc """
  Enhanced Flow benchmark that monitors CPU utilization to determine
  if we're actually using all available cores during Flow operations.
  
  This will reveal whether performance plateaus are due to poor core
  utilization or other bottlenecks.
  """

  require Logger

  def run do
    IO.puts "=== CPU Utilization Flow Benchmark ==="
    
    # System information
    schedulers = System.schedulers_online()
    IO.puts "Available CPU cores: #{schedulers}"
    IO.puts "Erlang schedulers: #{:erlang.system_info(:schedulers)}"
    IO.puts ""
    
    # Enable scheduler wall time statistics
    :erlang.system_flag(:scheduler_wall_time, true)
    
    # Test with a large enough workload to see CPU patterns
    test_size = 10_000
    IO.puts "Testing with #{test_size} activities to monitor CPU utilization"
    IO.puts ""
    
    activities = generate_complex_activities(test_size)
    
    # Test each approach with CPU monitoring
    test_with_cpu_monitoring("Baseline Flow", fn -> 
      AriaEngine.ConvergenceFlow.solve_activities_with_convergence(activities, stages: schedulers)
    end)
    
    test_with_cpu_monitoring("Streaming Flow", fn -> 
      AriaEngine.ConvergenceFlowOptimized.solve_activities_streaming(activities, stages: schedulers)
    end)
    
    test_with_cpu_monitoring("Pipeline Flow", fn -> 
      AriaEngine.ConvergenceFlowOptimized.solve_activities_pipeline(activities, stages: schedulers)
    end)
    
    test_with_cpu_monitoring("Adaptive Flow", fn -> 
      AriaEngine.ConvergenceFlowOptimized.solve_activities_adaptive(activities, stages: schedulers)
    end)
    
    test_with_cpu_monitoring("Hybrid Flow", fn -> 
      AriaEngine.ConvergenceFlowOptimized.solve_activities_hybrid(activities, stages: schedulers)
    end)
    
    # Test new partition-aware approaches
    test_with_cpu_monitoring("Resource-Aware Partition Flow", fn -> 
      AriaEngine.ConvergenceFlowPartitionAware.solve_activities_resource_aware(activities, stages: schedulers)
    end)
    
    test_with_cpu_monitoring("Load-Balanced Partition Flow", fn -> 
      AriaEngine.ConvergenceFlowPartitionAware.solve_activities_load_balanced(activities, stages: schedulers)
    end)
    
    test_with_cpu_monitoring("Hybrid Partition-Aware Flow", fn -> 
      AriaEngine.ConvergenceFlowPartitionAware.solve_activities_hybrid_partition_aware(activities, stages: schedulers)
    end)
    
    IO.puts "=== CPU Utilization Analysis Complete ==="
  end
  
  defp test_with_cpu_monitoring(name, test_function) do
    IO.puts "--- #{name} ---"
    
    # Clear previous statistics
    :erlang.statistics(:scheduler_wall_time)
    
    # Run the test
    {time_us, result} = :timer.tc(test_function)
    
    # Get scheduler statistics
    scheduler_stats = :erlang.statistics(:scheduler_wall_time)
    
    # Calculate CPU utilization
    cpu_utilization = calculate_cpu_utilization(scheduler_stats)
    
    # Display results
    time_ms = div(time_us, 1000)
    activities_count = length(Map.get(result, :activities, []))
    throughput = if time_ms > 0, do: round(activities_count * 1000 / time_ms), else: 999999
    
    IO.puts "Time: #{time_ms}ms | Activities: #{activities_count} | Throughput: #{format_number(throughput)} activities/sec"
    IO.puts "CPU Utilization:"
    
    # Display per-scheduler utilization
    scheduler_stats
    |> Enum.with_index(1)
    |> Enum.each(fn {{_scheduler_id, active_time, total_time}, index} ->
      utilization = if total_time > 0, do: round(active_time / total_time * 100), else: 0
      IO.puts "  Scheduler #{index}: #{utilization}%"
    end)
    
    avg_utilization = round(cpu_utilization * 100)
    IO.puts "Average CPU Utilization: #{avg_utilization}%"
    
    # Analysis
    analyze_cpu_usage(cpu_utilization, length(scheduler_stats))
    
    IO.puts ""
  end
  
  defp calculate_cpu_utilization(scheduler_stats) do
    total_active = scheduler_stats |> Enum.map(fn {_, active, _} -> active end) |> Enum.sum()
    total_time = scheduler_stats |> Enum.map(fn {_, _, total} -> total end) |> Enum.sum()
    
    if total_time > 0, do: total_active / total_time, else: 0.0
  end
  
  defp analyze_cpu_usage(utilization, scheduler_count) do
    cond do
      utilization < 0.3 ->
        IO.puts "⚠️  LOW CPU USAGE: Only #{round(utilization * 100)}% - likely I/O bound or serialized"
      
      utilization < 0.6 ->
        IO.puts "⚡ MODERATE CPU USAGE: #{round(utilization * 100)}% - some parallelization but room for improvement"
      
      utilization > 0.8 ->
        IO.puts "🔥 HIGH CPU USAGE: #{round(utilization * 100)}% - good core utilization!"
      
      true ->
        IO.puts "✅ GOOD CPU USAGE: #{round(utilization * 100)}% - reasonable core utilization"
    end
    
    # Check if we're using multiple cores
    if scheduler_count > 1 do
      IO.puts "📊 Using #{scheduler_count} schedulers - multi-core processing active"
    else
      IO.puts "⚠️  Single scheduler - not utilizing multiple cores"
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
  
  defp format_number(num) when num >= 1_000_000 do
    "#{Float.round(num / 1_000_000, 1)}M"
  end
  
  defp format_number(num) when num >= 1_000 do
    "#{Float.round(num / 1_000, 1)}K"
  end
  
  defp format_number(num) do
    Integer.to_string(num)
  end
end

# Run the CPU utilization benchmark
CPUUtilizationBenchmark.run()
