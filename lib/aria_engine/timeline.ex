# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule Timeline do
  @moduledoc "Timeline module with interval-based storage using Path Consistency (PC-2) algorithm\nfor Simple Temporal Network (STN) solving.\n\nAccepts time input in seconds but solves at 1ms tick precision.\nSupports Allen's interval algebra with usability improvements.\nRespects agent vs entity distinction in temporal constraints.\n\n## Time Representation\n- External API: seconds (float/integer)\n- Internal storage/solving: milliseconds (integer)\n- Precision: 1ms ticks as per ADR-006\n\n## Features\n- All 13 Allen interval relations\n- Path Consistency (PC-2) STN solving\n- Agent/entity distinction\n- Fluent API for constraint building\n- Comprehensive edge case handling\n\n## Examples\n\n    iex> timeline = Timeline.new()\n    iex> alias Timeline.Interval\n    iex> start_time = DateTime.from_naive!(~N[2025-01-01 10:00:00], \"Etc/UTC\")\n    iex> end_time = DateTime.from_naive!(~N[2025-01-01 12:00:00], \"Etc/UTC\")\n    iex> interval = Interval.new(start_time, end_time)\n    iex> timeline = Timeline.add_interval(timeline, interval)\n    iex> length(Map.keys(timeline.intervals))\n    1\n\n## References\n\n- ADR-078: Timeline Module PC-2 STN Implementation\n- ADR-079: Timeline Module Implementation Progress\n- ADR-045: Allen's Interval Algebra Temporal Relationships\n- ADR-040: Temporal Constraint Solver Selection\n- ADR-046: Interval Notation Usability\n- ADR-006: Game Engine Real-time Execution (1ms tick requirement)\n"
  alias Timeline.Interval
  alias Timeline.Internal.STN
  @type t :: %__MODULE__{intervals: %{Interval.id() => Interval.t()}, stn: STN.t()}
  defstruct intervals: %{}, stn: STN.new(), metadata: %{}
  @spec new(keyword()) :: t()
  def new(opts \\ []) do
    intervals = Keyword.get(opts, :intervals, [])
    metadata = Keyword.get(opts, :metadata, %{})
    %__MODULE__{metadata: metadata} |> add_intervals(intervals)
  end

  @spec add_interval(t(), Interval.t()) :: t()
  def add_interval(%__MODULE__{} = timeline, interval) do
    stn = timeline.stn |> STN.add_interval(interval)

    timeline
    |> Map.put(:intervals, Map.put(timeline.intervals, interval.id, interval))
    |> Map.put(:stn, stn)
  end

  @spec add_intervals(t(), list(Interval.t())) :: t()
  def add_intervals(%__MODULE__{} = timeline, intervals) do
    Enum.reduce(intervals, timeline, &add_interval/2)
  end

  @spec get_interval(t(), Interval.id()) :: Interval.t() | nil
  def get_interval(%__MODULE__{intervals: intervals}, id) do
    intervals[id]
  end

  @spec update_interval(t(), Interval.t()) :: t()
  def update_interval(%__MODULE__{} = timeline, interval) do
    stn = STN.update_interval(timeline.stn, interval)

    timeline
    |> Map.put(:intervals, Map.put(timeline.intervals, interval.id, interval))
    |> Map.put(:stn, stn)
  end

  @spec remove_interval(t(), Interval.id()) :: t()
  def remove_interval(%__MODULE__{} = timeline, id) do
    stn = STN.remove_interval(timeline.stn, id)
    timeline |> Map.put(:intervals, Map.delete(timeline.intervals, id)) |> Map.put(:stn, stn)
  end

  @spec add_constraint(t(), String.t(), String.t(), {number(), number()}) :: t()
  def add_constraint(timeline, from_point, to_point, constraint) do
    stn = STN.add_constraint(timeline.stn, from_point, to_point, constraint)
    %{timeline | stn: stn}
  end

  @spec solve(t()) :: t()
  def solve(timeline) do
    require Logger
    stn = STN.solve(timeline.stn)
    updated_timeline = %{timeline | stn: stn}

    case Map.get(stn.metadata, :solved_times) do
      nil ->
        updated_timeline

      solved_times ->
        result = apply_solved_times_to_intervals(updated_timeline, solved_times)
        result
    end
  end

  @doc "Creates a new Timeline with STN configuration options.\n\nThis function provides access to STN configuration while maintaining\nTimeline as the primary interface.\n"
  @spec new_with_stn_opts(keyword()) :: t()
  def new_with_stn_opts(stn_opts) do
    stn = STN.new(stn_opts)
    %__MODULE__{intervals: %{}, stn: stn, metadata: %{}}
  end

  @doc "Creates a new Timeline with constant work pattern enabled.\n"
  @spec new_constant_work(keyword()) :: t()
  def new_constant_work(opts \\ []) do
    stn = STN.new_constant_work(opts)
    %__MODULE__{intervals: %{}, stn: stn, metadata: %{}}
  end

  @doc "Checks if the Timeline's temporal constraints are consistent.\n"
  @spec consistent?(t()) :: boolean()
  def consistent?(timeline) do
    STN.consistent?(timeline.stn)
  end

  @doc "Gets all time points in the Timeline's STN.\n"
  @spec time_points(t()) :: [String.t()]
  def time_points(timeline) do
    STN.time_points(timeline.stn)
  end

  @doc "Adds a time point to the Timeline's STN.\n"
  @spec add_time_point(t(), String.t()) :: t()
  def add_time_point(timeline, time_point) do
    stn = STN.add_time_point(timeline.stn, time_point)
    %{timeline | stn: stn}
  end

  @doc "Gets a constraint between two time points.\n"
  @spec get_constraint(t(), String.t(), String.t()) :: {number(), number()} | nil
  def get_constraint(timeline, from_point, to_point) do
    STN.get_constraint(timeline.stn, from_point, to_point)
  end

  @doc "Applies Path Consistency (PC-2) algorithm to the Timeline using MiniZinc solver.\n"
  @spec apply_pc2(t()) :: t()
  def apply_pc2(timeline) do
    alias Timeline.Internal.STN.MiniZincSolver
    solved_stn = MiniZincSolver.solve_stn(timeline.stn)
    %{timeline | stn: solved_stn}
  end

  @doc "Computes the intersection of two Timelines.\n\nReturns a Timeline with constraints that satisfy both input Timelines.\n"
  @spec intersection(t(), t()) :: t()
  def intersection(timeline1, timeline2) do
    intersected_stn = STN.intersection(timeline1.stn, timeline2.stn)
    merged_intervals = Map.merge(timeline1.intervals, timeline2.intervals)
    merged_metadata = Map.merge(timeline1.metadata, timeline2.metadata)
    %__MODULE__{intervals: merged_intervals, stn: intersected_stn, metadata: merged_metadata}
  end

  @doc "Computes the union of two Timelines.\n\nReturns a Timeline with constraints that allow either input Timeline to be satisfied.\n"
  @spec union(t(), t()) :: t()
  def union(timeline1, timeline2) do
    union_stn = STN.union(timeline1.stn, timeline2.stn)
    merged_intervals = Map.merge(timeline1.intervals, timeline2.intervals)
    merged_metadata = Map.merge(timeline1.metadata, timeline2.metadata)
    %__MODULE__{intervals: merged_intervals, stn: union_stn, metadata: merged_metadata}
  end

  @doc "Chains multiple Timelines sequentially.\n\nReturns a Timeline where the Timelines are executed in sequence.\n"
  @spec chain([t()]) :: t()
  def chain([]) do
    new()
  end

  def chain([single_timeline]) do
    single_timeline
  end

  def chain(timelines) when is_list(timelines) do
    stns = Enum.map(timelines, & &1.stn)
    chained_stn = STN.chain(stns)
    merged_intervals = timelines |> Enum.map(& &1.intervals) |> Enum.reduce(%{}, &Map.merge/2)
    merged_metadata = timelines |> Enum.map(& &1.metadata) |> Enum.reduce(%{}, &Map.merge/2)
    %__MODULE__{intervals: merged_intervals, stn: chained_stn, metadata: merged_metadata}
  end

  @doc "Joins multiple Timelines in parallel.\n\nReturns a Timeline where the Timelines can be executed concurrently.\n"
  @spec parallel_join([t()]) :: t()
  def parallel_join([]) do
    new()
  end

  def parallel_join([single_timeline]) do
    single_timeline
  end

  def parallel_join(timelines) when is_list(timelines) do
    stns = Enum.map(timelines, & &1.stn)
    parallel_stn = STN.parallel_join(stns)
    merged_intervals = timelines |> Enum.map(& &1.intervals) |> Enum.reduce(%{}, &Map.merge/2)
    merged_metadata = timelines |> Enum.map(& &1.metadata) |> Enum.reduce(%{}, &Map.merge/2)
    %__MODULE__{intervals: merged_intervals, stn: parallel_stn, metadata: merged_metadata}
  end

  @doc "Composes two Timelines.\n\nReturns a Timeline representing the composition of the two input Timelines.\n"
  @spec compose(t(), t()) :: t()
  def compose(timeline1, timeline2) do
    composed_stn = STN.compose(timeline1.stn, timeline2.stn)
    merged_intervals = Map.merge(timeline1.intervals, timeline2.intervals)
    merged_metadata = Map.merge(timeline1.metadata, timeline2.metadata)
    %__MODULE__{intervals: merged_intervals, stn: composed_stn, metadata: merged_metadata}
  end

  @doc "Segments a Timeline for parallel processing.\n"
  @spec segment(t(), pos_integer()) :: t()
  def segment(timeline, max_segments) do
    segmented_stn = STN.segment(timeline.stn, max_segments)
    %{timeline | stn: segmented_stn}
  end

  @doc "Solves a Timeline using parallel processing.\n"
  @spec parallel_solve(t(), pos_integer()) :: t()
  def parallel_solve(timeline, max_segments) do
    solved_stn = STN.parallel_solve(timeline.stn, max_segments)
    %{timeline | stn: solved_stn}
  end

  @doc "Gets the underlying STN for compatibility during migration.\n\nThis function should only be used during the migration period and will be\nremoved once all external modules use the Timeline API.\n"
  @spec get_stn(t()) :: STN.t()
  def get_stn(timeline) do
    timeline.stn
  end

  @doc "Creates a Timeline from an existing STN.\n\nThis function should only be used during the migration period and will be\nremoved once all external modules use the Timeline API.\n"
  @spec from_stn(STN.t()) :: t()
  def from_stn(stn) do
    %__MODULE__{intervals: %{}, stn: stn, metadata: %{}}
  end

  defp apply_solved_times_to_intervals(timeline, solved_times) do
    base_time = get_base_time(timeline)
    lod_resolution = Map.get(timeline.stn, :lod_resolution, 100)

    updated_intervals =
      timeline.intervals
      |> Enum.map(fn {interval_id, interval} ->
        start_point = "#{interval_id}_start"
        end_point = "#{interval_id}_end"

        case {Map.get(solved_times, start_point), Map.get(solved_times, end_point)} do
          {start_offset, end_offset} when not is_nil(start_offset) and not is_nil(end_offset) ->
            start_seconds = start_offset / lod_resolution
            end_seconds = end_offset / lod_resolution
            new_start_time = DateTime.add(base_time, round(start_seconds * 1000), :millisecond)
            new_end_time = DateTime.add(base_time, round(end_seconds * 1000), :millisecond)
            updated_interval = %{interval | start_time: new_start_time, end_time: new_end_time}
            {interval_id, updated_interval}

          _ ->
            {interval_id, interval}
        end
      end)
      |> Map.new()

    %{timeline | intervals: updated_intervals}
  end

  defp get_base_time(timeline) do
    case timeline.intervals |> Map.values() |> List.first() do
      nil ->
        DateTime.from_naive!(~N[2025-01-01 00:00:00], "Etc/UTC")

      first_interval ->
        start_time = first_interval.start_time
        %{start_time | second: 0, microsecond: {0, 0}}
    end
  end
end