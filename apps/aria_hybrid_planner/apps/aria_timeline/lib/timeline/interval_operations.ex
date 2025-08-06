# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule Timeline.IntervalOperations do
  @moduledoc "Core Timeline operations including interval management, STN solving, and composition operations.\n\nThis module contains the fundamental Timeline functionality:\n- Basic CRUD operations for intervals\n- STN solving and encapsulation\n- Timeline composition operations (intersection, union, chain, parallel)\n- Core utility functions\n\n## Time Representation\n- External API: seconds (float/integer)\n- Internal storage/solving: milliseconds (integer)\n- Precision: 1ms ticks as per ADR-006\n"
  alias Timeline.Interval
  alias Timeline.Internal.STN

  @type timeline :: %{
          intervals: %{Interval.id() => Interval.t()},
          bridges: %{String.t() => any()},
          stn: STN.t(),
          metadata: map()
        }
  @spec new(keyword()) :: timeline()
  def new(opts \\ []) do
    intervals = Keyword.get(opts, :intervals, [])
    metadata = Keyword.get(opts, :metadata, %{})
    timeline = %{intervals: %{}, bridges: %{}, stn: STN.new(), metadata: metadata}
    add_intervals(timeline, intervals)
  end

  @spec add_interval(timeline(), Interval.t()) :: timeline()
  def add_interval(timeline, interval) do
    stn = timeline.stn |> STN.add_interval(interval)

    timeline
    |> Map.put(:intervals, Map.put(timeline.intervals, interval.id, interval))
    |> Map.put(:stn, stn)
  end

  @spec add_intervals(timeline(), list(Interval.t())) :: timeline()
  def add_intervals(timeline, intervals) do
    Enum.reduce(intervals, timeline, &add_interval(&2, &1))
  end

  @spec get_interval(timeline(), Interval.id()) :: Interval.t() | nil
  def get_interval(timeline, id) do
    timeline.intervals[id]
  end

  @spec update_interval(timeline(), Interval.t()) :: timeline()
  def update_interval(timeline, interval) do
    stn = STN.update_interval(timeline.stn, interval)

    timeline
    |> Map.put(:intervals, Map.put(timeline.intervals, interval.id, interval))
    |> Map.put(:stn, stn)
  end

  @spec remove_interval(timeline(), Interval.id()) :: timeline()
  def remove_interval(timeline, id) do
    stn = STN.remove_interval(timeline.stn, id)
    timeline |> Map.put(:intervals, Map.delete(timeline.intervals, id)) |> Map.put(:stn, stn)
  end

  @spec add_constraint(timeline(), String.t(), String.t(), {number(), number()}) :: timeline()
  def add_constraint(timeline, from_point, to_point, constraint) do
    stn = STN.add_constraint(timeline.stn, from_point, to_point, constraint)
    %{timeline | stn: stn}
  end

  @spec solve(timeline()) :: timeline()
  def solve(timeline) do
    require Logger
    stn = STN.solve_stn(timeline.stn)
    updated_timeline = %{timeline | stn: stn}

    case Map.get(stn.metadata, :solved_times) do
      nil -> updated_timeline
      solved_times -> apply_solved_times_to_intervals(updated_timeline, solved_times)
    end
  end

  @doc "Creates a new Timeline with STN configuration options.\n\nThis function provides access to STN configuration while maintaining\nTimeline as the primary interface.\n"
  @spec new_with_stn_opts(keyword()) :: timeline()
  def new_with_stn_opts(stn_opts) do
    stn = STN.new(stn_opts)
    %{intervals: %{}, bridges: %{}, stn: stn, metadata: %{}}
  end

  @doc "Creates a new Timeline with constant work pattern enabled.\n"
  @spec new_constant_work(keyword()) :: timeline()
  def new_constant_work(opts \\ []) do
    stn = STN.new_constant_work(opts)
    %{intervals: %{}, bridges: %{}, stn: stn, metadata: %{}}
  end

  @doc "Checks if the Timeline's temporal constraints are consistent.\n"
  @spec consistent?(timeline()) :: boolean()
  def consistent?(timeline) do
    STN.consistent?(timeline.stn)
  end

  @doc "Gets all time points in the Timeline's STN.\n"
  @spec time_points(timeline()) :: [String.t()]
  def time_points(timeline) do
    STN.time_points(timeline.stn)
  end

  @doc "Adds a time point to the Timeline's STN.\n"
  @spec add_time_point(timeline(), String.t()) :: timeline()
  def add_time_point(timeline, time_point) do
    stn = STN.add_time_point(timeline.stn, time_point)
    %{timeline | stn: stn}
  end

  @doc "Gets a constraint between two time points.\n"
  @spec get_constraint(timeline(), String.t(), String.t()) :: {number(), number()} | nil
  def get_constraint(timeline, from_point, to_point) do
    STN.get_constraint(timeline.stn, from_point, to_point)
  end

  @doc "TOMBSTONE: PC-2 algorithm was removed in favor of MiniZinc-based STN solving.\n\nThe Path Consistency (PC-2) algorithm implementation was removed as part of\nthe temporal planning segment closure. Use Timeline.solve/1 instead, which\nuses the MiniZinc solver for STN constraint solving.\n\nRemoved: January 2025\nReplacement: Timeline.solve/1\n"
  @spec apply_pc2(timeline()) :: timeline()
  def apply_pc2(timeline) do
    require Logger
    Logger.warning("TOMBSTONE: apply_pc2/1 is deprecated. Use Timeline.solve/1 instead.")
    solve(timeline)
  end

  @doc "Chains multiple Timelines sequentially.\n\nReturns a Timeline where the Timelines are executed in sequence.\n"
  @spec chain([timeline()]) :: timeline()
  def chain([]) do
    new()
  end

  def chain([single_timeline]) do
    single_timeline
  end

  @doc "Gets the underlying STN for compatibility during migration.\n\nThis function should only be used during the migration period and will be\nremoved once all external modules use the Timeline API.\n"
  @spec get_stn(timeline()) :: STN.t()
  def get_stn(timeline) do
    timeline.stn
  end

  @doc "Creates a Timeline from an existing STN.\n\nThis function should only be used during the migration period and will be\nremoved once all external modules use the Timeline API.\n"
  @spec from_stn(STN.t()) :: timeline()
  def from_stn(stn) do
    %{intervals: %{}, bridges: %{}, stn: stn, metadata: %{}}
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
        "2025-01-01T00:00:00Z"

      first_interval ->
        start_time = first_interval.start_time
        %{start_time | second: 0, microsecond: {0, 0}}
    end
  end
end
