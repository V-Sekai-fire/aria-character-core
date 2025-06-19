#!/usr/bin/env elixir

# Large-Scale Convergence Benchmark
# Tests performance characteristics across different problem sizes to find crossover points

alias AriaEngine.Convergence

defmodule LargeScaleBenchmark do
  @moduledoc """
  Comprehensive benchmarking for convergence approaches at scale.
  """

  def run_full_benchmark do
    IO.puts("=== Large-Scale Convergence Benchmark ===\n")
    
    # Test configurations
    problem_sizes = [10, 25, 50, 100, 250, 500, 1000]
    batch_sizes = [8, 16, 32, 64]
    approaches = [:flow, :nx_cpu, :nx_pytorch]
    
    # Warm up the system
    IO.puts("Warming up system...")
    warmup()
    
    IO.puts("\n=== STN Constraint Benchmarks ===")
    stn_results = benchmark_stn_scaling(problem_sizes, approaches)
    
    IO.puts("\n=== Activity Scheduling Benchmarks ===")
    activity_results = benchmark_activity_scaling(problem_sizes, approaches)
    
    IO.puts("\n=== Batch Size Optimization ===")
    batch_results = benchmark_batch_sizes(batch_sizes, approaches)
    
    IO.puts("\n=== Performance Analysis ===")
    analyze_results(stn_results, activity_results, batch_results)
    
    # Save detailed results
    save_benchmark_results(%{
      stn: stn_results,
      activities: activity_results,
      batch_optimization: batch_results,
      timestamp: DateTime.utc_now()
    })
  end

  defp warmup do
    # Small warmup problems to eliminate JIT overhead
    small_constraints = generate_stn_problems(5, :dense)
    small_activities = generate_activity_problems(5, :complex)
    
    Enum.each([:flow, :nx_cpu], fn approach ->
      Convergence.solve_stn_batch(small_constraints, approach: approach_to_opts(approach))
      Convergence.solve_activities_batch(small_activities, approach: approach_to_opts(approach))
    end)
    
    :timer.sleep(1000)  # Let system settle
  end

  defp benchmark_stn_scaling(problem_sizes, approaches) do
    IO.puts("Testing STN constraint solving at different scales...")
    
    Enum.map(problem_sizes, fn size ->
      IO.puts("  Problem size: #{size} timelines")
      
      # Generate both dense and sparse constraint networks
      dense_problems = generate_stn_problems(size, :dense)
      sparse_problems = generate_stn_problems(size, :sparse)
      
      dense_results = benchmark_approaches(dense_problems, approaches, :stn)
      sparse_results = benchmark_approaches(sparse_problems, approaches, :stn)
      
      %{
        size: size,
        dense: dense_results,
        sparse: sparse_results
      }
    end)
  end

  defp benchmark_activity_scaling(problem_sizes, approaches) do
    IO.puts("Testing activity scheduling at different scales...")
    
    Enum.map(problem_sizes, fn size ->
      IO.puts("  Problem size: #{size} activities")
      
      # Generate both complex and simple dependency patterns
      complex_problems = generate_activity_problems(size, :complex)
      simple_problems = generate_activity_problems(size, :simple)
      
      complex_results = benchmark_approaches(complex_problems, approaches, :activities)
      simple_results = benchmark_approaches(simple_problems, approaches, :activities)
      
      %{
        size: size,
        complex: complex_results,
        simple: simple_results
      }
    end)
  end

  defp benchmark_batch_sizes(batch_sizes, approaches) do
    IO.puts("Testing optimal batch sizes...")
    
    # Use medium-sized problems for batch optimization
    test_size = 200
    stn_problems = generate_stn_problems(test_size, :dense)
    activity_problems = generate_activity_problems(test_size, :complex)
    
    Enum.map(batch_sizes, fn batch_size ->
      IO.puts("  Batch size: #{batch_size}")
      
      stn_results = Enum.map(approaches, fn approach ->
        opts = approach_to_opts(approach) ++ [batch_size: batch_size]
        {time, result} = :timer.tc(fn ->
          Convergence.solve_stn_batch(stn_problems, opts)
        end)
        
        {approach, %{time_ms: time / 1000, success_rate: result.successful_count / result.total_count}}
      end) |> Map.new()
      
      activity_results = Enum.map(approaches, fn approach ->
        opts = approach_to_opts(approach) ++ [batch_size: batch_size]
        {time, result} = :timer.tc(fn ->
          Convergence.solve_activities_batch(activity_problems, opts)
        end)
        
        {approach, %{time_ms: time / 1000, success_rate: result.successful_count / result.total_count}}
      end) |> Map.new()
      
      %{
        batch_size: batch_size,
        stn: stn_results,
        activities: activity_results
      }
    end)
  end

  defp benchmark_approaches(problems, approaches, problem_type) do
    solve_func = case problem_type do
      :stn -> &Convergence.solve_stn_batch/2
      :activities -> &Convergence.solve_activities_batch/2
    end
    
    Enum.map(approaches, fn approach ->
      # Run multiple iterations for statistical significance
      times = Enum.map(1..3, fn _iteration ->
        opts = approach_to_opts(approach)
        {time, result} = :timer.tc(fn -> solve_func.(problems, opts) end)
        
        %{
          time_ms: time / 1000,
          success_rate: result.successful_count / result.total_count,
          total_problems: result.total_count
        }
      end)
      
      # Calculate statistics
      avg_time = Enum.map(times, & &1.time_ms) |> Enum.sum() |> Kernel./(length(times))
      min_time = Enum.map(times, & &1.time_ms) |> Enum.min()
      max_time = Enum.map(times, & &1.time_ms) |> Enum.max()
      avg_success = Enum.map(times, & &1.success_rate) |> Enum.sum() |> Kernel./(length(times))
      
      {approach, %{
        avg_time_ms: avg_time,
        min_time_ms: min_time,
        max_time_ms: max_time,
        success_rate: avg_success,
        iterations: length(times)
      }}
    end) |> Map.new()
  end

  defp generate_stn_problems(count, density) do
    Enum.map(1..count, fn i ->
      constraints = case density do
        :dense -> generate_dense_constraints(i)
        :sparse -> generate_sparse_constraints(i)
      end
      
      %{
        id: "timeline_#{i}",
        constraints: constraints
      }
    end)
  end

  defp generate_activity_problems(count, complexity) do
    activities_per_set = max(5, div(count, 10))  # Reasonable activities per project
    set_count = div(count, activities_per_set)
    
    Enum.map(1..set_count, fn i ->
      activities = case complexity do
        :complex -> generate_complex_activities(activities_per_set, i)
        :simple -> generate_simple_activities(activities_per_set, i)
      end
      
      %{
        id: "project_#{i}",
        activities: activities
      }
    end)
  end

  defp generate_dense_constraints(timeline_id) do
    # Create a timeline with many interconnected constraints
    timepoints = ["start", "task1", "task2", "task3", "task4", "end"]
    
    # Generate constraints between most timepoint pairs
    for i <- 0..(length(timepoints)-2),
        j <- (i+1)..(length(timepoints)-1),
        into: %{} do
      p1 = Enum.at(timepoints, i)
      p2 = Enum.at(timepoints, j)
      
      # Add some randomness based on timeline_id for variety
      base_min = (j - i) * 5
      base_max = (j - i) * 15
      variation = rem(timeline_id * (i + j + 1), 10)
      
      {{p1, p2}, {base_min + variation, base_max + variation}}
    end
  end

  defp generate_sparse_constraints(timeline_id) do
    # Create a timeline with fewer, more linear constraints
    timepoints = ["start", "middle", "end"]
    
    base_duration = 10 + rem(timeline_id * 7, 20)
    
    %{
      {{"start", "middle"}, {base_duration, base_duration + 10}},
      {{"middle", "end"}, {base_duration, base_duration + 15}}
    }
  end

  defp generate_complex_activities(count, project_id) do
    Enum.map(1..count, fn i ->
      # Create complex dependency patterns
      dependencies = if i > 1 do
        # Some activities depend on multiple previous activities
        prev_count = min(i - 1, 3)
        Enum.map(1..prev_count, fn j -> "task_#{project_id}_#{i - j}" end)
      else
        []
      end
      
      resources = [
        "cpu_#{rem(i, 3)}",
        "memory_#{rem(i, 2)}",
        "disk_#{rem(i, 4)}"
      ] |> Enum.take(1 + rem(i, 2))  # 1-2 resources per activity
      
      %{
        id: "task_#{project_id}_#{i}",
        duration: 5 + rem(i * project_id, 15),
        resources: resources,
        dependencies: dependencies
      }
    end)
  end

  defp generate_simple_activities(count, project_id) do
    Enum.map(1..count, fn i ->
      # Simple linear dependency chain
      dependencies = if i > 1, do: ["task_#{project_id}_#{i - 1}"], else: []
      
      %{
        id: "task_#{project_id}_#{i}",
        duration: 5 + rem(i, 10),
        resources: ["worker_#{rem(i, 2)}"],
        dependencies: dependencies
      }
    end)
  end

  defp approach_to_opts(:flow), do: [approach: :flow]
  defp approach_to_opts(:nx_cpu), do: [approach: :nx, use_pytorch: false]
  defp approach_to_opts(:nx_pytorch), do: [approach: :nx, use_pytorch: true]

  defp analyze_results(stn_results, activity_results, batch_results) do
    IO.puts("Performance Analysis:")
    IO.puts("=" |> String.duplicate(50))
    
    # Find crossover points for STN
    IO.puts("\nSTN Constraint Solving:")
    analyze_crossover_points(stn_results, "STN")
    
    # Find crossover points for activities
    IO.puts("\nActivity Scheduling:")
    analyze_crossover_points(activity_results, "Activities")
    
    # Batch size recommendations
    IO.puts("\nBatch Size Optimization:")
    analyze_batch_optimization(batch_results)
    
    # Overall recommendations
    IO.puts("\nRecommendations:")
    print_recommendations(stn_results, activity_results)
  end

  defp analyze_crossover_points(results, problem_type) do
    case problem_type do
      "STN" ->
        Enum.each(results, fn %{size: size, dense: dense, sparse: sparse} ->
          dense_winner = find_fastest_approach(dense)
          sparse_winner = find_fastest_approach(sparse)
          
          IO.puts("  Size #{size}: Dense=#{dense_winner}, Sparse=#{sparse_winner}")
          
          # Show performance ratios
          if dense[:flow] && dense[:nx_cpu] do
            ratio = dense[:nx_cpu].avg_time_ms / dense[:flow].avg_time_ms
            IO.puts("    Dense Nx/Flow ratio: #{Float.round(ratio, 2)}x")
          end
        end)
      
      "Activities" ->
        Enum.each(results, fn %{size: size, complex: complex, simple: simple} ->
          complex_winner = find_fastest_approach(complex)
          simple_winner = find_fastest_approach(simple)
          
          IO.puts("  Size #{size}: Complex=#{complex_winner}, Simple=#{simple_winner}")
          
          # Show performance ratios
          if complex[:flow] && complex[:nx_cpu] do
            ratio = complex[:nx_cpu].avg_time_ms / complex[:flow].avg_time_ms
            IO.puts("    Complex Nx/Flow ratio: #{Float.round(ratio, 2)}x")
          end
        end)
    end
  end

  defp analyze_batch_optimization(batch_results) do
    Enum.each(batch_results, fn %{batch_size: size, stn: stn, activities: activities} ->
      stn_winner = find_fastest_approach(stn)
      activity_winner = find_fastest_approach(activities)
      
      IO.puts("  Batch #{size}: STN=#{stn_winner}, Activities=#{activity_winner}")
    end)
  end

  defp find_fastest_approach(results) do
    results
    |> Enum.min_by(fn {_approach, metrics} -> 
      Map.get(metrics, :avg_time_ms, Map.get(metrics, :time_ms, 999999))
    end)
    |> elem(0)
  end

  defp print_recommendations(stn_results, activity_results) do
    # Find the size where Nx becomes consistently faster
    nx_crossover_stn = find_crossover_size(stn_results, :dense)
    nx_crossover_activities = find_crossover_size(activity_results, :complex)
    
    IO.puts("  - Use Flow for STN problems < #{nx_crossover_stn} timelines")
    IO.puts("  - Use Nx for STN problems >= #{nx_crossover_stn} timelines")
    IO.puts("  - Use Flow for Activity problems < #{nx_crossover_activities} activities")
    IO.puts("  - Use Nx for Activity problems >= #{nx_crossover_activities} activities")
    IO.puts("  - Enable PyTorch acceleration for problems > 500 items")
  end

  defp find_crossover_size(results, variant) do
    crossover = Enum.find(results, fn result ->
      variant_results = Map.get(result, variant)
      flow_time = get_in(variant_results, [:flow, :avg_time_ms]) || 999999
      nx_time = get_in(variant_results, [:nx_cpu, :avg_time_ms]) || 999999
      
      nx_time < flow_time
    end)
    
    if crossover, do: crossover.size, else: 1000
  end

  defp save_benchmark_results(results) do
    filename = "large_scale_benchmark_results_#{DateTime.utc_now() |> DateTime.to_unix()}.json"
    File.write!(filename, Jason.encode!(results, pretty: true))
    IO.puts("\nDetailed results saved to: #{filename}")
  end
end

# Run the benchmark
LargeScaleBenchmark.run_full_benchmark()
