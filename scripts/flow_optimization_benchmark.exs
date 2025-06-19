#!/usr/bin/env elixir

# Flow Optimization Benchmark Script
# Tests different Flow optimization strategies against baseline performance

Mix.install([
  {:flow, "~> 1.2"},
  {:nx, "~> 0.7"},
  {:benchee, "~> 1.3"}
])

# Load the project modules
Code.require_file("../lib/aria_engine/convergence_flow.ex", __DIR__)
Code.require_file("../lib/aria_engine/convergence_flow_optimized.ex", __DIR__)
Code.require_file("../lib/aria_engine/convergence_nx.ex", __DIR__)

defmodule FlowOptimizationBenchmark do
  @moduledoc """
  Comprehensive benchmark comparing different Flow optimization strategies.
  
  Tests:
  1. Baseline Flow (current implementation)
  2. Streaming Flow (optimized)
  3. Pipeline Flow (optimized)
  4. Adaptive Flow (optimized)
  5. Hybrid Flow (optimized)
  6. Nx baseline (for comparison)
  """

  require Logger

  def run_comprehensive_benchmark do
    IO.puts("=== Flow Optimization Benchmark ===")
    IO.puts("Testing different Flow strategies for performance improvements")
    IO.puts("")

    # Test different problem sizes
    sizes = [10, 25, 50, 100, 250, 500]
    
    for size <- sizes do
      IO.puts("--- Testing size #{size} ---")
      
      # Generate test data
      activities = generate_test_activities(size)
      stn_data = generate_test_stn(size)
      
      # Run activity scheduling benchmarks
      IO.puts("Activity Scheduling:")
      benchmark_activity_approaches(activities, size)
      
      IO.puts("")
      
      # Run STN benchmarks
      IO.puts("STN Constraint Solving:")
      benchmark_stn_approaches(stn_data, size)
      
      IO.puts("")
      IO.puts(String.duplicate("=", 60))
      IO.puts("")
    end
  end

  def benchmark_activity_approaches(activities, size) do
    Benchee.run(
      %{
        "Baseline Flow" => fn -> 
          AriaEngine.ConvergenceFlow.solve_activities_with_convergence(activities, stages: 4)
        end,
        "Streaming Flow" => fn -> 
          AriaEngine.ConvergenceFlowOptimized.solve_activities_streaming(activities, stages: 4)
        end,
        "Pipeline Flow" => fn -> 
          AriaEngine.ConvergenceFlowOptimized.solve_activities_pipeline(activities, stages: 4)
        end,
        "Adaptive Flow" => fn -> 
          AriaEngine.ConvergenceFlowOptimized.solve_activities_adaptive(activities, stages: 4)
        end,
        "Hybrid Flow" => fn -> 
          AriaEngine.ConvergenceFlowOptimized.solve_activities_hybrid(activities, stages: 4)
        end,
        "Nx Baseline" => fn -> 
          AriaEngine.ConvergenceNx.solve_activities(activities, backend: :cpu)
        end
      },
      time: 3,
      memory_time: 1,
      reduction_time: 1,
      print: [
        fast_warning: false,
        configuration: false
      ],
      formatters: [
        {Benchee.Formatters.Console, 
         comparison: true, 
         extended_statistics: true
        }
      ]
    )
  end

  def benchmark_stn_approaches(stn_data, size) do
    Benchee.run(
      %{
        "Baseline Flow" => fn -> 
          AriaEngine.ConvergenceFlow.solve_stn_with_convergence(stn_data, stages: 4)
        end,
        "Streaming Flow" => fn -> 
          AriaEngine.ConvergenceFlowOptimized.solve_stn_streaming(stn_data, stages: 4)
        end,
        "Nx Baseline" => fn -> 
          AriaEngine.ConvergenceNx.solve_stn(stn_data.constraints, backend: :cpu)
        end
      },
      time: 3,
      memory_time: 1,
      reduction_time: 1,
      print: [
        fast_warning: false,
        configuration: false
      ],
      formatters: [
        {Benchee.Formatters.Console, 
         comparison: true, 
         extended_statistics: true
        }
      ]
    )
  end

  def run_detailed_analysis do
    IO.puts("=== Detailed Flow Analysis ===")
    IO.puts("Analyzing optimization characteristics for different approaches")
    IO.puts("")

    # Test with different complexity patterns
    test_cases = [
      {:simple, generate_simple_activities(100)},
      {:complex_resources, generate_resource_heavy_activities(100)},
      {:complex_dependencies, generate_dependency_heavy_activities(100)},
      {:mixed_complexity, generate_mixed_complexity_activities(100)}
    ]

    for {case_name, activities} <- test_cases do
      IO.puts("--- #{case_name |> Atom.to_string() |> String.upcase()} ---")
      
      # Analyze characteristics
      analysis = AriaEngine.ConvergenceFlowOptimized.analyze_activity_characteristics(activities)
      IO.puts("Characteristics: #{inspect(analysis, pretty: true)}")
      
      # Test adaptive selection
      IO.puts("Testing adaptive approach selection...")
      
      result = Benchee.run(
        %{
          "Adaptive Flow" => fn -> 
            AriaEngine.ConvergenceFlowOptimized.solve_activities_adaptive(activities)
          end,
          "Streaming Flow" => fn -> 
            AriaEngine.ConvergenceFlowOptimized.solve_activities_streaming(activities)
          end,
          "Pipeline Flow" => fn -> 
            AriaEngine.ConvergenceFlowOptimized.solve_activities_pipeline(activities)
          end,
          "Hybrid Flow" => fn -> 
            AriaEngine.ConvergenceFlowOptimized.solve_activities_hybrid(activities)
          end
        },
        time: 2,
        print: [fast_warning: false, configuration: false],
        formatters: [{Benchee.Formatters.Console, comparison: true}]
      )
      
      IO.puts("")
    end
  end

  def run_scalability_test do
    IO.puts("=== Scalability Analysis ===")
    IO.puts("Testing how different approaches scale with problem size")
    IO.puts("")

    # Test scaling from small to very large problems
    sizes = [10, 50, 100, 500, 1000, 2000]
    
    results = %{}
    
    for size <- sizes do
      IO.puts("Testing size #{size}...")
      
      activities = generate_test_activities(size)
      
      # Test each approach
      approaches = [
        {:streaming, &AriaEngine.ConvergenceFlowOptimized.solve_activities_streaming/2},
        {:pipeline, &AriaEngine.ConvergenceFlowOptimized.solve_activities_pipeline/2},
        {:adaptive, &AriaEngine.ConvergenceFlowOptimized.solve_activities_adaptive/2},
        {:hybrid, &AriaEngine.ConvergenceFlowOptimized.solve_activities_hybrid/2}
      ]
      
      size_results = for {name, func} <- approaches do
        time_start = System.monotonic_time(:microsecond)
        
        try do
          _result = func.(activities, [])
          time_end = System.monotonic_time(:microsecond)
          duration = time_end - time_start
          
          {name, duration}
        rescue
          error ->
            IO.puts("Error in #{name}: #{inspect(error)}")
            {name, :error}
        end
      end
      
      results = Map.put(results, size, size_results)
      
      # Print results for this size
      IO.puts("Results for size #{size}:")
      for {name, duration} <- size_results do
        case duration do
          :error -> IO.puts("  #{name}: ERROR")
          time -> IO.puts("  #{name}: #{Float.round(time / 1000, 2)}ms")
        end
      end
      IO.puts("")
    end
    
    # Analyze scaling patterns
    analyze_scaling_patterns(results)
  end

  def run_memory_analysis do
    IO.puts("=== Memory Usage Analysis ===")
    IO.puts("Comparing memory efficiency of different approaches")
    IO.puts("")

    size = 500
    activities = generate_test_activities(size)
    
    approaches = [
      {"Baseline Flow", fn -> AriaEngine.ConvergenceFlow.solve_activities_with_convergence(activities) end},
      {"Streaming Flow", fn -> AriaEngine.ConvergenceFlowOptimized.solve_activities_streaming(activities) end},
      {"Pipeline Flow", fn -> AriaEngine.ConvergenceFlowOptimized.solve_activities_pipeline(activities) end},
      {"Hybrid Flow", fn -> AriaEngine.ConvergenceFlowOptimized.solve_activities_hybrid(activities) end}
    ]
    
    for {name, func} <- approaches do
      IO.puts("Testing #{name}...")
      
      # Measure memory before
      :erlang.garbage_collect()
      {memory_before, _} = :erlang.process_info(self(), :memory)
      
      # Run the function
      _result = func.()
      
      # Measure memory after
      :erlang.garbage_collect()
      {memory_after, _} = :erlang.process_info(self(), :memory)
      
      memory_used = memory_after - memory_before
      IO.puts("  Memory used: #{Float.round(memory_used / 1024, 2)} KB")
    end
  end

  # Test data generation functions

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

  defp generate_simple_activities(count) do
    for i <- 1..count do
      %{
        id: "simple_#{i}",
        duration: 1,
        resources: ["resource_#{rem(i, 5)}"],
        dependencies: [],
        priority: 1
      }
    end
  end

  defp generate_resource_heavy_activities(count) do
    for i <- 1..count do
      %{
        id: "resource_heavy_#{i}",
        duration: :rand.uniform(5),
        resources: generate_resources(:rand.uniform(8) + 3), # 4-10 resources
        dependencies: generate_dependencies(i, count, 0.1), # Few dependencies
        priority: :rand.uniform(3)
      }
    end
  end

  defp generate_dependency_heavy_activities(count) do
    for i <- 1..count do
      %{
        id: "dep_heavy_#{i}",
        duration: :rand.uniform(3),
        resources: generate_resources(:rand.uniform(2)), # 1-2 resources
        dependencies: generate_dependencies(i, count, 0.4), # Many dependencies
        priority: :rand.uniform(5)
      }
    end
  end

  defp generate_mixed_complexity_activities(count) do
    for i <- 1..count do
      complexity = rem(i, 3)
      
      case complexity do
        0 -> # Simple
          %{
            id: "mixed_simple_#{i}",
            duration: 1,
            resources: ["resource_#{rem(i, 3)}"],
            dependencies: [],
            priority: 1
          }
        
        1 -> # Resource heavy
          %{
            id: "mixed_resource_#{i}",
            duration: :rand.uniform(5),
            resources: generate_resources(:rand.uniform(6) + 2),
            dependencies: generate_dependencies(i, count, 0.1),
            priority: :rand.uniform(3)
          }
        
        2 -> # Dependency heavy
          %{
            id: "mixed_dep_#{i}",
            duration: :rand.uniform(3),
            resources: generate_resources(:rand.uniform(2)),
            dependencies: generate_dependencies(i, count, 0.3),
            priority: :rand.uniform(5)
          }
      end
    end
  end

  defp generate_test_stn(count) do
    constraints = for i <- 1..count do
      {{"timepoint_#{i}", "timepoint_#{rem(i + 1, count) + 1}"}, :rand.uniform(10)}
    end
    
    %{constraints: Enum.into(constraints, %{})}
  end

  defp generate_resources(count) do
    for i <- 1..count do
      "resource_#{:rand.uniform(20)}"
    end
  end

  defp generate_dependencies(current_id, total_count, probability \\ 0.2) do
    if current_id == 1 do
      []
    else
      possible_deps = 1..(current_id - 1)
      
      possible_deps
      |> Enum.filter(fn _ -> :rand.uniform() < probability end)
      |> Enum.map(&"activity_#{&1}")
    end
  end

  defp analyze_scaling_patterns(results) do
    IO.puts("=== Scaling Pattern Analysis ===")
    
    # Extract successful results only
    clean_results = results
    |> Enum.map(fn {size, size_results} ->
      clean_size_results = size_results
      |> Enum.filter(fn {_name, duration} -> duration != :error end)
      
      {size, clean_size_results}
    end)
    |> Enum.filter(fn {_size, size_results} -> length(size_results) > 0 end)
    
    # Analyze each approach
    approaches = [:streaming, :pipeline, :adaptive, :hybrid]
    
    for approach <- approaches do
      IO.puts("#{approach |> Atom.to_string() |> String.upcase()} scaling:")
      
      approach_data = clean_results
      |> Enum.map(fn {size, size_results} ->
        case Enum.find(size_results, fn {name, _} -> name == approach end) do
          {^approach, duration} -> {size, duration}
          nil -> nil
        end
      end)
      |> Enum.filter(&(&1 != nil))
      
      if length(approach_data) >= 2 do
        # Calculate scaling factor
        [{size1, time1} | _] = approach_data
        {size2, time2} = List.last(approach_data)
        
        size_ratio = size2 / size1
        time_ratio = time2 / time1
        scaling_factor = time_ratio / size_ratio
        
        IO.puts("  Size #{size1} -> #{size2}: #{Float.round(scaling_factor, 3)}x scaling factor")
        
        # Print all data points
        for {size, time} <- approach_data do
          IO.puts("    Size #{size}: #{Float.round(time / 1000, 2)}ms")
        end
      else
        IO.puts("  Insufficient data for analysis")
      end
      
      IO.puts("")
    end
  end
end

# Run the benchmarks
case System.argv() do
  ["comprehensive"] -> FlowOptimizationBenchmark.run_comprehensive_benchmark()
  ["detailed"] -> FlowOptimizationBenchmark.run_detailed_analysis()
  ["scalability"] -> FlowOptimizationBenchmark.run_scalability_test()
  ["memory"] -> FlowOptimizationBenchmark.run_memory_analysis()
  ["all"] -> 
    FlowOptimizationBenchmark.run_comprehensive_benchmark()
    FlowOptimizationBenchmark.run_detailed_analysis()
    FlowOptimizationBenchmark.run_scalability_test()
    FlowOptimizationBenchmark.run_memory_analysis()
  _ -> 
    IO.puts("Usage: elixir flow_optimization_benchmark.exs [comprehensive|detailed|scalability|memory|all]")
    IO.puts("")
    IO.puts("  comprehensive - Compare all approaches across different sizes")
    IO.puts("  detailed      - Analyze optimization characteristics")
    IO.puts("  scalability   - Test scaling patterns")
    IO.puts("  memory        - Compare memory usage")
    IO.puts("  all           - Run all benchmarks")
end
