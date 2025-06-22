# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngine.Timeline do
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

  ## Module Organization

  This module has been split into focused sub-modules for better maintainability:

  - `AriaEngine.Timeline.Core` - Core Timeline operations and STN integration
  - `AriaEngine.Timeline.Bridges` - Bridge management and validation
  - `AriaEngine.Timeline.Segmentation` - Timeline segmentation functionality
  - `AriaEngine.Timeline.Builder` - Builder pattern and fluent API

  ## Examples

      iex> timeline = AriaEngine.Timeline.new()
      iex> alias AriaEngine.Timeline.Interval
      iex> start_time = DateTime.from_naive!(~N[2025-01-01 10:00:00], "Etc/UTC")
      iex> end_time = DateTime.from_naive!(~N[2025-01-01 12:00:00], "Etc/UTC")
      iex> interval = Interval.new(start_time, end_time)
      iex> timeline = AriaEngine.Timeline.add_interval(timeline, interval)
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

  alias AriaEngine.Timeline.IntervalOperations
  alias AriaEngine.Timeline.BridgeOperations
  alias AriaEngine.Timeline.TimelineSegmenter
  alias AriaEngine.Timeline.Interval
  alias AriaEngine.Timeline.Bridge
  alias AriaEngine.Timeline.Internal.STN

  @type t :: %__MODULE__{
          intervals: %{Interval.id() => Interval.t()},
          bridges: %{Bridge.id() => Bridge.t()},
          stn: STN.t(),
          metadata: map()
        }

  defstruct intervals: %{},
            bridges: %{},
            stn: STN.new(),
            metadata: %{}

  # ==================== CORE TIMELINE OPERATIONS ====================

  @doc """
  Creates a new Timeline.

  ## Examples

      iex> timeline = AriaEngine.Timeline.new()
      iex> map_size(timeline.intervals)
      0

  """
  @spec new(keyword()) :: t()
  def new(opts \\ []) do
    core_timeline = IntervalOperations.new(opts)
    struct(__MODULE__, core_timeline)
  end

  @doc """
  Adds an interval to the timeline.

  ## Examples

      iex> timeline = AriaEngine.Timeline.new()
      iex> start_time = DateTime.from_naive!(~N[2025-01-01 10:00:00], "Etc/UTC")
      iex> end_time = DateTime.from_naive!(~N[2025-01-01 12:00:00], "Etc/UTC")
      iex> interval = AriaEngine.Timeline.Interval.new(start_time, end_time)
      iex> updated_timeline = AriaEngine.Timeline.add_interval(timeline, interval)
      iex> map_size(updated_timeline.intervals)
      1

  """
  @spec add_interval(t(), Interval.t()) :: t()
  def add_interval(%__MODULE__{} = timeline, interval) do
    core_timeline = to_core_timeline(timeline)
    updated_core = IntervalOperations.add_interval(core_timeline, interval)
    struct(__MODULE__, updated_core)
  end

  @doc """
  Adds multiple intervals to the timeline.

  ## Examples

      iex> timeline = AriaEngine.Timeline.new()
      iex> start1 = DateTime.from_naive!(~N[2025-01-01 10:00:00], "Etc/UTC")
      iex> end1 = DateTime.from_naive!(~N[2025-01-01 11:00:00], "Etc/UTC")
      iex> start2 = DateTime.from_naive!(~N[2025-01-01 12:00:00], "Etc/UTC")
      iex> end2 = DateTime.from_naive!(~N[2025-01-01 13:00:00], "Etc/UTC")
      iex> interval1 = AriaEngine.Timeline.Interval.new(start1, end1)
      iex> interval2 = AriaEngine.Timeline.Interval.new(start2, end2)
      iex> updated_timeline = AriaEngine.Timeline.add_intervals(timeline, [interval1, interval2])
      iex> map_size(updated_timeline.intervals)
      2

  """
  @spec add_intervals(t(), list(Interval.t())) :: t()
  def add_intervals(%__MODULE__{} = timeline, intervals) do
    core_timeline = to_core_timeline(timeline)
    updated_core = IntervalOperations.add_intervals(core_timeline, intervals)
    struct(__MODULE__, updated_core)
  end

  @doc """
  Gets an interval by ID.

  ## Examples

      iex> timeline = AriaEngine.Timeline.new()
      iex> start_time = DateTime.from_naive!(~N[2025-01-01 10:00:00], "Etc/UTC")
      iex> end_time = DateTime.from_naive!(~N[2025-01-01 12:00:00], "Etc/UTC")
      iex> interval = AriaEngine.Timeline.Interval.new(start_time, end_time)
      iex> timeline = AriaEngine.Timeline.add_interval(timeline, interval)
      iex> retrieved = AriaEngine.Timeline.get_interval(timeline, interval.id)
      iex> retrieved.id == interval.id
      true

  """
  @spec get_interval(t(), Interval.id()) :: Interval.t() | nil
  def get_interval(%__MODULE__{} = timeline, id) do
    core_timeline = to_core_timeline(timeline)
    IntervalOperations.get_interval(core_timeline, id)
  end

  @doc """
  Updates an interval in the timeline.
  """
  @spec update_interval(t(), Interval.t()) :: t()
  def update_interval(%__MODULE__{} = timeline, interval) do
    core_timeline = to_core_timeline(timeline)
    updated_core = IntervalOperations.update_interval(core_timeline, interval)
    struct(__MODULE__, updated_core)
  end

  @doc """
  Removes an interval from the timeline.
  """
  @spec remove_interval(t(), Interval.id()) :: t()
  def remove_interval(%__MODULE__{} = timeline, id) do
    core_timeline = to_core_timeline(timeline)
    updated_core = IntervalOperations.remove_interval(core_timeline, id)
    struct(__MODULE__, updated_core)
  end

  @doc """
  Adds a constraint between two time points.
  """
  @spec add_constraint(t(), String.t(), String.t(), {number(), number()}) :: t()
  def add_constraint(%__MODULE__{} = timeline, from_point, to_point, constraint) do
    core_timeline = to_core_timeline(timeline)
    updated_core = IntervalOperations.add_constraint(core_timeline, from_point, to_point, constraint)
    struct(__MODULE__, updated_core)
  end

  @doc """
  Solves the timeline's temporal constraints.
  """
  @spec solve(t()) :: t()
  def solve(%__MODULE__{} = timeline) do
    core_timeline = to_core_timeline(timeline)
    updated_core = IntervalOperations.solve(core_timeline)
    struct(__MODULE__, updated_core)
  end

  # ==================== BRIDGE MANAGEMENT ====================

  @doc """
  Adds a bridge to the timeline.

  ## Examples

      iex> timeline = AriaEngine.Timeline.new()
      iex> position = DateTime.from_naive!(~N[2025-01-01 12:00:00], "Etc/UTC")
      iex> bridge = AriaEngine.Timeline.Bridge.new("decision_1", position, :decision)
      iex> updated_timeline = AriaEngine.Timeline.add_bridge(timeline, bridge)
      iex> Map.has_key?(updated_timeline.bridges, "decision_1")
      true

  """
  @spec add_bridge(t(), Bridge.t()) :: t()
  def add_bridge(%__MODULE__{} = timeline, bridge) do
    core_timeline = to_core_timeline(timeline)
    updated_core = BridgeOperations.add_bridge(core_timeline, bridge)
    struct(__MODULE__, updated_core)
  end

  @doc """
  Removes a bridge from the timeline.
  """
  @spec remove_bridge(t(), Bridge.id()) :: t()
  def remove_bridge(%__MODULE__{} = timeline, bridge_id) do
    core_timeline = to_core_timeline(timeline)
    updated_core = BridgeOperations.remove_bridge(core_timeline, bridge_id)
    struct(__MODULE__, updated_core)
  end

  @doc """
  Gets a bridge by ID.
  """
  @spec get_bridge(t(), Bridge.id()) :: Bridge.t() | nil
  def get_bridge(%__MODULE__{} = timeline, bridge_id) do
    core_timeline = to_core_timeline(timeline)
    BridgeOperations.get_bridge(core_timeline, bridge_id)
  end

  @doc """
  Gets all bridges in the timeline, sorted by position.
  """
  @spec get_bridges(t()) :: [Bridge.t()]
  def get_bridges(%__MODULE__{} = timeline) do
    core_timeline = to_core_timeline(timeline)
    BridgeOperations.get_bridges(core_timeline)
  end

  @doc """
  Updates a bridge in the timeline.
  """
  @spec update_bridge(t(), Bridge.t()) :: t()
  def update_bridge(%__MODULE__{} = timeline, bridge) do
    core_timeline = to_core_timeline(timeline)
    updated_core = BridgeOperations.update_bridge(core_timeline, bridge)
    struct(__MODULE__, updated_core)
  end

  @doc """
  Gets the temporal positions of all bridges in the timeline.
  """
  @spec bridge_positions(t()) :: [DateTime.t()]
  def bridge_positions(%__MODULE__{} = timeline) do
    core_timeline = to_core_timeline(timeline)
    BridgeOperations.bridge_positions(core_timeline)
  end

  @doc """
  Validates that a bridge can be placed at the specified position.
  """
  @spec validate_bridge_placement(t(), Bridge.t()) :: :ok | {:error, String.t()}
  def validate_bridge_placement(%__MODULE__{} = timeline, bridge) do
    core_timeline = to_core_timeline(timeline)
    BridgeOperations.validate_bridge_placement(core_timeline, bridge)
  end

  @doc """
  Finds bridges within a specific time range.
  """
  @spec bridges_in_range(t(), DateTime.t(), DateTime.t()) :: [Bridge.t()]
  def bridges_in_range(%__MODULE__{} = timeline, start_time, end_time) do
    core_timeline = to_core_timeline(timeline)
    BridgeOperations.bridges_in_range(core_timeline, start_time, end_time)
  end

  @doc """
  Validates all bridge placements in the timeline.
  """
  @spec validate_all_bridge_placements(t()) :: :ok | {:error, String.t()}
  def validate_all_bridge_placements(%__MODULE__{} = timeline) do
    core_timeline = to_core_timeline(timeline)
    BridgeOperations.validate_all_bridge_placements(core_timeline)
  end

  # ==================== SEGMENTATION ====================

  @doc """
  Segments the timeline by bridge positions.

  Returns a list of timeline segments, where each segment contains intervals
  that occur between bridge points.

  ## Examples

      iex> timeline = AriaEngine.Timeline.new()
      iex> start1 = DateTime.from_naive!(~N[2025-01-01 10:00:00], "Etc/UTC")
      iex> end1 = DateTime.from_naive!(~N[2025-01-01 11:00:00], "Etc/UTC")
      iex> interval1 = AriaEngine.Timeline.Interval.new(start1, end1)
      iex> timeline = AriaEngine.Timeline.add_interval(timeline, interval1)
      iex> bridge_pos = DateTime.from_naive!(~N[2025-01-01 10:30:00], "Etc/UTC")
      iex> bridge = AriaEngine.Timeline.Bridge.new("decision_1", bridge_pos, :decision)
      iex> timeline = AriaEngine.Timeline.add_bridge(timeline, bridge)
      iex> segments = AriaEngine.Timeline.segment_by_bridges(timeline)
      iex> length(segments)
      2

  """
  @spec segment_by_bridges(t()) :: [t()]
  def segment_by_bridges(%__MODULE__{} = timeline) do
    core_timeline = to_core_timeline(timeline)
    core_segments = TimelineSegmenter.segment_by_bridges(core_timeline)
    Enum.map(core_segments, &struct(__MODULE__, &1))
  end

  @doc """
  Gets the temporal bounds of a timeline (earliest start, latest end).
  """
  @spec get_timeline_bounds(t()) :: {DateTime.t(), DateTime.t()}
  def get_timeline_bounds(%__MODULE__{} = timeline) do
    core_timeline = to_core_timeline(timeline)
    TimelineSegmenter.get_timeline_bounds(core_timeline)
  end

  # ==================== STN ENCAPSULATION API ====================

  @doc """
  Creates a new Timeline with STN configuration options.
  """
  @spec new_with_stn_opts(keyword()) :: t()
  def new_with_stn_opts(stn_opts) do
    core_timeline = IntervalOperations.new_with_stn_opts(stn_opts)
    struct(__MODULE__, core_timeline)
  end

  @doc """
  Creates a new Timeline with constant work pattern enabled.
  """
  @spec new_constant_work(keyword()) :: t()
  def new_constant_work(opts \\ []) do
    core_timeline = IntervalOperations.new_constant_work(opts)
    struct(__MODULE__, core_timeline)
  end

  @doc """
  Checks if the Timeline's temporal constraints are consistent.
  """
  @spec consistent?(t()) :: boolean()
  def consistent?(%__MODULE__{} = timeline) do
    core_timeline = to_core_timeline(timeline)
    IntervalOperations.consistent?(core_timeline)
  end

  @doc """
  Gets all time points in the Timeline's STN.
  """
  @spec time_points(t()) :: [String.t()]
  def time_points(%__MODULE__{} = timeline) do
    core_timeline = to_core_timeline(timeline)
    IntervalOperations.time_points(core_timeline)
  end

  @doc """
  Adds a time point to the Timeline's STN.
  """
  @spec add_time_point(t(), String.t()) :: t()
  def add_time_point(%__MODULE__{} = timeline, time_point) do
    core_timeline = to_core_timeline(timeline)
    updated_core = IntervalOperations.add_time_point(core_timeline, time_point)
    struct(__MODULE__, updated_core)
  end

  @doc """
  Gets a constraint between two time points.
  """
  @spec get_constraint(t(), String.t(), String.t()) :: {number(), number()} | nil
  def get_constraint(%__MODULE__{} = timeline, from_point, to_point) do
    core_timeline = to_core_timeline(timeline)
    IntervalOperations.get_constraint(core_timeline, from_point, to_point)
  end

  @doc """
  TOMBSTONE: PC-2 algorithm was removed in favor of MiniZinc-based STN solving.
  """
  @spec apply_pc2(t()) :: t()
  def apply_pc2(%__MODULE__{} = timeline) do
    core_timeline = to_core_timeline(timeline)
    updated_core = IntervalOperations.apply_pc2(core_timeline)
    struct(__MODULE__, updated_core)
  end

  # ==================== STN COMPOSITION OPERATIONS ====================

  @doc """
  Computes the intersection of two Timelines.
  """
  @spec intersection(t(), t()) :: t()
  def intersection(%__MODULE__{} = timeline1, %__MODULE__{} = timeline2) do
    core1 = to_core_timeline(timeline1)
    core2 = to_core_timeline(timeline2)
    updated_core = IntervalOperations.intersection(core1, core2)
    struct(__MODULE__, updated_core)
  end

  @doc """
  Computes the union of two Timelines.
  """
  @spec union(t(), t()) :: t()
  def union(%__MODULE__{} = timeline1, %__MODULE__{} = timeline2) do
    core1 = to_core_timeline(timeline1)
    core2 = to_core_timeline(timeline2)
    updated_core = IntervalOperations.union(core1, core2)
    struct(__MODULE__, updated_core)
  end

  @doc """
  Chains multiple Timelines sequentially.
  """
  @spec chain([t()]) :: t()
  def chain([]), do: new()
  def chain([single_timeline]), do: single_timeline

  def chain(timelines) when is_list(timelines) do
    core_timelines = Enum.map(timelines, &to_core_timeline/1)
    updated_core = IntervalOperations.chain(core_timelines)
    struct(__MODULE__, updated_core)
  end

  @doc """
  Joins multiple Timelines in parallel.
  """
  @spec parallel_join([t()]) :: t()
  def parallel_join([]), do: new()
  def parallel_join([single_timeline]), do: single_timeline

  def parallel_join(timelines) when is_list(timelines) do
    core_timelines = Enum.map(timelines, &to_core_timeline/1)
    updated_core = IntervalOperations.parallel_join(core_timelines)
    struct(__MODULE__, updated_core)
  end

  @doc """
  Composes two Timelines.
  """
  @spec compose(t(), t()) :: t()
  def compose(%__MODULE__{} = timeline1, %__MODULE__{} = timeline2) do
    core1 = to_core_timeline(timeline1)
    core2 = to_core_timeline(timeline2)
    updated_core = IntervalOperations.compose(core1, core2)
    struct(__MODULE__, updated_core)
  end

  # ==================== STN UTILITY FUNCTIONS ====================

  @doc """
  Segments a Timeline for parallel processing.
  """
  @spec segment(t(), pos_integer()) :: t()
  def segment(%__MODULE__{} = timeline, max_segments) do
    core_timeline = to_core_timeline(timeline)
    updated_core = IntervalOperations.segment(core_timeline, max_segments)
    struct(__MODULE__, updated_core)
  end

  @doc """
  Solves a Timeline using parallel processing.
  """
  @spec parallel_solve(t(), pos_integer()) :: t()
  def parallel_solve(%__MODULE__{} = timeline, max_segments) do
    core_timeline = to_core_timeline(timeline)
    updated_core = IntervalOperations.parallel_solve(core_timeline, max_segments)
    struct(__MODULE__, updated_core)
  end

  # ==================== DIRECT STN ACCESS (MIGRATION COMPATIBILITY) ====================

  @doc """
  Gets the underlying STN for compatibility during migration.
  """
  @spec get_stn(t()) :: STN.t()
  def get_stn(%__MODULE__{} = timeline) do
    core_timeline = to_core_timeline(timeline)
    IntervalOperations.get_stn(core_timeline)
  end

  @doc """
  Creates a Timeline from an existing STN.
  """
  @spec from_stn(STN.t()) :: t()
  def from_stn(stn) do
    core_timeline = IntervalOperations.from_stn(stn)
    struct(__MODULE__, core_timeline)
  end

  # ==================== BRIDGE BUILDER PATTERN FUNCTIONS ====================

  @doc """
  Enable automatic bridge segmentation for this timeline.
  """
  @spec with_bridge_segmentation(t()) :: t()
  def with_bridge_segmentation(%__MODULE__{} = timeline) do
    updated_metadata = Map.put(timeline.metadata, :auto_bridge_mode, true)
    %{timeline | metadata: updated_metadata}
  end

  @doc """
  Automatically insert bridges at logical decision points.
  """
  @spec auto_insert_bridges(t(), [atom()]) :: t()
  def auto_insert_bridges(%__MODULE__{} = timeline, rules \\ [:action_type_transitions]) do
    # This functionality could be moved to Builder module in the future
    # For now, keeping the existing implementation for compatibility
    bridges_to_add = analyze_and_create_bridges(timeline, rules)

    Enum.reduce(bridges_to_add, timeline, fn bridge, acc_timeline ->
      add_bridge(acc_timeline, bridge)
    end)
  end

  @doc """
  Add a phase of intervals with automatic bridge insertion.
  """
  @spec add_phase(t(), String.t(), [Interval.t()]) :: t()
  def add_phase(%__MODULE__{} = timeline, phase_name, intervals) do
    # Add all intervals in the phase
    timeline_with_intervals = add_intervals(timeline, intervals)

    # If auto-bridge mode is enabled, add a bridge at the end of this phase
    case Map.get(timeline.metadata, :auto_bridge_mode, false) do
      true ->
        # Find the end time of this phase
        phase_end_time = get_phase_end_time(intervals)

        # Create a bridge at the phase boundary
        bridge_id = "#{phase_name}_end"
        bridge = Bridge.new(bridge_id, phase_end_time, :decision, %{phase: phase_name})

        add_bridge(timeline_with_intervals, bridge)

      false ->
        timeline_with_intervals
    end
  end

  # ==================== PRIVATE HELPER FUNCTIONS ====================

  # Convert Timeline struct to core timeline map for delegation
  defp to_core_timeline(%__MODULE__{} = timeline) do
    %{
      intervals: timeline.intervals,
      bridges: timeline.bridges,
      stn: timeline.stn,
      metadata: timeline.metadata
    }
  end

  # Legacy bridge analysis functions (kept for compatibility)
  defp analyze_and_create_bridges(%__MODULE__{} = timeline, rules) do
    intervals = Map.values(timeline.intervals)

    Enum.flat_map(rules, fn rule ->
      case rule do
        :action_type_transitions ->
          create_action_transition_bridges(intervals)

        :resource_changes ->
          create_resource_change_bridges(intervals)

        :phase_boundaries ->
          create_phase_boundary_bridges(intervals)

        :decision_points ->
          create_decision_point_bridges(intervals)

        _ ->
          []
      end
    end)
    |> Enum.uniq_by(& &1.id)
  end

  defp create_action_transition_bridges(intervals) do
    intervals
    |> Enum.sort_by(& &1.start_time, DateTime)
    |> Enum.chunk_every(2, 1, :discard)
    |> Enum.with_index()
    |> Enum.filter(fn {[interval1, interval2], _index} ->
      type1 = get_interval_action_type(interval1)
      type2 = get_interval_action_type(interval2)
      type1 != type2
    end)
    |> Enum.map(fn {[interval1, interval2], index} ->
      bridge_time = DateTime.add(interval1.end_time, 1, :second)
      bridge_id = "transition_#{index}"

      Bridge.new(bridge_id, bridge_time, :decision, %{
        from_action: interval1.id,
        to_action: interval2.id,
        rule: :action_type_transitions
      })
    end)
  end

  defp create_resource_change_bridges(intervals) do
    intervals
    |> Enum.sort_by(& &1.start_time, DateTime)
    |> Enum.chunk_every(2, 1, :discard)
    |> Enum.with_index()
    |> Enum.filter(fn {[interval1, interval2], _index} ->
      resources1 = get_interval_resources(interval1)
      resources2 = get_interval_resources(interval2)
      resources1 != resources2
    end)
    |> Enum.map(fn {[interval1, interval2], index} ->
      bridge_time = DateTime.add(interval1.end_time, 500, :millisecond)
      bridge_id = "resource_check_#{index}"

      Bridge.new(bridge_id, bridge_time, :resource_check, %{
        from_action: interval1.id,
        to_action: interval2.id,
        rule: :resource_changes
      })
    end)
  end

  defp create_phase_boundary_bridges(intervals) do
    intervals
    |> Enum.group_by(&get_interval_phase/1)
    |> Enum.flat_map(fn {phase, phase_intervals} ->
      case phase_intervals do
        [] ->
          []

        _ ->
          phase_end_time =
            phase_intervals
            |> Enum.map(& &1.end_time)
            |> Enum.max(DateTime)

          bridge_id = "phase_#{phase}_end"

          [
            Bridge.new(bridge_id, phase_end_time, :synchronization, %{
              phase: phase,
              rule: :phase_boundaries
            })
          ]
      end
    end)
  end

  defp create_decision_point_bridges(intervals) do
    intervals
    |> Enum.filter(&has_decision_metadata?/1)
    |> Enum.with_index()
    |> Enum.map(fn {interval, index} ->
      bridge_id = "decision_#{index}"

      Bridge.new(bridge_id, interval.start_time, :decision, %{
        action: interval.id,
        rule: :decision_points
      })
    end)
  end

  defp get_interval_action_type(%Interval{metadata: metadata}) do
    Map.get(metadata, :action_type, :default)
  end

  defp get_interval_resources(%Interval{metadata: metadata}) do
    Map.get(metadata, :resources, [])
  end

  defp get_interval_phase(%Interval{metadata: metadata}) do
    Map.get(metadata, :phase, :default)
  end

  defp has_decision_metadata?(%Interval{metadata: metadata}) do
    Map.get(metadata, :has_decision, false) or
      Map.get(metadata, :decision_point, false)
  end

  defp get_phase_end_time(intervals) when is_list(intervals) do
    case intervals do
      [] -> DateTime.utc_now()
      _ ->
        intervals
        |> Enum.map(& &1.end_time)
        |> Enum.max(DateTime)
    end
  end
end
