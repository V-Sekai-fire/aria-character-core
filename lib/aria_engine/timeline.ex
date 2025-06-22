# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule Timeline do
  @moduledoc """
  Timeline module with interval-based storage using Path Consistency (PC-2) algorithm
  for Simple Temporal Network (STN) solving.

  Accepts time input in seconds but solves at 1ms tick precision.
  Supports Allen's interval algebra with usability improvements.
  Respects agent vs entity distinction in temporal constraints.

  ## Time Representation
  - External API: seconds (float/integer)
  - Internal storage/solving: milliseconds (integer)
  - Precision: 1ms ticks as per ADR-006

  ## Features
  - All 13 Allen interval relations
  - Path Consistency (PC-2) STN solving
  - Agent/entity distinction
  - Fluent API for constraint building
  - Comprehensive edge case handling

  ## Examples

      iex> timeline = Timeline.new()
      iex> alias Timeline.Interval
      iex> start_time = DateTime.from_naive!(~N[2025-01-01 10:00:00], "Etc/UTC")
      iex> end_time = DateTime.from_naive!(~N[2025-01-01 12:00:00], "Etc/UTC")
      iex> interval = Interval.new(start_time, end_time)
      iex> timeline = Timeline.add_interval(timeline, interval)
      iex> length(Map.keys(timeline.intervals))
      1

  ## References

  - ADR-078: Timeline Module PC-2 STN Implementation
  - ADR-079: Timeline Module Implementation Progress
  - ADR-045: Allen's Interval Algebra Temporal Relationships
  - ADR-040: Temporal Constraint Solver Selection
  - ADR-046: Interval Notation Usability
  - ADR-006: Game Engine Real-time Execution (1ms tick requirement)
  """

  alias Timeline.Interval
  alias Timeline.Bridge
  alias Timeline.Internal.STN

  @type t :: %__MODULE__{
          intervals: %{Interval.id() => Interval.t()},
          bridges: %{Bridge.id() => Bridge.t()},
          stn: STN.t()
        }

  defstruct intervals: %{},
            bridges: %{},
            stn: STN.new(),
            metadata: %{}

  @spec new(keyword()) :: t()
  def new(opts \\ []) do
    intervals = Keyword.get(opts, :intervals, [])
    metadata = Keyword.get(opts, :metadata, %{})

    %__MODULE__{metadata: metadata}
    |> add_intervals(intervals)
  end

  @spec add_interval(t(), Interval.t()) :: t()
  def add_interval(%__MODULE__{} = timeline, interval) do
    stn =
      timeline.stn
      |> STN.add_interval(interval)

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

    timeline
    |> Map.put(:intervals, Map.delete(timeline.intervals, id))
    |> Map.put(:stn, stn)
  end

  @spec add_constraint(t(), String.t(), String.t(), {number(), number()}) :: t()
  def add_constraint(timeline, from_point, to_point, constraint) do
    stn = STN.add_constraint(timeline.stn, from_point, to_point, constraint)
    %{timeline | stn: stn}
  end

  # Bridge Management Functions

  @doc """
  Adds a bridge to the timeline.

  ## Examples

      iex> timeline = Timeline.new()
      iex> position = DateTime.from_naive!(~N[2025-01-01 12:00:00], "Etc/UTC")
      iex> bridge = Timeline.Bridge.new("decision_1", position, :decision)
      iex> updated_timeline = Timeline.add_bridge(timeline, bridge)
      iex> Map.has_key?(updated_timeline.bridges, "decision_1")
      true

  """
  @spec add_bridge(t(), Bridge.t()) :: t()
  def add_bridge(%__MODULE__{} = timeline, %Bridge{} = bridge) do
    validate_bridge_placement!(timeline, bridge)
    
    %{timeline | bridges: Map.put(timeline.bridges, bridge.id, bridge)}
  end

  @doc """
  Removes a bridge from the timeline.

  ## Examples

      iex> timeline = Timeline.new()
      iex> position = DateTime.from_naive!(~N[2025-01-01 12:00:00], "Etc/UTC")
      iex> bridge = Timeline.Bridge.new("decision_1", position, :decision)
      iex> timeline_with_bridge = Timeline.add_bridge(timeline, bridge)
      iex> updated_timeline = Timeline.remove_bridge(timeline_with_bridge, "decision_1")
      iex> Map.has_key?(updated_timeline.bridges, "decision_1")
      false

  """
  @spec remove_bridge(t(), Bridge.id()) :: t()
  def remove_bridge(%__MODULE__{} = timeline, bridge_id) do
    %{timeline | bridges: Map.delete(timeline.bridges, bridge_id)}
  end

  @doc """
  Gets a bridge by ID.

  ## Examples

      iex> timeline = Timeline.new()
      iex> position = DateTime.from_naive!(~N[2025-01-01 12:00:00], "Etc/UTC")
      iex> bridge = Timeline.Bridge.new("decision_1", position, :decision)
      iex> timeline_with_bridge = Timeline.add_bridge(timeline, bridge)
      iex> retrieved_bridge = Timeline.get_bridge(timeline_with_bridge, "decision_1")
      iex> retrieved_bridge.id
      "decision_1"

  """
  @spec get_bridge(t(), Bridge.id()) :: Bridge.t() | nil
  def get_bridge(%__MODULE__{bridges: bridges}, bridge_id) do
    bridges[bridge_id]
  end

  @doc """
  Gets all bridges in the timeline, sorted by position.

  ## Examples

      iex> timeline = Timeline.new()
      iex> pos1 = DateTime.from_naive!(~N[2025-01-01 11:00:00], "Etc/UTC")
      iex> pos2 = DateTime.from_naive!(~N[2025-01-01 12:00:00], "Etc/UTC")
      iex> bridge1 = Timeline.Bridge.new("b1", pos1, :decision)
      iex> bridge2 = Timeline.Bridge.new("b2", pos2, :condition)
      iex> timeline = timeline |> Timeline.add_bridge(bridge2) |> Timeline.add_bridge(bridge1)
      iex> [first, second] = Timeline.get_bridges(timeline)
      iex> first.id
      "b1"

  """
  @spec get_bridges(t()) :: [Bridge.t()]
  def get_bridges(%__MODULE__{bridges: bridges}) do
    bridges
    |> Map.values()
    |> Bridge.sort_by_position()
  end

  @doc """
  Updates a bridge in the timeline.

  ## Examples

      iex> timeline = Timeline.new()
      iex> position = DateTime.from_naive!(~N[2025-01-01 12:00:00], "Etc/UTC")
      iex> bridge = Timeline.Bridge.new("decision_1", position, :decision)
      iex> timeline_with_bridge = Timeline.add_bridge(timeline, bridge)
      iex> updated_bridge = Timeline.Bridge.update_metadata(bridge, %{priority: :high})
      iex> updated_timeline = Timeline.update_bridge(timeline_with_bridge, updated_bridge)
      iex> retrieved_bridge = Timeline.get_bridge(updated_timeline, "decision_1")
      iex> retrieved_bridge.metadata.priority
      :high

  """
  @spec update_bridge(t(), Bridge.t()) :: t()
  def update_bridge(%__MODULE__{} = timeline, %Bridge{} = bridge) do
    case validate_bridge_placement(timeline, bridge, true) do
      :ok -> %{timeline | bridges: Map.put(timeline.bridges, bridge.id, bridge)}
      {:error, message} -> raise ArgumentError, message
    end
  end

  # Bridge Segmentation Functions

  @doc """
  Segments the timeline by bridge positions.

  Returns a list of timeline segments, where each segment contains intervals
  that occur between bridge points. Each segment is a complete Timeline
  with proper DateTime intervals.

  ## Examples

      iex> timeline = Timeline.new()
      iex> start1 = DateTime.from_naive!(~N[2025-01-01 10:00:00], "Etc/UTC")
      iex> end1 = DateTime.from_naive!(~N[2025-01-01 11:00:00], "Etc/UTC")
      iex> interval1 = Timeline.Interval.new(start1, end1)
      iex> timeline = Timeline.add_interval(timeline, interval1)
      iex> bridge_pos = DateTime.from_naive!(~N[2025-01-01 10:30:00], "Etc/UTC")
      iex> bridge = Timeline.Bridge.new("decision_1", bridge_pos, :decision)
      iex> timeline = Timeline.add_bridge(timeline, bridge)
      iex> segments = Timeline.segment_by_bridges(timeline)
      iex> length(segments)
      2

  """
  @spec segment_by_bridges(t()) :: [t()]
  def segment_by_bridges(%__MODULE__{} = timeline) do
    bridges = get_bridges(timeline)
    
    case bridges do
      [] ->
        # No bridges, return the timeline as a single segment
        [%{timeline | metadata: Map.put(timeline.metadata, :segment, 1)}]
      
      _ ->
        # Create segments based on bridge positions
        create_segments_from_bridges(timeline, bridges)
    end
  end

  @doc """
  Gets the temporal positions of all bridges in the timeline.

  ## Examples

      iex> timeline = Timeline.new()
      iex> pos1 = DateTime.from_naive!(~N[2025-01-01 11:00:00], "Etc/UTC")
      iex> pos2 = DateTime.from_naive!(~N[2025-01-01 12:00:00], "Etc/UTC")
      iex> bridge1 = Timeline.Bridge.new("b1", pos1, :decision)
      iex> bridge2 = Timeline.Bridge.new("b2", pos2, :condition)
      iex> timeline = timeline |> Timeline.add_bridge(bridge1) |> Timeline.add_bridge(bridge2)
      iex> positions = Timeline.bridge_positions(timeline)
      iex> length(positions)
      2

  """
  @spec bridge_positions(t()) :: [DateTime.t()]
  def bridge_positions(%__MODULE__{} = timeline) do
    timeline
    |> get_bridges()
    |> Enum.map(& &1.position)
  end

  @doc """
  Validates that a bridge can be placed at the specified position.

  Checks that the bridge position doesn't conflict with existing intervals
  or create temporal inconsistencies.

  ## Examples

      iex> timeline = Timeline.new()
      iex> position = DateTime.from_naive!(~N[2025-01-01 12:00:00], "Etc/UTC")
      iex> bridge = Timeline.Bridge.new("decision_1", position, :decision)
      iex> Timeline.validate_bridge_placement(timeline, bridge)
      :ok

  """
  @spec validate_bridge_placement(t(), Bridge.t()) :: :ok | {:error, String.t()}
  def validate_bridge_placement(%__MODULE__{} = timeline, %Bridge{} = bridge) do
    validate_bridge_placement(timeline, bridge, false)
  end

  @doc """
  Validates that a bridge can be placed at the specified position.

  The `allow_existing` parameter controls whether to allow updating an existing bridge ID.
  """
  @spec validate_bridge_placement(t(), Bridge.t(), boolean()) :: :ok | {:error, String.t()}
  def validate_bridge_placement(%__MODULE__{} = timeline, %Bridge{} = bridge, allow_existing) do
    # Check for duplicate bridge IDs only if not allowing existing
    case {Map.has_key?(timeline.bridges, bridge.id), allow_existing} do
      {true, false} ->
        {:error, "Bridge with ID '#{bridge.id}' already exists"}
      
      _ ->
        # Check for temporal conflicts with intervals
        validate_bridge_temporal_placement(timeline, bridge)
    end
  end

  @doc """
  Finds bridges within a specific time range.

  ## Examples

      iex> timeline = Timeline.new()
      iex> start_time = DateTime.from_naive!(~N[2025-01-01 10:00:00], "Etc/UTC")
      iex> end_time = DateTime.from_naive!(~N[2025-01-01 14:00:00], "Etc/UTC")
      iex> pos1 = DateTime.from_naive!(~N[2025-01-01 11:00:00], "Etc/UTC")
      iex> pos2 = DateTime.from_naive!(~N[2025-01-01 15:00:00], "Etc/UTC")
      iex> bridge1 = Timeline.Bridge.new("b1", pos1, :decision)
      iex> bridge2 = Timeline.Bridge.new("b2", pos2, :decision)
      iex> timeline = timeline |> Timeline.add_bridge(bridge1) |> Timeline.add_bridge(bridge2)
      iex> bridges = Timeline.bridges_in_range(timeline, start_time, end_time)
      iex> length(bridges)
      1

  """
  @spec bridges_in_range(t(), DateTime.t(), DateTime.t()) :: [Bridge.t()]
  def bridges_in_range(%__MODULE__{} = timeline, start_time, end_time) do
    timeline
    |> get_bridges()
    |> Bridge.in_range(start_time, end_time)
  end

  @spec solve(t()) :: t()
  def solve(timeline) do
    require Logger
    stn = STN.solve(timeline.stn)

    # Apply solved times from STN back to intervals if available
    updated_timeline = %{timeline | stn: stn}

    case Map.get(stn.metadata, :solved_times) do
      nil ->
        updated_timeline

      solved_times ->
        result = apply_solved_times_to_intervals(updated_timeline, solved_times)
        result
    end
  end

  # STN Encapsulation API - Functions needed by external modules

  @doc """
  Creates a new Timeline with STN configuration options.

  This function provides access to STN configuration while maintaining
  Timeline as the primary interface.
  """
  @spec new_with_stn_opts(keyword()) :: t()
  def new_with_stn_opts(stn_opts) do
    stn = STN.new(stn_opts)

    %__MODULE__{
      intervals: %{},
      stn: stn,
      metadata: %{}
    }
  end

  @doc """
  Creates a new Timeline with constant work pattern enabled.
  """
  @spec new_constant_work(keyword()) :: t()
  def new_constant_work(opts \\ []) do
    stn = STN.new_constant_work(opts)

    %__MODULE__{
      intervals: %{},
      stn: stn,
      metadata: %{}
    }
  end

  @doc """
  Checks if the Timeline's temporal constraints are consistent.
  """
  @spec consistent?(t()) :: boolean()
  def consistent?(timeline) do
    STN.consistent?(timeline.stn)
  end

  @doc """
  Gets all time points in the Timeline's STN.
  """
  @spec time_points(t()) :: [String.t()]
  def time_points(timeline) do
    STN.time_points(timeline.stn)
  end

  @doc """
  Adds a time point to the Timeline's STN.
  """
  @spec add_time_point(t(), String.t()) :: t()
  def add_time_point(timeline, time_point) do
    stn = STN.add_time_point(timeline.stn, time_point)
    %{timeline | stn: stn}
  end

  @doc """
  Gets a constraint between two time points.
  """
  @spec get_constraint(t(), String.t(), String.t()) :: {number(), number()} | nil
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
  @spec apply_pc2(t()) :: t()
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
  @spec intersection(t(), t()) :: t()
  def intersection(timeline1, timeline2) do
    intersected_stn = STN.intersection(timeline1.stn, timeline2.stn)

    # Merge intervals from both timelines
    merged_intervals = Map.merge(timeline1.intervals, timeline2.intervals)

    # Merge metadata
    merged_metadata = Map.merge(timeline1.metadata, timeline2.metadata)

    %__MODULE__{
      intervals: merged_intervals,
      stn: intersected_stn,
      metadata: merged_metadata
    }
  end

  @doc """
  Computes the union of two Timelines.

  Returns a Timeline with constraints that allow either input Timeline to be satisfied.
  """
  @spec union(t(), t()) :: t()
  def union(timeline1, timeline2) do
    union_stn = STN.union(timeline1.stn, timeline2.stn)

    # Merge intervals from both timelines
    merged_intervals = Map.merge(timeline1.intervals, timeline2.intervals)

    # Merge metadata
    merged_metadata = Map.merge(timeline1.metadata, timeline2.metadata)

    %__MODULE__{
      intervals: merged_intervals,
      stn: union_stn,
      metadata: merged_metadata
    }
  end

  @doc """
  Chains multiple Timelines sequentially.

  Returns a Timeline where the Timelines are executed in sequence.
  """
  @spec chain([t()]) :: t()
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

    %__MODULE__{
      intervals: merged_intervals,
      stn: chained_stn,
      metadata: merged_metadata
    }
  end

  @doc """
  Joins multiple Timelines in parallel.

  Returns a Timeline where the Timelines can be executed concurrently.
  """
  @spec parallel_join([t()]) :: t()
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

    %__MODULE__{
      intervals: merged_intervals,
      stn: parallel_stn,
      metadata: merged_metadata
    }
  end

  @doc """
  Composes two Timelines.

  Returns a Timeline representing the composition of the two input Timelines.
  """
  @spec compose(t(), t()) :: t()
  def compose(timeline1, timeline2) do
    composed_stn = STN.compose(timeline1.stn, timeline2.stn)

    # Merge intervals from both timelines
    merged_intervals = Map.merge(timeline1.intervals, timeline2.intervals)

    # Merge metadata
    merged_metadata = Map.merge(timeline1.metadata, timeline2.metadata)

    %__MODULE__{
      intervals: merged_intervals,
      stn: composed_stn,
      metadata: merged_metadata
    }
  end

  # STN Utility Functions

  @doc """
  Segments a Timeline for parallel processing.
  """
  @spec segment(t(), pos_integer()) :: t()
  def segment(timeline, max_segments) do
    segmented_stn = STN.segment(timeline.stn, max_segments)
    %{timeline | stn: segmented_stn}
  end

  @doc """
  Solves a Timeline using parallel processing.
  """
  @spec parallel_solve(t(), pos_integer()) :: t()
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
  @spec get_stn(t()) :: STN.t()
  def get_stn(timeline), do: timeline.stn

  @doc """
  Creates a Timeline from an existing STN.

  This function should only be used during the migration period and will be
  removed once all external modules use the Timeline API.
  """
  @spec from_stn(STN.t()) :: t()
  def from_stn(stn) do
    %__MODULE__{
      intervals: %{},
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

  # Bridge validation and segmentation helper functions

  defp validate_bridge_placement!(%__MODULE__{} = timeline, %Bridge{} = bridge) do
    case validate_bridge_placement(timeline, bridge) do
      :ok -> :ok
      {:error, message} -> raise ArgumentError, message
    end
  end

  defp validate_bridge_temporal_placement(%__MODULE__{} = timeline, %Bridge{} = bridge) do
    # Check if bridge position conflicts with any intervals
    conflicts = 
      timeline.intervals
      |> Map.values()
      |> Enum.filter(fn interval ->
        # Bridge should not be placed exactly at interval start or end times
        # to avoid ambiguity in segmentation
        DateTime.compare(bridge.position, interval.start_time) == :eq or
        DateTime.compare(bridge.position, interval.end_time) == :eq
      end)

    case conflicts do
      [] -> :ok
      [conflict | _] ->
        {:error, "Bridge position conflicts with interval '#{conflict.id}' boundary"}
    end
  end

  defp create_segments_from_bridges(%__MODULE__{} = timeline, bridges) do
    # Get sorted bridge positions
    bridge_positions = Enum.map(bridges, & &1.position)
    
    # Create time ranges for each segment
    time_ranges = create_time_ranges(timeline, bridge_positions)
    
    # Create a segment for each time range
    time_ranges
    |> Enum.with_index(1)
    |> Enum.map(fn {{start_time, end_time, bridge_before}, segment_num} ->
      create_segment(timeline, start_time, end_time, segment_num, bridge_before)
    end)
    |> Enum.reject(&segment_empty?/1)
  end

  defp create_time_ranges(%__MODULE__{} = timeline, bridge_positions) do
    # Get the overall timeline bounds
    {timeline_start, timeline_end} = get_timeline_bounds(timeline)
    
    # Create ranges: [timeline_start, bridge1], [bridge1, bridge2], ..., [bridgeN, timeline_end]
    all_boundaries = [timeline_start] ++ bridge_positions ++ [timeline_end]
    
    all_boundaries
    |> Enum.chunk_every(2, 1, :discard)
    |> Enum.with_index()
    |> Enum.map(fn {[start_time, end_time], index} ->
      bridge_before = if index == 0, do: nil, else: Enum.at(bridge_positions, index - 1)
      {start_time, end_time, bridge_before}
    end)
  end

  defp get_timeline_bounds(%__MODULE__{intervals: intervals}) when map_size(intervals) == 0 do
    # No intervals, use a default range
    start_time = DateTime.from_naive!(~N[2025-01-01 00:00:00], "Etc/UTC")
    end_time = DateTime.from_naive!(~N[2025-01-01 23:59:59], "Etc/UTC")
    {start_time, end_time}
  end

  defp get_timeline_bounds(%__MODULE__{intervals: intervals}) do
    interval_list = Map.values(intervals)
    
    start_time = 
      interval_list
      |> Enum.map(& &1.start_time)
      |> Enum.min(DateTime)
    
    end_time = 
      interval_list
      |> Enum.map(& &1.end_time)
      |> Enum.max(DateTime)
    
    {start_time, end_time}
  end

  defp create_segment(%__MODULE__{} = timeline, start_time, end_time, segment_num, bridge_before) do
    # Filter intervals that fall within this segment's time range
    segment_intervals = 
      timeline.intervals
      |> Enum.filter(fn {_id, interval} ->
        interval_in_range?(interval, start_time, end_time)
      end)
      |> Map.new()

    # Create segment metadata
    segment_metadata = 
      timeline.metadata
      |> Map.put(:segment, segment_num)
      |> Map.put(:bridge_before, bridge_before)
      |> Map.put(:segment_start, start_time)
      |> Map.put(:segment_end, end_time)

    # Create new timeline for this segment
    %__MODULE__{
      intervals: segment_intervals,
      bridges: %{}, # Segments don't inherit bridges
      stn: STN.new(), # Each segment gets a fresh STN
      metadata: segment_metadata
    }
  end

  defp interval_in_range?(%Interval{start_time: start_time, end_time: end_time}, range_start, range_end) do
    # Interval overlaps with the range if:
    # - interval start is before range end AND
    # - interval end is after range start
    DateTime.compare(start_time, range_end) == :lt and
    DateTime.compare(end_time, range_start) == :gt
  end

  defp segment_empty?(%__MODULE__{intervals: intervals}) do
    map_size(intervals) == 0
  end
end
