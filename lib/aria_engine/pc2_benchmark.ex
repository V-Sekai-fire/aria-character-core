defmodule AriaEngine.PC2Benchmark do
  @moduledoc """
  Performance benchmarking for PC2 algorithm.
  """

  require Logger
  alias Timeline.Internal.STN
  alias Timeline.Internal.STN.PC2

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
      %{avg: 0, min: 0, max: 0, p95: 0}
    else
      avg = Enum.sum(times) / length(times)
      min = Enum.min(times)
      max = Enum.max(times)

      sorted_times = Enum.sort(times)
      p95_index = round((length(times) - 1) * 0.95)
      p95 = Enum.at(sorted_times, p95_index)

      %{
        avg: avg,
        min: min,
        max: max,
        p95: p95
      }
    end
  end
end
