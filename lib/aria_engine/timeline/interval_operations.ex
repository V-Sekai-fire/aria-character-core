# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngine.Timeline.IntervalOperations do
  @moduledoc """
  Core Timeline operations including interval management, STN solving, and composition operations.

  This module contains the fundamental Timeline functionality:
  - Basic CRUD operations for intervals
  - STN solving and encapsulation
  - Timeline composition operations (intersection, union, chain, parallel)
  - Core utility functions

  ## Time Representation
  - External API: seconds (float/integer)
  - Internal storage/solving: milliseconds (integer)
  - Precision: 1ms ticks as per ADR-006
  """

  alias AriaEngine.Timeline.Interval
  alias AriaEngine.Timeline.Internal.STN

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

    timeline = %{
      intervals: %{},
      bridges: %{},
      stn: STN.new(),
      metadata: metadata
    }

    add_intervals(timeline, intervals)
  end

  @spec add_interval(timeline(), Interval.t()) :: timeline()
  def add_interval(timeline, interval) do
    stn =
      timeline.stn
      |> STN.add_interval(interval)

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

    timeline
    |> Map.put(:intervals, Map.delete(timeline.intervals, id))
    |> Map.put(:stn, stn)
  end

  @spec add_constraint(timeline(), String.t(), String.t(), {number(), number()}) :: timeline()
  def add_constraint(timeline, from_point, to_point, constraint) do
    stn = STN.add_constraint(timeline.stn, from_point, to_point, constraint)
    %{timeline | stn: stn}
  end

  @spec solve(timeline()) :: timeline()
  def solve(timeline) do
    require Logger
    stn = STN.solve(timeline.stn)

    # Apply solved times from STN back to intervals if available
    updated_timeline = %{timeline | stn: stn}

    case Map.get(stn.metadata, :solved_times) do
      nil ->
        updated_timeline

      solved_times ->
        apply_solved_times_to_intervals(updated_timeline, solved_times)
    end
  end

  # STN Encapsulation API - Functions needed by external modules

  @doc """
  Creates a new Timeline with STN configuration options.

  This function provides access to STN configuration while maintaining
  Timeline as the primary interface.
  """
  @spec new_with_stn_opts(keyword()) :: timeline()
  def new_with_stn_opts(stn_opts) do
    stn = STN.new(stn_opts)

    %{
      intervals: %{},
      bridges: %{},
      stn: stn,
      metadata: %{}
    }
  end

  @doc """
  Creates a new Timeline with constant work pattern enabled.
  """
  @spec new_constant_work(keyword()) :: timeline()
  def new_constant_work(opts \\ []) do
    stn = STN.new_constant_work(opts)

    %{
      intervals: %{},
      bridges: %{},
      stn: stn,
      metadata: %{}
    }
  end

  @doc """
  Checks if the Timeline's temporal constraints are consistent.
  """
  @spec consistent?(timeline()) :: boolean()
  def consistent?(timeline) do
    STN.consistent?(timeline.stn)
  end

  @doc """
  Gets all time points in the Timeline's STN.
  """
  @spec time_points(timeline()) :: [String.t()]
  def time_points(timeline) do
    STN.time_points(timeline.stn)
  end

  @doc """
  Adds a time point to the Timeline's STN.
  """
  @spec add_time_point(timeline(), String.t()) :: timeline()
  def add_time_point(timeline, time_point) do
    stn = STN.add_time_point(timeline.stn, time_point)
    %{timeline | stn: stn}
  end

  @doc """
  Gets a constraint between two time points.
  """
  @spec get_constraint(timeline(), String.t(), String.t()) :: {number(), number()} | nil
  def get_constraint(timeline, from_point, to_point) do
    STN.get_constraint(timeline.stn, from_point, to_point)
  end

  @doc """
  TOMBSTONE: PC-2 algorithm was removed in favor of MiniZinc-based STN solving.

  The Path Consistency (PC-2) algorithm implementation was removed as part of
  the temporal planning segment closure. Use Timeline.solve/1 instead, which
  uses the MiniZinc solver for STN constraint solving.

  Removed: January 2025
  Replacement: Timeline.solve/1
  """
  @spec apply_pc2(timeline()) :: timeline()
  def apply_pc2(timeline) do
    require Logger
    Logger.warning("TOMBSTONE: apply_pc2/1 is deprecated. Use Timeline.solve/1 instead.")
    solve(timeline)
  end

  # STN Composition Operations

  @doc """
  Computes the intersection of two Timelines.

  Returns a Timeline with constraints that satisfy both input Timelines.
  """
  @spec intersection(timeline(), timeline()) :: timeline()
  def intersection(timeline1, timeline2) do
    intersected_stn = STN.intersection(timeline1.stn, timeline2.stn)

    # Merge intervals from both timelines
    merged_intervals = Map.merge(timeline1.intervals, timeline2.intervals)

    # Merge metadata
    merged_metadata = Map.merge(timeline1.metadata, timeline2.metadata)

    %{
      intervals: merged_intervals,
      bridges: %{},
      stn: intersected_stn,
      metadata: merged_metadata
    }
  end

  @doc """
  Computes the union of two Timelines.

  Returns a Timeline with constraints that allow either input Timeline to be satisfied.
  """
  @spec union(timeline(), timeline()) :: timeline()
  def union(timeline1, timeline2) do
    union_stn = STN.union(timeline1.stn, timeline2.stn)

    # Merge intervals from both timelines
    merged_intervals = Map.merge(timeline1.intervals, timeline2.intervals)

    # Merge metadata
    merged_metadata = Map.merge(timeline1.metadata, timeline2.metadata)

    %{
      intervals: merged_intervals,
      bridges: %{},
      stn: union_stn,
      metadata: merged_metadata
    }
  end

  @doc """
  Chains multiple Timelines sequentially.

  Returns a Timeline where the Timelines are executed in sequence.
  """
  @spec chain([timeline()]) :: timeline()
  def chain([]), do: new()
  def chain([single_timeline]), do: single_timeline

  def chain(timelines) when is_list(timelines) do
    stns = Enum.map(timelines, & &1.stn)
    chained_stn = STN.chain(stns)

    # Merge all intervals and metadata
    merged_intervals =
      timelines
      |> Enum.map(& &1.intervals)
      |> Enum.reduce(%{}, &Map.merge/2)

    merged_metadata =
      timelines
      |> Enum.map(& &1.metadata)
      |> Enum.reduce(%{}, &Map.merge/2)

    %{
      intervals: merged_intervals,
      bridges: %{},
      stn: chained_stn,
      metadata: merged_metadata
    }
  end

  @doc """
  Joins multiple Timelines in parallel.

  Returns a Timeline where the Timelines can be executed concurrently.
  """
  @spec parallel_join([timeline()]) :: timeline()
  def parallel_join([]), do: new()
  def parallel_join([single_timeline]), do: single_timeline

  def parallel_join(timelines) when is_list(timelines) do
    stns = Enum.map(timelines, & &1.stn)
    parallel_stn = STN.parallel_join(stns)

    # Merge all intervals and metadata
    merged_intervals =
      timelines
      |> Enum.map(& &1.intervals)
      |> Enum.reduce(%{}, &Map.merge/2)

    merged_metadata =
      timelines
      |> Enum.map(& &1.metadata)
      |> Enum.reduce(%{}, &Map.merge/2)

    %{
      intervals: merged_intervals,
      bridges: %{},
      stn: parallel_stn,
      metadata: merged_metadata
    }
  end

  @doc """
  Composes two Timelines.

  Returns a Timeline representing the composition of the two input Timelines.
  """
  @spec compose(timeline(), timeline()) :: timeline()
  def compose(timeline1, timeline2) do
    composed_stn = STN.compose(timeline1.stn, timeline2.stn)

    # Merge intervals from both timelines
    merged_intervals = Map.merge(timeline1.intervals, timeline2.intervals)

    # Merge metadata
    merged_metadata = Map.merge(timeline1.metadata, timeline2.metadata)

    %{
      intervals: merged_intervals,
      bridges: %{},
      stn: composed_stn,
      metadata: merged_metadata
    }
  end

  # STN Utility Functions

  @doc """
  Segments a Timeline for parallel processing.
  """
  @spec segment(timeline(), pos_integer()) :: timeline()
  def segment(timeline, max_segments) do
    segmented_stn = STN.segment(timeline.stn, max_segments)
    %{timeline | stn: segmented_stn}
  end

  @doc """
  Solves a Timeline using parallel processing.
  """
  @spec parallel_solve(timeline(), pos_integer()) :: timeline()
  def parallel_solve(timeline, max_segments) do
    solved_stn = STN.parallel_solve(timeline.stn, max_segments)
    %{timeline | stn: solved_stn}
  end

  # Direct STN Access (for migration compatibility)

  @doc """
  Gets the underlying STN for compatibility during migration.

  This function should only be used during the migration period and will be
  removed once all external modules use the Timeline API.
  """
  @spec get_stn(timeline()) :: STN.t()
  def get_stn(timeline), do: timeline.stn

  @doc """
  Creates a Timeline from an existing STN.

  This function should only be used during the migration period and will be
  removed once all external modules use the Timeline API.
  """
  @spec from_stn(STN.t()) :: timeline()
  def from_stn(stn) do
    %{
      intervals: %{},
      bridges: %{},
      stn: stn,
      metadata: %{}
    }
  end

  # Private helper functions

  defp apply_solved_times_to_intervals(timeline, solved_times) do
    # Get the base time from the first interval or use epoch
    base_time = get_base_time(timeline)

    # Get the LOD resolution from the STN (default to 100 if not available)
    lod_resolution = Map.get(timeline.stn, :lod_resolution, 100)

    # Update each interval with its solved start time
    updated_intervals =
      timeline.intervals
      |> Enum.map(fn {interval_id, interval} ->
        start_point = "#{interval_id}_start"
        end_point = "#{interval_id}_end"

        case {Map.get(solved_times, start_point), Map.get(solved_times, end_point)} do
          {start_offset, end_offset} when not is_nil(start_offset) and not is_nil(end_offset) ->
            # Convert STN time units to seconds
            # STN uses lod_resolution units per second (e.g., 100 = centiseconds)
            start_seconds = start_offset / lod_resolution
            end_seconds = end_offset / lod_resolution

            # Convert to DateTime
            new_start_time = DateTime.add(base_time, round(start_seconds * 1000), :millisecond)
            new_end_time = DateTime.add(base_time, round(end_seconds * 1000), :millisecond)

            updated_interval = %{interval | start_time: new_start_time, end_time: new_end_time}
            {interval_id, updated_interval}

          _ ->
            # Keep original interval if no solved times available
            {interval_id, interval}
        end
      end)
      |> Map.new()

    %{timeline | intervals: updated_intervals}
  end

  defp get_base_time(timeline) do
    case timeline.intervals |> Map.values() |> List.first() do
      nil ->
        # No intervals, use epoch
        DateTime.from_naive!(~N[2025-01-01 00:00:00], "Etc/UTC")

      first_interval ->
        # Use the start time of the first interval as base, but round down to the minute
        # This ensures we have a clean base time for the solved schedule
        start_time = first_interval.start_time
        %{start_time | second: 0, microsecond: {0, 0}}
    end
  end
end
