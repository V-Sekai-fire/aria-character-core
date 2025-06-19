defmodule AriaEngine.PC2BenchmarkTest do
  use ExUnit.Case
  doctest AriaEngine.PC2Benchmark

  test "generate_test_stn/1 generates a valid STN" do
    size = 10
    stn = AriaEngine.PC2Benchmark.generate_test_stn(size)
    assert MapSet.size(stn.time_points) == size
    assert map_size(stn.constraints) > 0
  end

  test "run_pc2_solve/1 runs PC2 solve and returns timing" do
    size = 10
    stn = AriaEngine.PC2Benchmark.generate_test_stn(size)
    result = AriaEngine.PC2Benchmark.run_pc2_solve(stn)
    assert is_boolean(result.result)
    assert is_number(result.time)
  end

  test "collect_timing_data/1 collects timing statistics" do
    results = [
      %{time: 10},
      %{time: 20},
      %{time: 30},
      %{time: 40},
      %{time: 50}
    ]
    stats = AriaEngine.PC2Benchmark.collect_timing_data(results)
    assert is_map(stats)
    assert stats.avg == 30
    assert stats.min == 10
    assert stats.max == 50
    assert stats.p95 == 50
  end
end
