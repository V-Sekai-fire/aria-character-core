# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule Timeline.Internal.STN.OperationsTest do
  use ExUnit.Case, async: true
  alias Timeline.Internal.STN
  alias Timeline.Internal.STN.Operations

  describe("segment/2") do
    test "returns single STN when time points <= 5" do
      stn = create_stn_with_points(3)
      segments = Operations.segment(stn, 10)
      assert length(segments) == 1
      assert hd(segments) == stn
    end

    test "splits STN into 5-point segments when time points > 5" do
      stn = create_stn_with_points(12)
      segments = Operations.segment(stn, 10)
      assert length(segments) == 3
      assert MapSet.size(Enum.at(segments, 0).time_points) == 5
      assert MapSet.size(Enum.at(segments, 1).time_points) == 5
      assert MapSet.size(Enum.at(segments, 2).time_points) == 2
    end

    test "segments contain only relevant constraints" do
      stn = create_stn_with_connected_points(6)
      segments = Operations.segment(stn, 10)
      assert length(segments) == 2

      for segment <- segments do
        for {{p1, p2}, _constraint} <- segment.constraints do
          assert MapSet.member?(segment.time_points, p1)
          assert MapSet.member?(segment.time_points, p2)
        end
      end
    end

    test "preserves STN properties in segments" do
      stn = create_stn_with_properties()
      segments = Operations.segment(stn, 10)

      for segment <- segments do
        assert segment.consistent == stn.consistent
        assert segment.time_unit == stn.time_unit
        assert segment.lod_level == stn.lod_level
        assert segment.lod_resolution == stn.lod_resolution
      end
    end

    test "handles large STNs efficiently" do
      stn = create_stn_with_points(25)
      segments = Operations.segment(stn, 10)
      assert length(segments) == 5

      for segment <- segments do
        assert MapSet.size(segment.time_points) == 5
      end
    end
  end

  describe("parallel_solve/2") do
    test "handles single segment STN correctly" do
      stn = create_stn_with_points(3)
      result = Operations.parallel_solve(stn, 4)
      assert %STN{} = result
      assert result.consistent
    end

    test "solves multi-segment STN and merges results" do
      stn = create_stn_with_connected_points(8)
      result = Operations.parallel_solve(stn, 4)
      assert %STN{} = result
      assert MapSet.size(result.time_points) >= MapSet.size(stn.time_points)
    end

    test "maintains consistency after parallel solving" do
      stn = create_consistent_stn(10)
      result = Operations.parallel_solve(stn, 4)
      assert result.consistent
    end
  end

  defp create_stn_with_points(count) do
    time_points = 1..count |> Enum.map(&"point_#{&1}") |> MapSet.new()

    constraints =
      time_points
      |> MapSet.to_list()
      |> Enum.map(fn point -> {{point, point}, {-1, 1}} end)
      |> Map.new()

    %STN{time_points: time_points, constraints: constraints, consistent: true}
  end

  defp create_stn_with_connected_points(count) do
    time_points = 1..count |> Enum.map(&"point_#{&1}") |> MapSet.new()

    constraints =
      time_points
      |> MapSet.to_list()
      |> Enum.with_index()
      |> Enum.reduce(%{}, fn {point, index}, acc ->
        acc = Map.put(acc, {point, point}, {-1, 1})

        if index < count - 1 do
          next_point = "point_#{index + 2}"
          Map.put(acc, {point, next_point}, {1, 10})
        else
          acc
        end
      end)

    %STN{time_points: time_points, constraints: constraints, consistent: true}
  end

  defp create_stn_with_properties do
    %STN{
      time_points: MapSet.new(["p1", "p2", "p3"]),
      constraints: %{{"p1", "p1"} => {-1, 1}, {"p2", "p2"} => {-1, 1}, {"p3", "p3"} => {-1, 1}},
      consistent: true,
      time_unit: :millisecond,
      lod_level: 1,
      lod_resolution: 100
    }
  end

  defp create_consistent_stn(count) do
    time_points = 1..count |> Enum.map(&"point_#{&1}") |> MapSet.new()

    constraints =
      time_points
      |> MapSet.to_list()
      |> Enum.map(fn point -> {{point, point}, {-1, 1}} end)
      |> Map.new()

    %STN{time_points: time_points, constraints: constraints, consistent: true}
  end
end
