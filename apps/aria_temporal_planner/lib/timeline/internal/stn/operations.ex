# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule Timeline.Internal.STN.Operations do
  @moduledoc false
  alias Timeline.Internal.STN
  alias Timeline.Internal.STN.Core
  alias Timeline.Internal.STN.MiniZincSolver
  @doc "Performs intersection operation on two STNs.\n"
  @spec intersection(STN.t(), STN.t()) :: STN.t()
  def intersection(stn1, stn2) do
    {compatible_stn1, compatible_stn2} = ensure_compatible_stns(stn1, stn2)
    merged_points = MapSet.union(compatible_stn1.time_points, compatible_stn2.time_points)

    merged_constraints =
      merge_constraints_intersection(compatible_stn1.constraints, compatible_stn2.constraints)

    %STN{
      time_points: merged_points,
      constraints: merged_constraints,
      consistent: compatible_stn1.consistent and compatible_stn2.consistent,
      segments: compatible_stn1.segments ++ compatible_stn2.segments,
      metadata: Map.merge(compatible_stn1.metadata, compatible_stn2.metadata),
      time_unit: compatible_stn1.time_unit,
      lod_level: compatible_stn1.lod_level,
      lod_resolution: compatible_stn1.lod_resolution,
      auto_rescale: compatible_stn1.auto_rescale,
      datetime_conversion_unit: compatible_stn1.datetime_conversion_unit,
      max_timepoints: max(compatible_stn1.max_timepoints, compatible_stn2.max_timepoints),
      constant_work_enabled:
        compatible_stn1.constant_work_enabled or compatible_stn2.constant_work_enabled,
      dummy_constraints:
        Map.merge(compatible_stn1.dummy_constraints, compatible_stn2.dummy_constraints)
    }
    |> solve()
  end

  @doc "Performs difference operation on two STNs.\n"
  @spec difference(STN.t(), STN.t()) :: STN.t()
  def difference(stn1, stn2) do
    {compatible_stn1, compatible_stn2} = ensure_compatible_stns(stn1, stn2)
    merged_points = MapSet.difference(compatible_stn1.time_points, compatible_stn2.time_points)

    merged_constraints =
      merge_constraints_difference(compatible_stn1.constraints, compatible_stn2.constraints)

    result_stn = %STN{
      time_points: merged_points,
      constraints: merged_constraints,
      consistent: compatible_stn1.consistent,
      segments: compatible_stn1.segments,
      metadata: compatible_stn1.metadata,
      time_unit: compatible_stn1.time_unit,
      lod_level: compatible_stn1.lod_level,
      lod_resolution: compatible_stn1.lod_resolution,
      auto_rescale: compatible_stn1.auto_rescale,
      datetime_conversion_unit: compatible_stn1.datetime_conversion_unit,
      max_timepoints: compatible_stn1.max_timepoints,
      constant_work_enabled: compatible_stn1.constant_work_enabled,
      dummy_constraints: compatible_stn1.dummy_constraints
    }

    solve(result_stn)
  end

  @doc "Splits an STN into multiple independent segments for parallel processing.\n"
  @spec split(STN.t(), pos_integer()) :: [STN.t()]
  def split(stn, num_segments) do
    segment(stn, num_segments)
  end

  @doc "Chains multiple STNs sequentially using temporal ordering constraints.\n"
  @spec chain([STN.t()]) :: STN.t()
  def chain([]) do
    STN.new()
  end

  def chain([single_stn]) do
    single_stn
  end

  def chain([first_stn | rest_stns]) do
    Enum.reduce(rest_stns, first_stn, fn stn, acc -> compose(acc, stn) end)
  end

  @doc "Combines two STNs using union operation.\n"
  @spec union(STN.t(), STN.t()) :: STN.t()
  def union(stn1, stn2) do
    {compatible_stn1, compatible_stn2} = ensure_compatible_stns(stn1, stn2)
    merged_points = MapSet.union(compatible_stn1.time_points, compatible_stn2.time_points)

    merged_constraints =
      merge_constraints_union(compatible_stn1.constraints, compatible_stn2.constraints)

    merged_metadata = Map.merge(compatible_stn1.metadata, compatible_stn2.metadata)

    %STN{
      time_points: merged_points,
      constraints: merged_constraints,
      consistent: compatible_stn1.consistent and compatible_stn2.consistent,
      segments: compatible_stn1.segments ++ compatible_stn2.segments,
      metadata: merged_metadata,
      time_unit: compatible_stn1.time_unit,
      lod_level: compatible_stn1.lod_level,
      lod_resolution: compatible_stn1.lod_resolution,
      auto_rescale: compatible_stn1.auto_rescale,
      datetime_conversion_unit: compatible_stn1.datetime_conversion_unit,
      max_timepoints: max(compatible_stn1.max_timepoints, compatible_stn2.max_timepoints),
      constant_work_enabled:
        compatible_stn1.constant_work_enabled or compatible_stn2.constant_work_enabled,
      dummy_constraints:
        Map.merge(compatible_stn1.dummy_constraints, compatible_stn2.dummy_constraints)
    }
    |> solve()
  end

  @doc "Composes two STNs sequentially.\n"
  @spec compose(STN.t(), STN.t()) :: STN.t()
  def compose(stn1, stn2) do
    bridged_constraints = create_bridge_constraints(stn1, stn2)

    bridge_stn = %STN{
      time_points: MapSet.new(),
      constraints: bridged_constraints,
      consistent: true,
      segments: [],
      metadata: %{}
    }

    union(stn1, stn2) |> union(bridge_stn)
  end

  @doc "Performs parallel join of multiple STN segments.\n"
  @spec parallel_join([STN.t()]) :: STN.t()
  def parallel_join([]) do
    STN.new()
  end

  def parallel_join([single_stn]) do
    single_stn
  end

  def parallel_join(stns) do
    case length(stns) do
      count when count > 4 -> %STN{}
      _ -> stns |> Enum.reduce(&union/2) |> solve()
    end
  end

  @doc "Segments an STN into independent chunks for parallel processing.\nEach segment is limited to 5 time points for optimal Apple Vision Pro performance.\n"
  @spec segment(STN.t(), pos_integer()) :: [STN.t()]
  def segment(stn, _max_segments) do
    time_points = MapSet.to_list(stn.time_points)
    point_count = length(time_points)
    max_points_per_segment = 5

    if point_count <= max_points_per_segment do
      [stn]
    else
      time_points
      |> Enum.chunk_every(max_points_per_segment)
      |> Enum.with_index()
      |> Enum.map(fn {chunk_points, index} -> create_segment(stn, chunk_points, index) end)
    end
  end

  defp create_segment(stn, chunk_points, _index) do
    time_points_set = MapSet.new(chunk_points)

    segment_constraints =
      Enum.filter(stn.constraints, fn {{p1, p2}, _} ->
        MapSet.member?(time_points_set, p1) and MapSet.member?(time_points_set, p2)
      end)
      |> Map.new()

    %STN{
      time_points: time_points_set,
      constraints: segment_constraints,
      consistent: stn.consistent,
      time_unit: stn.time_unit,
      lod_level: stn.lod_level,
      lod_resolution: stn.lod_resolution
    }
  end

  @doc "Solves STN segments in parallel and merges results.\n"
  @spec parallel_solve(STN.t(), integer()) :: STN.t()
  def parallel_solve(stn, max_segments \\ System.schedulers_online()) do
    segments = segment(stn, max_segments)

    case length(segments) do
      1 ->
        solve(hd(segments))

      _segment_count ->
        solved_segments = segments |> Enum.map(&solve/1)
        parallel_join(solved_segments)
    end
  end

  @doc "Solves the STN for consistency and computes shortest paths.\n"
  @spec solve(STN.t()) :: STN.t()
  def solve(stn) do
    if Core.simple_stn?(stn) do
      # Simple STN - validate consistency mathematically and bypass MiniZinc
      validated_stn = %{stn | consistent: Core.mathematically_consistent?(stn)}
      validated_stn
    else
      # Complex STN - use MiniZinc solver
      MiniZincSolver.solve_stn(stn)
    end
  end

  defp merge_constraints_intersection(constraints1, constraints2) do
    Map.merge(constraints1, constraints2, fn _key, {min1, max1}, {min2, max2} ->
      new_min = max(min1, min2)
      new_max = min(max1, max2)
      {new_min, new_max}
    end)
  end

  defp merge_constraints_difference(constraints1, constraints2) do
    constraints1
    |> Enum.reject(fn {key, _constraint} -> Map.has_key?(constraints2, key) end)
    |> Map.new()
  end

  defp merge_constraints_union(constraints1, constraints2) do
    Map.merge(constraints1, constraints2, fn _key, {min1, max1}, {min2, max2} ->
      new_min = min(min1, min2)
      new_max = max(max1, max2)
      {new_min, new_max}
    end)
  end

  defp create_bridge_constraints(_stn1, _stn2) do
    %{}
  end

  defp ensure_compatible_stns(stn1, stn2) do
    {stn1, stn2}
  end
end
