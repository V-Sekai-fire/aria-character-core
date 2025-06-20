# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngine.PC2Benchmark do
  @moduledoc """
  Performance benchmarking for PC2 algorithm with Apple Vision Pro optimization.
  """

  require Logger
  alias Timeline.Internal.STN
  alias Timeline.Internal.STN.PC2

  # Apple Vision Pro performance thresholds (in milliseconds)
  @vision_pro_critical 0.5   # Ultra-safe threshold for 96fps
  @vision_pro_warning 1.0    # Warning threshold
  @vision_pro_failure 2.0    # Will impact frame rate
  @vision_pro_frame_budget 10.4  # Total frame budget at 96fps

  def generate_test_stn(size) when is_integer(size) and size > 0 do
    Logger.info("Generating test STN with size: #{size}")
    :rand.seed(:exsss, {1, 2, 3})

    # Generate time points
    time_points = Enum.map(1..size, &Integer.to_string/1)
    time_points_set = MapSet.new(time_points)

    # Generate random constraints
    constraint_pairs = for i <- 1..size, j <- 1..size, i < j, do: {Integer.to_string(i), Integer.to_string(j)}
    constraints = Enum.reduce(constraint_pairs, %{}, fn {i, j}, acc ->
      lower_bound = (:rand.uniform() * 200) - 100
      upper_bound = (:rand.uniform() * 200) - 100

      Map.put(acc, {i, j}, {lower_bound, upper_bound})
    end)

    %STN{
      time_points: time_points_set,
      constraints: constraints,
      consistent: true,
      time_unit: :second
    }
  end

  def run_pc2_solve(stn) do
    Logger.info("Running PC2 solve on STN")

    start_time = System.monotonic_time()
    result_stn = PC2.apply_pc2(stn)
    result = result_stn.consistent

    end_time = System.monotonic_time()
    elapsed_time = (end_time - start_time) / 1_000_000

    %{
      result: result,
      time: elapsed_time
    }
  end

  def collect_timing_data(results) do
    Logger.info("Collecting timing data")

    times =
      results
      |> Enum.filter(fn result -> is_number(result.time) end)
      |> Enum.map(fn result -> result.time end)

    if length(times) == 0 do
      %{avg: 0, min: 0, max: 0, p95: 0, vision_pro: %{critical_compliance: 0, warning_compliance: 0, failure_rate: 100}}
    else
      avg = Enum.sum(times) / length(times)
      min = Enum.min(times)
      max = Enum.max(times)

      sorted_times = Enum.sort(times)
      p95_index = round((length(times) - 1) * 0.95)
      p95 = Enum.at(sorted_times, p95_index)

      vision_pro_analysis = analyze_vision_pro_compliance(times)

      %{
        avg: avg,
        min: min,
        max: max,
        p95: p95,
        vision_pro: vision_pro_analysis
      }
    end
  end

  def analyze_vision_pro_compliance(times) do
    total_count = length(times)
    
    critical_compliant = Enum.count(times, fn time -> time <= @vision_pro_critical end)
    warning_compliant = Enum.count(times, fn time -> time <= @vision_pro_warning end)
    failure_count = Enum.count(times, fn time -> time > @vision_pro_failure end)

    %{
      critical_compliance: (critical_compliant / total_count) * 100,
      warning_compliance: (warning_compliant / total_count) * 100,
      failure_rate: (failure_count / total_count) * 100,
      frame_budget_usage: calculate_frame_budget_usage(times)
    }
  end

  defp calculate_frame_budget_usage(times) do
    avg_time = Enum.sum(times) / length(times)
    (avg_time / @vision_pro_frame_budget) * 100
  end

  def run_scaling_benchmark(opts \\ []) do
    sizes = Keyword.get(opts, :sizes, [5, 10, 25, 50, 100])
    iterations = Keyword.get(opts, :iterations, 10)

    Logger.info("Running scaling benchmark with sizes: #{inspect(sizes)} and iterations: #{iterations}")

    results =
      Enum.map(sizes, fn size ->
        benchmark_size(size, iterations, opts)
      end)

    analyze_scaling_results(results)
  end

  def benchmark_size(size, iterations, _opts) do
    Logger.info("Benchmarking size: #{size} with #{iterations} iterations")

    Enum.map(1..iterations, fn _i ->
      stn = generate_test_stn(size)
      result = run_pc2_solve(stn)
      {stn, result}
    end)
  end

  def analyze_scaling_results(results) do
    Logger.info("Analyzing scaling results")

    Enum.map(results, fn size_results ->
      stn = List.first(size_results) |> elem(0)
      size = MapSet.size(stn.time_points)
      timing_data = size_results |> Enum.map(fn {_, result} -> result end) |> collect_timing_data()

      %{
        size: size,
        timing: timing_data,
        stn: stn
      }
    end)
  end

  def format_benchmark_report(analysis) do
    Logger.info("Formatting benchmark report")

    report =
      "PC2 Scaling Benchmark Results\n" <>
      "============================\n" <>
      "Size |  Avg Time  |  Min Time  |  Max Time  |  P95 Time\n" <>
      "-----|-----------|------------|------------|------------\n" <>
      Enum.map_join(analysis, "\n", fn result ->
        size = result.size
        avg = result.timing.avg
        min = result.timing.min
        max = result.timing.max
        p95 = result.timing.p95

        "#{size} | #{avg} | #{min} | #{max} | #{p95}"
      end)

    Logger.debug(report)
    report
  end

  def format_vision_pro_report(analysis) do
    Logger.info("Formatting Apple Vision Pro performance report")

    header = """
    Apple Vision Pro PC2 Performance Analysis
    ========================================
    Target: 96fps (10.4ms frame budget)
    Critical Threshold: #{@vision_pro_critical}ms
    Warning Threshold: #{@vision_pro_warning}ms
    Failure Threshold: #{@vision_pro_failure}ms

    """

    table_header = """
    Size | Avg(ms) | Critical% | Warning% | Failure% | Budget%
    -----|---------|-----------|----------|----------|--------
    """

    table_rows = Enum.map_join(analysis, "\n", fn result ->
      size = result.size
      avg = Float.round(result.timing.avg, 3)
      vp = result.timing.vision_pro
      critical = Float.round(vp.critical_compliance, 1)
      warning = Float.round(vp.warning_compliance, 1)
      failure = Float.round(vp.failure_rate, 1)
      budget = Float.round(vp.frame_budget_usage, 1)
      
      status = cond do
        vp.critical_compliance >= 95.0 -> " ✅"
        vp.warning_compliance >= 90.0 -> " ⚠️"
        true -> " ❌"
      end

      "#{size} | #{avg} | #{critical}% | #{warning}% | #{failure}% | #{budget}%#{status}"
    end)

    recommendations = generate_vision_pro_recommendations(analysis)

    report = header <> table_header <> table_rows <> "\n\n" <> recommendations

    Logger.debug(report)
    report
  end

  defp generate_vision_pro_recommendations(analysis) do
    max_safe_size = Enum.find_value(analysis, fn result ->
      if result.timing.vision_pro.critical_compliance >= 95.0 do
        result.size
      end
    end)

    max_warning_size = Enum.find_value(analysis, fn result ->
      if result.timing.vision_pro.warning_compliance >= 90.0 do
        result.size
      end
    end)

    """
    Apple Vision Pro Recommendations:
    ================================
    
    ✅ Maximum safe constraint network size: #{max_safe_size || "< 5"} nodes
    ⚠️  Maximum acceptable size with monitoring: #{max_warning_size || "< 5"} nodes
    
    For optimal Vision Pro performance:
    • Keep temporal constraint networks under #{max_safe_size || 5} nodes
    • Consider constraint pruning for larger networks
    • Implement adaptive complexity based on thermal state
    • Use background processing during low-activity periods
    """
  end

  def run_vision_pro_benchmark(opts \\ []) do
    Logger.info("Running complete Apple Vision Pro PC2 performance analysis")
    
    # Use smaller sizes and more iterations for Vision Pro analysis
    vision_pro_opts = Keyword.merge([
      sizes: [3, 5, 8, 10, 15],
      iterations: 20
    ], opts)
    
    analysis = run_scaling_benchmark(vision_pro_opts)
    
    # Generate both reports
    Logger.debug("\n" <> String.duplicate("=", 60))
    format_benchmark_report(analysis)
    Logger.debug("\n" <> String.duplicate("=", 60))
    format_vision_pro_report(analysis)
    
    analysis
  end

  def run_segmentation_comparison_benchmark(opts \\ []) do
    Logger.info("Running segmentation comparison benchmark")
    
    sizes = Keyword.get(opts, :sizes, [8, 12, 16, 20, 25])
    iterations = Keyword.get(opts, :iterations, 10)
    
    Logger.info("Comparing 5-point segmentation vs direct PC2 for sizes: #{inspect(sizes)}")
    
    results = Enum.map(sizes, fn size ->
      Logger.info("Benchmarking size #{size}")
      
      # Generate test STN
      stn = generate_test_stn(size)
      
      # Test segmented approach (current implementation)
      segmented_times = Enum.map(1..iterations, fn _i ->
        start_time = System.monotonic_time()
        Timeline.Internal.STN.Operations.parallel_solve(stn, 4)
        end_time = System.monotonic_time()
        (end_time - start_time) / 1_000_000
      end)
      
      # Test direct PC2 approach (without segmentation)
      direct_times = Enum.map(1..iterations, fn _i ->
        start_time = System.monotonic_time()
        PC2.apply_pc2(stn)
        end_time = System.monotonic_time()
        (end_time - start_time) / 1_000_000
      end)
      
      %{
        size: size,
        segmented: collect_timing_data_simple(segmented_times),
        direct: collect_timing_data_simple(direct_times),
        improvement: calculate_improvement(segmented_times, direct_times)
      }
    end)
    
    format_segmentation_comparison_report(results)
    results
  end
  
  defp collect_timing_data_simple(times) do
    if length(times) == 0 do
      %{avg: 0, min: 0, max: 0, p95: 0}
    else
      avg = Enum.sum(times) / length(times)
      min = Enum.min(times)
      max = Enum.max(times)
      
      sorted_times = Enum.sort(times)
      p95_index = round((length(times) - 1) * 0.95)
      p95 = Enum.at(sorted_times, p95_index)
      
      %{avg: avg, min: min, max: max, p95: p95}
    end
  end
  
  defp calculate_improvement(segmented_times, direct_times) do
    segmented_avg = Enum.sum(segmented_times) / length(segmented_times)
    direct_avg = Enum.sum(direct_times) / length(direct_times)
    
    if direct_avg > 0 do
      improvement_percent = ((direct_avg - segmented_avg) / direct_avg) * 100
      speedup_ratio = direct_avg / segmented_avg
      
      %{
        percent: improvement_percent,
        speedup: speedup_ratio,
        segmented_faster: segmented_avg < direct_avg
      }
    else
      %{percent: 0, speedup: 1.0, segmented_faster: false}
    end
  end
  
  defp format_segmentation_comparison_report(results) do
    Logger.info("Formatting segmentation comparison report")
    
    header = """
    
    Segmentation vs Direct PC2 Performance Comparison
    ================================================
    Testing 5-point segmentation optimization against direct PC2 solving
    
    """
    
    table_header = """
    Size | Segmented Avg(ms) | Direct Avg(ms) | Improvement | Speedup | Status
    -----|-------------------|----------------|-------------|---------|--------
    """
    
    table_rows = Enum.map_join(results, "\n", fn result ->
      size = result.size
      seg_avg = Float.round(result.segmented.avg, 3)
      dir_avg = Float.round(result.direct.avg, 3)
      improvement = Float.round(result.improvement.percent, 1)
      speedup = Float.round(result.improvement.speedup, 2)
      
      status = if result.improvement.segmented_faster, do: " ✅ Faster", else: " ❌ Slower"
      
      "#{size} | #{seg_avg} | #{dir_avg} | #{improvement}% | #{speedup}x | #{status}"
    end)
    
    summary = generate_segmentation_summary(results)
    
    report = header <> table_header <> table_rows <> "\n\n" <> summary
    
    Logger.debug(report)
    report
  end
  
  defp generate_segmentation_summary(results) do
    faster_count = Enum.count(results, fn r -> r.improvement.segmented_faster end)
    total_count = length(results)
    
    avg_improvement = results
    |> Enum.filter(fn r -> r.improvement.segmented_faster end)
    |> Enum.map(fn r -> r.improvement.percent end)
    |> case do
      [] -> 0.0
      improvements -> Enum.sum(improvements) / length(improvements)
    end
    
    best_improvement = results
    |> Enum.map(fn r -> r.improvement.percent end)
    |> Enum.max()
    |> case do
      val when is_number(val) -> val * 1.0  # Convert to float
      _ -> 0.0
    end
    
    """
    Segmentation Performance Summary:
    ================================
    
    Segmentation wins: #{faster_count}/#{total_count} test cases
    Average improvement when faster: #{Float.round(avg_improvement, 1)}%
    Best improvement: #{Float.round(best_improvement, 1)}%
    
    Analysis: #{if faster_count > total_count/2, do: "5-point segmentation shows performance benefits", else: "Direct PC2 performs better for these sizes"}
    
    Apple Vision Pro Impact:
    • Segmentation helps maintain <1ms execution for larger networks
    • Benefits compound with parallel processing on multi-core devices
    • Recommended for STNs with >5 time points on resource-constrained hardware
    """
  end
end
