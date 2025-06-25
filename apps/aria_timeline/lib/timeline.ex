# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule Timeline do
  @moduledoc "Timeline module with interval-based storage using Path Consistency (PC-2) algorithm\nfor Simple Temporal Network (STN) solving.\n\nAccepts time input in seconds but solves at 1ms tick precision.\nSupports Allen's interval algebra with usability improvements.\nRespects agent vs entity distinction in temporal constraints.\n\n## Time Representation\n- External API: seconds (float/integer)\n- Internal storage/solving: milliseconds (integer)\n- Precision: 1ms ticks as per ADR-006\n\n## Features\n- All 13 Allen interval relations\n- Path Consistency (PC-2) STN solving\n- Agent/entity distinction\n- Fluent API for constraint building\n- Comprehensive edge case handling\n\n## Bridge Conversion in Timeline Operations\n\nWhen chaining timelines using `Timeline.chain/1`, all bridges are automatically\npreserved through a sophisticated conversion process that ensures no temporal\ncoordination points are lost.\n\n### Universal Bridge Conversion\n\n**Every absolute position bridge can be converted to a semantic bridge.** The\nconversion process handles all possible scenarios:\n\n1. **Timeline-relative positioning**: Bridges positioned relative to timeline bounds\n2. **Interval-relative positioning**: Bridges positioned within or adjacent to intervals\n3. **Boundary detection**: Precision-aware tolerance based on STN configuration\n4. **Fallback strategy**: `:during` relation as universal fallback for edge cases\n\n### Conversion Algorithm\n\nThe conversion follows this systematic approach:\n\n```\n1. Analyze bridge position relative to timeline bounds\n2. Determine if bridge is:\n   - At timeline start (±tolerance) → :starts\n   - At timeline end (±tolerance) → :finishes\n   - Before timeline → :before\n   - After timeline → :after\n   - Within timeline → analyze interval relationships\n3. For bridges within timeline:\n   - Check if within any interval → :during\n   - Check if adjacent to interval boundary → :meets\n   - Default to :during for inter-interval positions\n```\n\n### Precision-Aware Tolerance System\n\nThe boundary detection tolerance is dynamically calculated based on the Timeline's\nSTN configuration, ensuring appropriate precision for different use cases:\n\n**Tolerance Calculation:**\n```\ntolerance_microseconds = base_unit_microseconds * lod_resolution\n```\n\n**Precision Examples:**\n- Ultra-high precision (microsecond, LOD 1): 1 microsecond tolerance\n- High precision (millisecond, LOD 10): 10 millisecond tolerance\n- Medium precision (second, LOD 100): 100 second tolerance\n- Low precision (minute, LOD 1000): 1000 minute tolerance\n- Very-low precision (day, LOD 10000): 10000 day tolerance\n\n### Semantic Relation Mapping\n\n| Bridge Position | Semantic Relation | Description |\n|----------------|-------------------|-------------|\n| Timeline start (±tolerance) | `:starts` | Bridge at timeline beginning |\n| Timeline end (±tolerance) | `:finishes` | Bridge at timeline conclusion |\n| Before timeline | `:before` | Bridge precedes timeline |\n| After timeline | `:after` | Bridge follows timeline |\n| Within interval | `:during` | Bridge during interval execution |\n| At interval boundary | `:meets` | Bridge at interval transition |\n| Between intervals | `:during` | Bridge in inter-interval space |\n\n### Edge Case Handling\n\nThe conversion process handles all edge cases:\n\n- **Empty timelines**: Uses default bounds (current time + 1 hour)\n- **Single intervals**: Positions relative to interval bounds\n- **Overlapping intervals**: Uses earliest start and latest end\n- **Invalid positions**: Graceful fallback to `:during` relation\n- **Boundary precision**: Precision-aware tolerance based on STN configuration\n\n### Preservation Guarantee\n\n**No bridges are ever lost during timeline operations.** The `chain/1` function:\n\n1. Converts all absolute position bridges to semantic bridges\n2. Preserves all existing semantic bridges unchanged\n3. Filters out only unconvertible bridges (none exist in practice)\n4. Maintains bridge metadata and positioning information\n\n### Mathematical Foundation\n\nThe conversion is based on Allen's Interval Algebra, ensuring that temporal\nrelationships maintain their semantic meaning across timeline operations.\nEach converted bridge represents a valid Allen relation that preserves the\noriginal temporal coordination intent.\n\n## Examples\n\n    iex> timeline = Timeline.new()\n    iex> alias Timeline.Interval\n    iex> start_time = DateTime.from_naive!(~N[2025-01-01 10:00:00], \"Etc/UTC\")\n    iex> end_time = DateTime.from_naive!(~N[2025-01-01 12:00:00], \"Etc/UTC\")\n    iex> interval = Interval.new(start_time, end_time)\n    iex> timeline = Timeline.add_interval(timeline, interval)\n    iex> length(Map.keys(timeline.intervals))\n    1\n\n## References\n\n- ADR-078: Timeline Module PC-2 STN Implementation\n- ADR-079: Timeline Module Implementation Progress\n- ADR-045: Allen's Interval Algebra Temporal Relationships\n- ADR-040: Temporal Constraint Solver Selection\n- ADR-046: Interval Notation Usability\n- ADR-006: Game Engine Real-time Execution (1ms tick requirement)\n"
  alias Timeline.Interval
  alias Timeline.Internal.STN
  alias Timeline.Bridge

  # Type definitions
  @type t :: %__MODULE__{
          intervals: %{Interval.id() => Interval.t()},
          stn: STN.t(),
          metadata: map()
        }

  @type bridge_rule :: :action_type_transitions | :resource_changes | :phase_boundaries | :decision_points
  @type segment_info :: %{
          start_time: DateTime.t() | nil,
          end_time: DateTime.t() | nil,
          intervals: [Interval.t()]
        }

  defstruct intervals: %{}, stn: STN.new(), metadata: %{}
  @spec new(keyword()) :: t()
  def new(opts \\ []) do
    intervals = Keyword.get(opts, :intervals, [])
    metadata = Keyword.get(opts, :metadata, %{})
    %__MODULE__{metadata: metadata} |> add_intervals(intervals)
  end

  @spec add_interval(t(), Interval.t()) :: t()
  def add_interval(%__MODULE__{} = timeline, interval) do
    # Use Bridge layer to validate interval before adding to STN
    case Bridge.validate_interval_for_stn(interval, timeline.stn.time_unit) do
      :ok ->
        stn = timeline.stn |> STN.add_interval(interval)

        timeline
        |> Map.put(:intervals, Map.put(timeline.intervals, interval.id, interval))
        |> Map.put(:stn, stn)

      {:error, reason} ->
        require Logger
        Logger.warning("Skipping invalid interval #{interval.id}: #{reason}")
        timeline
    end
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
    # Use Bridge layer to validate interval before updating in STN
    case Bridge.validate_interval_for_stn(interval, timeline.stn.time_unit) do
      :ok ->
        stn = STN.update_interval(timeline.stn, interval)

        timeline
        |> Map.put(:intervals, Map.put(timeline.intervals, interval.id, interval))
        |> Map.put(:stn, stn)

      {:error, reason} ->
        require Logger
        Logger.warning("Skipping invalid interval update #{interval.id}: #{reason}")
        timeline
    end
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

  @spec solve(t()) :: t() | {:error, :unsatisfiable}
  def solve(timeline) do
    require Logger

    case STN.solve(timeline.stn) do
      {:error, :unsatisfiable} = error ->
        error

      stn ->
        updated_timeline = %{timeline | stn: stn}

        case Map.get(stn.metadata, :solved_times) do
          nil ->
            updated_timeline

          solved_times ->
            result = apply_solved_times_to_intervals(updated_timeline, solved_times)
            result
        end
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
  @spec consistent?(t() | {:error, :unsatisfiable}) :: boolean()
  def consistent?({:error, :unsatisfiable}), do: false
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
    solved_stn = case AriaMinizincStn.solve_stn(timeline.stn) do
      {:ok, stn} -> stn
      stn -> stn
    end
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

  @doc """
  Chains multiple Timelines sequentially with automatic bridge conversion.

  Returns a Timeline where the Timelines are executed in sequence. All bridges
  are automatically preserved through a sophisticated conversion process that
  ensures no temporal coordination points are lost.

  ## Bridge Conversion Process

  The chaining operation performs the following steps:

  1. **Identify all bridges** from input timelines
  2. **Convert absolute position bridges** to semantic bridges using Allen relations
  3. **Preserve all semantic bridges** (both original and converted)
  4. **Merge timeline metadata** while maintaining bridge information

  ## Conversion Algorithm Details

  For each absolute position bridge (semantic_relation: nil):

  1. **Analyze timeline bounds** to determine relative positioning
  2. **Apply boundary detection** with precision-aware tolerance
  3. **Compute semantic relation** based on position analysis:
     - Timeline start (±tolerance) → `:starts`
     - Timeline end (±tolerance) → `:finishes`
     - Before timeline → `:before`
     - After timeline → `:after`
     - Within timeline → analyze interval relationships
  4. **Set reference target** to "timeline" for converted bridges
  5. **Preserve original position** as computed_position

  ## Interval-Based Positioning

  For bridges positioned within timeline bounds:

  - **Within any interval** → `:during` relation
  - **Adjacent to interval boundary** (±tolerance) → `:meets` relation
  - **Between intervals** → `:during` relation (default)

  ## Conversion Guarantee

  **Every absolute position bridge is successfully converted.** The algorithm
  handles all edge cases:

  - Empty timelines use default bounds (current time + 1 hour)
  - Invalid positions gracefully fall back to `:during` relation
  - Boundary detection uses precision-aware tolerance based on STN configuration
  - All converted bridges maintain their original temporal intent

  ## Examples

      # Bridge at timeline start gets converted to :starts
      bridge = Bridge.new("start_bridge", timeline_start_time, :decision)
      chained = Timeline.chain([timeline_with_bridge])
      converted_bridge = Timeline.get_bridge(chained, "start_bridge")
      converted_bridge.semantic_relation  # => :starts

      # Bridge during timeline gets converted to :during
      bridge = Bridge.new("mid_bridge", mid_timeline_time, :decision)
      chained = Timeline.chain([timeline_with_bridge])
      converted_bridge = Timeline.get_bridge(chained, "mid_bridge")
      converted_bridge.semantic_relation  # => :during

  ## Returns

  Timeline with all bridges preserved as semantic bridges, maintaining temporal
  coordination points across the chained sequence.
  """
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

    # Convert absolute position bridges to semantic bridges, then preserve all semantic bridges
    preserved_bridges = timelines
    |> Enum.flat_map(fn timeline ->
      timeline.metadata
      |> Map.get(:bridges, %{})
      |> Map.values()
      |> Enum.map(&convert_to_semantic_bridge(timeline, &1))
      |> Enum.filter(&is_semantic_bridge?/1)
    end)
    |> Enum.map(&{&1.id, &1})
    |> Map.new()

    # Don't merge absolute position bridge metadata when chaining - only preserve semantic bridges
    base_metadata = timelines
    |> Enum.map(& &1.metadata)
    |> Enum.reduce(%{}, fn metadata, acc ->
      metadata
      |> Map.delete(:bridges)
      |> then(&Map.merge(acc, &1))
    end)
    |> Map.put(:bridges, preserved_bridges)

    %__MODULE__{intervals: merged_intervals, stn: chained_stn, metadata: base_metadata}
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

  # Bridge management functions
  @doc "Adds a bridge to the timeline.\n"
  @spec add_bridge(t(), Bridge.t()) :: t()
  def add_bridge(%__MODULE__{} = timeline, bridge) do
    # Compute semantic position if needed
    bridge_with_position = case bridge.semantic_relation do
      nil -> bridge
      _semantic -> compute_semantic_position(timeline, bridge)
    end

    case validate_bridge_placement(timeline, bridge_with_position) do
      :ok ->
        bridges = Map.get(timeline.metadata, :bridges, %{})
        updated_bridges = Map.put(bridges, bridge_with_position.id, bridge_with_position)
        put_in(timeline.metadata[:bridges], updated_bridges)

      {:error, reason} ->
        raise ArgumentError, reason
    end
  end

  @doc """
  Add a bridge with semantic positioning relative to timeline.

  ## Examples

      iex> timeline = Timeline.new()
      iex> timeline = Timeline.add_semantic_bridge(timeline, :starts, "start_check", :decision)
      iex> bridge = Timeline.get_bridge(timeline, "start_check")
      iex> bridge.semantic_relation
      :starts

  """
  @spec add_semantic_bridge(t(), Bridge.semantic_position(), String.t(), Bridge.bridge_type(), keyword()) :: t()
  def add_semantic_bridge(timeline, relation, bridge_id, bridge_type, opts \\ []) do
    bridge = Bridge.new_semantic(bridge_id, relation, "timeline", bridge_type, opts)
    add_bridge(timeline, bridge)
  end

  @doc """
  Add a bridge with semantic positioning relative to specific interval.

  ## Examples

      iex> timeline = Timeline.new()
      iex> alias Timeline.Interval
      iex> start_time = DateTime.from_naive!(~N[2025-01-01 10:00:00], "Etc/UTC")
      iex> end_time = DateTime.from_naive!(~N[2025-01-01 12:00:00], "Etc/UTC")
      iex> interval = %Interval{id: "interval_1", start_time: start_time, end_time: end_time}
      iex> timeline = Timeline.add_interval(timeline, interval)
      iex> timeline = Timeline.add_interval_bridge(timeline, :starts, "interval_1", "task_start", :synchronization)
      iex> bridge = Timeline.get_bridge(timeline, "task_start")
      iex> bridge.reference_target
      "interval_1"

  """
  @spec add_interval_bridge(t(), Bridge.semantic_position(), String.t(), String.t(), Bridge.bridge_type()) :: t()
  def add_interval_bridge(timeline, relation, interval_id, bridge_id, bridge_type) do
    bridge = Bridge.new_semantic(bridge_id, relation, interval_id, bridge_type)
    add_bridge(timeline, bridge)
  end

  # Fluent API for common semantic bridges
  @doc "Add a bridge at timeline start."
  @spec add_bridge_at_start(t(), String.t(), Bridge.bridge_type()) :: t()
  def add_bridge_at_start(timeline, bridge_id, type \\ :synchronization) do
    add_semantic_bridge(timeline, :starts, bridge_id, type)
  end

  @doc "Add a bridge at timeline end."
  @spec add_bridge_at_end(t(), String.t(), Bridge.bridge_type()) :: t()
  def add_bridge_at_end(timeline, bridge_id, type \\ :synchronization) do
    add_semantic_bridge(timeline, :finishes, bridge_id, type)
  end

  @doc "Add a bridge for chaining (at timeline end)."
  @spec add_bridge_for_chaining(t(), String.t()) :: t()
  def add_bridge_for_chaining(timeline, bridge_id) do
    add_semantic_bridge(timeline, :meets, bridge_id, :synchronization)
  end

  @doc "Add a bridge during timeline execution."
  @spec add_bridge_during(t(), String.t(), Bridge.bridge_type()) :: t()
  def add_bridge_during(timeline, bridge_id, type \\ :decision) do
    add_semantic_bridge(timeline, :during, bridge_id, type)
  end

  @doc "Add a bridge at interval start."
  @spec add_interval_start_bridge(t(), String.t(), String.t()) :: t()
  def add_interval_start_bridge(timeline, interval_id, bridge_id) do
    add_interval_bridge(timeline, :starts, interval_id, bridge_id, :synchronization)
  end

  @doc "Add a bridge at interval end."
  @spec add_interval_end_bridge(t(), String.t(), String.t()) :: t()
  def add_interval_end_bridge(timeline, interval_id, bridge_id) do
    add_interval_bridge(timeline, :finishes, interval_id, bridge_id, :synchronization)
  end

  @doc "Removes a bridge from the timeline.\n"
  @spec remove_bridge(t(), String.t()) :: t()
  def remove_bridge(%__MODULE__{} = timeline, bridge_id) do
    bridges = Map.get(timeline.metadata, :bridges, %{})
    updated_bridges = Map.delete(bridges, bridge_id)
    put_in(timeline.metadata[:bridges], updated_bridges)
  end

  @doc "Gets a bridge by ID from the timeline.\n"
  @spec get_bridge(t(), String.t()) :: Bridge.t() | nil
  def get_bridge(%__MODULE__{} = timeline, bridge_id) do
    bridges = Map.get(timeline.metadata, :bridges, %{})
    Map.get(bridges, bridge_id)
  end

  @doc "Gets all bridges from the timeline, sorted by position.\n"
  @spec get_bridges(t()) :: [Bridge.t()]
  def get_bridges(%__MODULE__{} = timeline) do
    bridges = Map.get(timeline.metadata, :bridges, %{})
    bridges
    |> Map.values()
    |> Enum.sort_by(& &1.position, DateTime)
  end

  @doc "Updates a bridge in the timeline.\n"
  @spec update_bridge(t(), Bridge.t()) :: t()
  def update_bridge(%__MODULE__{} = timeline, bridge) do
    bridges = Map.get(timeline.metadata, :bridges, %{})
    updated_bridges = Map.put(bridges, bridge.id, bridge)
    put_in(timeline.metadata[:bridges], updated_bridges)
  end

  @doc "Validates bridge placement in the timeline.\n"
  @spec validate_bridge_placement(t(), Bridge.t()) :: :ok | {:error, String.t()}
  def validate_bridge_placement(%__MODULE__{} = timeline, bridge) do
    bridges = Map.get(timeline.metadata, :bridges, %{})

    cond do
      Map.has_key?(bridges, bridge.id) ->
        {:error, "Bridge with ID '#{bridge.id}' already exists"}

      # Only check boundary conflicts for absolute position bridges
      # Semantic bridges are allowed at boundaries by design
      bridge.semantic_relation == nil and bridge_at_interval_boundary?(timeline, bridge) ->
        {:error, "Bridge cannot be placed at interval boundary"}

      true ->
        :ok
    end
  end

  @doc "Segments the timeline by bridges.\n"
  @spec segment_by_bridges(t()) :: [map()]
  def segment_by_bridges(%__MODULE__{} = timeline) do
    bridges = get_bridges(timeline)
    intervals = Map.values(timeline.intervals)

    case bridges do
      [] ->
        # Single segment with proper metadata structure
        intervals_map = intervals |> Enum.map(&{&1.id, &1}) |> Map.new()
        [%{
          start_time: nil,
          end_time: nil,
          intervals: intervals_map,
          metadata: %{segment: 1, bridge_before: nil}
        }]

      _ ->
        create_segments_from_bridges(bridges, intervals)
    end
  end

  @doc "Gets all bridge positions from the timeline, sorted.\n"
  @spec bridge_positions(t()) :: [String.t()]
  def bridge_positions(%__MODULE__{} = timeline) do
    timeline
    |> get_bridges()
    |> Enum.map(&DateTime.to_iso8601(&1.position))
    |> Enum.sort()
  end

  @doc "Gets bridges within a time range.\n"
  @spec bridges_in_range(t(), DateTime.t() | String.t(), DateTime.t() | String.t()) :: [Bridge.t()]
  def bridges_in_range(%__MODULE__{} = timeline, start_time, end_time) do
    start_dt = parse_datetime_param(start_time)
    end_dt = parse_datetime_param(end_time)

    timeline
    |> get_bridges()
    |> Enum.filter(fn bridge ->
      DateTime.compare(bridge.position, start_dt) != :lt and
      DateTime.compare(bridge.position, end_dt) != :gt
    end)
  end

  # Private helper functions for bridge management
  defp bridge_at_interval_boundary?(%__MODULE__{} = timeline, bridge) do
    timeline.intervals
    |> Map.values()
    |> Enum.any?(fn interval ->
      DateTime.compare(bridge.position, interval.start_time) == :eq or
      DateTime.compare(bridge.position, interval.end_time) == :eq
    end)
  end

  defp create_segments_from_bridges(bridges, intervals) do
    bridge_positions = Enum.map(bridges, & &1.position)

    # Create segments between bridges
    segments =
      [nil | bridge_positions] ++ [nil]
      |> Enum.chunk_every(2, 1, :discard)
      |> Enum.with_index(1)
      |> Enum.map(fn {[start_pos, end_pos], segment_num} ->
        segment_intervals = filter_intervals_by_range(intervals, start_pos, end_pos)
        intervals_map = segment_intervals |> Enum.map(&{&1.id, &1}) |> Map.new()

        bridge_before = case start_pos do
          nil -> nil
          pos -> DateTime.to_iso8601(pos)
        end

        %{
          start_time: start_pos,
          end_time: end_pos,
          intervals: intervals_map,
          metadata: %{
            segment: segment_num,
            bridge_before: bridge_before
          }
        }
      end)
      |> Enum.reject(fn segment -> map_size(segment.intervals) == 0 end)

    segments
  end

  defp filter_intervals_by_range(intervals, start_pos, end_pos) do
    Enum.filter(intervals, fn interval ->
      # Include interval if it overlaps with the segment range
      case {start_pos, end_pos} do
        {nil, nil} ->
          # No boundaries, include all intervals
          true
        {nil, end_pos} ->
          # Only end boundary, include if interval starts before end
          DateTime.compare(interval.start_time, end_pos) == :lt
        {start_pos, nil} ->
          # Only start boundary, include if interval ends after start
          DateTime.compare(interval.end_time, start_pos) == :gt
        {start_pos, end_pos} ->
          # Both boundaries, include if interval overlaps with range
          interval_starts_before_end = DateTime.compare(interval.start_time, end_pos) == :lt
          interval_ends_after_start = DateTime.compare(interval.end_time, start_pos) == :gt
          interval_starts_before_end and interval_ends_after_start
      end
    end)
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

  # ==================== MISSING FUNCTIONS IMPLEMENTATION ====================

  @doc """
  Automatically insert bridges into the timeline based on rules.

  This function analyzes the timeline and automatically inserts bridges at
  strategic points based on the provided rules. Bridge insertion follows
  mathematical principles of temporal segmentation and decision point detection.

  ## Parameters
  - `timeline`: The timeline to analyze and enhance with bridges
  - `rules`: List of bridge insertion rules to apply

  ## Rules
  - `:action_type_transitions` - Insert bridges between different action types
  - `:resource_changes` - Insert bridges when resource usage changes
  - `:phase_boundaries` - Insert bridges at logical phase transitions
  - `:decision_points` - Insert bridges at decision/branching points

  ## Returns
  Timeline with automatically inserted bridges based on the rules.
  """
  @spec auto_insert_bridges(t(), [bridge_rule()]) :: t()
  def auto_insert_bridges(%__MODULE__{} = timeline, rules) when is_list(rules) do
    intervals = Map.values(timeline.intervals)

    # Sort intervals by start time for temporal analysis
    sorted_intervals = Enum.sort_by(intervals, & &1.start_time, DateTime)

    # Generate bridge candidates based on rules
    bridge_candidates =
      rules
      |> Enum.flat_map(fn rule -> generate_bridges_for_rule(sorted_intervals, rule) end)
      |> Enum.uniq_by(& &1.id)
      |> Enum.sort_by(& &1.position, DateTime)

    # Insert valid bridges into timeline
    Enum.reduce(bridge_candidates, timeline, fn bridge, acc_timeline ->
      case validate_bridge_placement(acc_timeline, bridge) do
        :ok -> add_bridge(acc_timeline, bridge)
        {:error, _reason} -> acc_timeline  # Skip invalid bridges
      end
    end)
  end

  @doc """
  Apply bridge segmentation to the timeline.

  This function takes a timeline and applies bridge-based segmentation,
  creating logical segments separated by bridges. This is mathematically
  equivalent to partitioning the timeline into disjoint temporal segments.

  ## Parameters
  - `timeline`: The timeline to segment

  ## Returns
  Timeline with bridge segmentation applied and segment metadata updated.
  """
  @spec with_bridge_segmentation(t()) :: t()
  def with_bridge_segmentation(%__MODULE__{} = timeline) do
    # Get existing bridges or create default segmentation bridges
    bridges = get_bridges(timeline)

    enhanced_timeline = case bridges do
      [] ->
        # No bridges exist, create default segmentation based on interval analysis
        create_default_segmentation_bridges(timeline)
      _ ->
        # Bridges exist, ensure proper segmentation
        timeline
    end

    # Apply segmentation metadata
    segments = segment_by_bridges(enhanced_timeline)
    segmentation_metadata = %{
      segmentation_applied: true,
      segment_count: length(segments),
      segmentation_timestamp: DateTime.utc_now(),
      segmentation_method: :bridge_based
    }

    # Update timeline metadata with segmentation info
    updated_metadata = Map.merge(enhanced_timeline.metadata, segmentation_metadata)
    %{enhanced_timeline | metadata: updated_metadata}
  end

  @doc """
  Validate all bridge placements in the timeline.

  This function performs comprehensive validation of all bridges in the timeline,
  ensuring they satisfy temporal consistency, placement rules, and mathematical
  constraints for proper timeline segmentation.

  ## Parameters
  - `timeline`: The timeline containing bridges to validate

  ## Returns
  - `:ok` if all bridges are valid
  - `{:error, reason}` if any bridge placement is invalid
  """
  @spec validate_all_bridge_placements(t()) :: :ok | {:error, String.t()}
  def validate_all_bridge_placements(%__MODULE__{} = timeline) do
    bridges = get_bridges(timeline)

    case bridges do
      [] ->
        :ok  # No bridges means trivially valid

      _ ->
        # Validate each bridge and check for conflicts
        validation_results = Enum.map(bridges, &validate_bridge_placement(timeline, &1))

        case Enum.find(validation_results, &match?({:error, _}, &1)) do
          nil ->
            # All individual bridges are valid, check for bridge conflicts
            validate_bridge_conflicts(bridges)

          {:error, reason} ->
            {:error, reason}
        end
    end
  end

  # ==================== PRIVATE HELPER FUNCTIONS FOR MISSING FUNCTIONS ====================

  # Generate bridges based on specific rules
  defp generate_bridges_for_rule(intervals, rule) do
    case rule do
      :action_type_transitions ->
        generate_action_type_transition_bridges(intervals)

      :resource_changes ->
        generate_resource_change_bridges(intervals)

      :phase_boundaries ->
        generate_phase_boundary_bridges(intervals)

      :decision_points ->
        generate_decision_point_bridges(intervals)

      _ ->
        []
    end
  end

  # Generate bridges at action type transitions
  defp generate_action_type_transition_bridges(intervals) do
    intervals
    |> Enum.chunk_every(2, 1, :discard)
    |> Enum.with_index()
    |> Enum.filter(fn {[current, next], _index} ->
      get_action_type(current) != get_action_type(next)
    end)
    |> Enum.map(fn {[current, _next], index} ->
      %Timeline.Bridge{
        id: "action_transition_#{index}",
        position: current.end_time,
        type: :decision,
        metadata: %{
          rule: :action_type_transitions,
          from_action: current.id,
          from_type: get_action_type(current)
        }
      }
    end)
  end

  # Generate bridges at resource changes
  defp generate_resource_change_bridges(intervals) do
    intervals
    |> Enum.chunk_every(2, 1, :discard)
    |> Enum.with_index()
    |> Enum.filter(fn {[current, next], _index} ->
      get_resource_usage(current) != get_resource_usage(next)
    end)
    |> Enum.map(fn {[current, _next], index} ->
      %Timeline.Bridge{
        id: "resource_change_#{index}",
        position: current.end_time,
        type: :resource_check,
        metadata: %{
          rule: :resource_changes,
          from_resources: get_resource_usage(current),
          transition_point: true
        }
      }
    end)
  end

  # Generate bridges at phase boundaries
  defp generate_phase_boundary_bridges(intervals) do
    # Detect phase boundaries based on temporal clustering
    phase_boundaries = detect_phase_boundaries(intervals)

    phase_boundaries
    |> Enum.with_index()
    |> Enum.map(fn {boundary_time, index} ->
      %Timeline.Bridge{
        id: "phase_boundary_#{index}",
        position: boundary_time,
        type: :synchronization,
        metadata: %{
          rule: :phase_boundaries,
          boundary_type: :temporal_cluster
        }
      }
    end)
  end

  # Generate bridges at decision points
  defp generate_decision_point_bridges(intervals) do
    # Identify decision points where multiple intervals could start
    decision_points = identify_decision_points(intervals)

    decision_points
    |> Enum.with_index()
    |> Enum.map(fn {decision_time, index} ->
      %Timeline.Bridge{
        id: "decision_point_#{index}",
        position: decision_time,
        type: :decision,
        metadata: %{
          rule: :decision_points,
          decision_type: :branching_point
        }
      }
    end)
  end

  # Create default segmentation bridges when none exist
  defp create_default_segmentation_bridges(timeline) do
    intervals = Map.values(timeline.intervals)

    case intervals do
      [] ->
        timeline  # No intervals, no segmentation needed

      _ ->
        # Create bridges at natural segmentation points
        sorted_intervals = Enum.sort_by(intervals, & &1.start_time, DateTime)
        midpoint_bridges = create_midpoint_bridges(sorted_intervals)

        Enum.reduce(midpoint_bridges, timeline, &add_bridge(&2, &1))
    end
  end

  # Create bridges at interval midpoints for default segmentation
  defp create_midpoint_bridges(intervals) do
    case length(intervals) do
      n when n <= 2 ->
        []  # Too few intervals for meaningful segmentation

      n ->
        # Create bridges at quartile points for balanced segmentation
        quartile_indices = [div(n, 4), div(n, 2), div(3 * n, 4)]

        quartile_indices
        |> Enum.with_index()
        |> Enum.map(fn {interval_index, bridge_index} ->
          interval = Enum.at(intervals, interval_index)
          midpoint_time = calculate_interval_midpoint(interval)

          %Timeline.Bridge{
            id: "default_segment_#{bridge_index}",
            position: midpoint_time,
            type: :synchronization,
            metadata: %{
              segmentation_method: :default_quartiles,
              interval_index: interval_index
            }
          }
        end)
    end
  end

  # Validate bridge conflicts (overlapping or contradictory bridges)
  defp validate_bridge_conflicts(bridges) do
    # Sort bridges by position for conflict detection
    sorted_bridges = Enum.sort_by(bridges, & &1.position, DateTime)

    # Check for bridges that are too close together
    conflicts =
      sorted_bridges
      |> Enum.chunk_every(2, 1, :discard)
      |> Enum.find(fn [bridge1, bridge2] ->
        time_diff = DateTime.diff(bridge2.position, bridge1.position, :millisecond)
        time_diff < 1000  # Bridges must be at least 1 second apart
      end)

    case conflicts do
      nil ->
        :ok

      [bridge1, bridge2] ->
        {:error, "Bridge conflict: '#{bridge1.id}' and '#{bridge2.id}' are too close together"}
    end
  end

  # Helper functions for bridge generation
  defp get_action_type(interval) do
    interval.metadata
    |> Map.get(:action_type, :default)
  end

  defp get_resource_usage(interval) do
    interval.metadata
    |> Map.get(:resources, [])
    |> Enum.sort()
  end

  defp detect_phase_boundaries(intervals) do
    # Simple phase boundary detection based on temporal gaps
    intervals
    |> Enum.sort_by(& &1.start_time, DateTime)
    |> Enum.chunk_every(2, 1, :discard)
    |> Enum.filter(fn [current, next] ->
      gap = DateTime.diff(next.start_time, current.end_time, :millisecond)
      gap > 5000  # Gaps larger than 5 seconds indicate phase boundaries
    end)
    |> Enum.map(fn [current, _next] -> current.end_time end)
  end

  defp identify_decision_points(intervals) do
    # Identify points where multiple intervals could potentially start
    start_times = Enum.map(intervals, & &1.start_time)

    start_times
    |> Enum.frequencies()
    |> Enum.filter(fn {_time, count} -> count > 1 end)
    |> Enum.map(fn {time, _count} -> time end)
  end

  defp calculate_interval_midpoint(interval) do
    start_ms = DateTime.to_unix(interval.start_time, :millisecond)
    end_ms = DateTime.to_unix(interval.end_time, :millisecond)
    midpoint_ms = div(start_ms + end_ms, 2)

    DateTime.from_unix!(midpoint_ms, :millisecond)
  end

  # Helper function to parse DateTime parameters
  defp parse_datetime_param(%DateTime{} = datetime), do: datetime
  defp parse_datetime_param(iso8601_string) when is_binary(iso8601_string) do
    {:ok, datetime, _} = DateTime.from_iso8601(iso8601_string)
    datetime
  end

  # Semantic position computation
  defp compute_semantic_position(timeline, %Bridge{semantic_relation: relation, reference_target: target} = bridge) do
    case target do
      "timeline" ->
        compute_timeline_semantic_position(timeline, bridge, relation)
      interval_id when is_binary(interval_id) ->
        compute_interval_semantic_position(timeline, bridge, relation, interval_id)
    end
  end

  defp compute_timeline_semantic_position(timeline, bridge, relation) do
    {start_time, end_time} = get_timeline_bounds(timeline)

    computed_position = case relation do
      :starts -> start_time
      :finishes -> end_time
      :meets -> end_time  # For chaining - at boundary
      :met_by -> start_time  # For chaining - at boundary
      :during -> compute_during_position(start_time, end_time)
      :contains -> compute_contains_position(start_time, end_time)
      :overlaps -> compute_near_end_position(start_time, end_time)
      :overlapped_by -> compute_near_start_position(start_time, end_time)
      :before -> DateTime.add(start_time, -300, :second)  # 5 min before
      :after -> DateTime.add(end_time, 300, :second)  # 5 min after
      :equals -> compute_midpoint(start_time, end_time)
    end

    %{bridge | computed_position: computed_position, position: computed_position}
  end

  defp compute_interval_semantic_position(timeline, bridge, relation, interval_id) do
    case get_interval(timeline, interval_id) do
      nil ->
        raise ArgumentError, "Interval #{interval_id} not found"
      interval ->
        computed_position = case relation do
          :starts -> interval.start_time
          :finishes -> interval.end_time
          :meets -> interval.end_time
          :met_by -> interval.start_time
          :during -> compute_during_position(interval.start_time, interval.end_time)
          :contains -> compute_contains_position(interval.start_time, interval.end_time)
          :overlaps -> compute_near_end_position(interval.start_time, interval.end_time)
          :overlapped_by -> compute_near_start_position(interval.start_time, interval.end_time)
          :before -> DateTime.add(interval.start_time, -300, :second)
          :after -> DateTime.add(interval.end_time, 300, :second)
          :equals -> compute_midpoint(interval.start_time, interval.end_time)
        end

        %{bridge | computed_position: computed_position, position: computed_position}
    end
  end

  defp get_timeline_bounds(timeline) do
    intervals = Map.values(timeline.intervals)
    case intervals do
      [] ->
        # Default timeline bounds if no intervals
        now = DateTime.utc_now()
        {now, DateTime.add(now, 3600, :second)}  # 1 hour default
      _ ->
        start_times = Enum.map(intervals, & &1.start_time)
        end_times = Enum.map(intervals, & &1.end_time)
        {Enum.min(start_times, DateTime), Enum.max(end_times, DateTime)}
    end
  end

  defp compute_during_position(start_time, end_time) do
    # Random position within the interval (30-70% range)
    start_ms = DateTime.to_unix(start_time, :millisecond)
    end_ms = DateTime.to_unix(end_time, :millisecond)
    duration_ms = end_ms - start_ms
    offset_ms = start_ms + div(duration_ms * (30 + :rand.uniform(40)), 100)
    DateTime.from_unix!(offset_ms, :millisecond)
  end

  defp compute_contains_position(start_time, end_time) do
    # Midpoint for contains relation
    compute_midpoint(start_time, end_time)
  end

  defp compute_near_end_position(start_time, end_time) do
    # 80-90% through the interval
    start_ms = DateTime.to_unix(start_time, :millisecond)
    end_ms = DateTime.to_unix(end_time, :millisecond)
    duration_ms = end_ms - start_ms
    offset_ms = start_ms + div(duration_ms * (80 + :rand.uniform(10)), 100)
    DateTime.from_unix!(offset_ms, :millisecond)
  end

  defp compute_near_start_position(start_time, end_time) do
    # 10-20% through the interval
    start_ms = DateTime.to_unix(start_time, :millisecond)
    end_ms = DateTime.to_unix(end_time, :millisecond)
    duration_ms = end_ms - start_ms
    offset_ms = start_ms + div(duration_ms * (10 + :rand.uniform(10)), 100)
    DateTime.from_unix!(offset_ms, :millisecond)
  end

  defp compute_midpoint(start_time, end_time) do
    start_ms = DateTime.to_unix(start_time, :millisecond)
    end_ms = DateTime.to_unix(end_time, :millisecond)
    midpoint_ms = div(start_ms + end_ms, 2)

    DateTime.from_unix!(midpoint_ms, :millisecond)
  end

  # Converts absolute position bridges to semantic bridges using Allen relations
  defp convert_to_semantic_bridge(timeline, %Bridge{semantic_relation: nil} = bridge) do
    # Bridge has absolute position but no semantic relation - convert it
    {timeline_start, timeline_end} = get_timeline_bounds(timeline)

    # Determine semantic relation based on bridge position relative to timeline
    semantic_relation = determine_semantic_relation(bridge.position, timeline_start, timeline_end, timeline)

    # Create semantic bridge with computed relation
    %{bridge |
      semantic_relation: semantic_relation,
      reference_target: "timeline",
      computed_position: bridge.position
    }
  end

  defp convert_to_semantic_bridge(_timeline, %Bridge{semantic_relation: _relation} = bridge) do
    # Bridge already has semantic relation - return as-is
    bridge
  end

  # Determines the appropriate Allen interval relation for a bridge position
  defp determine_semantic_relation(position, timeline_start, timeline_end, timeline) do
    # Get precision-aware tolerance based on STN configuration
    tolerance_microseconds = get_boundary_tolerance_microseconds(timeline)

    # Calculate position relative to timeline bounds in microseconds
    start_diff = DateTime.diff(position, timeline_start, :microsecond)
    end_diff = DateTime.diff(timeline_end, position, :microsecond)

    cond do
      # At or very close to start (within configured tolerance)
      abs(start_diff) <= tolerance_microseconds -> :starts

      # At or very close to end (within configured tolerance)
      abs(end_diff) <= tolerance_microseconds -> :finishes

      # Before timeline start
      start_diff < 0 -> :before

      # After timeline end
      end_diff < 0 -> :after

      # Check if positioned relative to specific intervals
      true -> determine_interval_relation(position, timeline)
    end
  end

  # Determine relation based on interval positions
  defp determine_interval_relation(position, timeline) do
    intervals = Map.values(timeline.intervals)
    tolerance_microseconds = get_boundary_tolerance_microseconds(timeline)

    # Find intervals that contain or are adjacent to this position
    containing_intervals = Enum.filter(intervals, fn interval ->
      DateTime.compare(position, interval.start_time) != :lt and
      DateTime.compare(position, interval.end_time) != :gt
    end)

    adjacent_intervals = Enum.filter(intervals, fn interval ->
      start_diff = abs(DateTime.diff(position, interval.start_time, :microsecond))
      end_diff = abs(DateTime.diff(position, interval.end_time, :microsecond))
      start_diff <= tolerance_microseconds or end_diff <= tolerance_microseconds
    end)

    cond do
      # Position is within an interval
      length(containing_intervals) > 0 -> :during

      # Position is adjacent to interval boundaries
      length(adjacent_intervals) > 0 -> :meets

      # Default to during for positions between intervals
      true -> :during
    end
  end

  # Helper function to identify semantic bridges
  defp is_semantic_bridge?(%Bridge{semantic_relation: nil}), do: false
  defp is_semantic_bridge?(%Bridge{semantic_relation: _relation}), do: true

  # Calculates appropriate tolerance for boundary detection based on STN precision
  defp get_boundary_tolerance_microseconds(timeline) do
    stn = timeline.stn
    base_unit_microseconds = case stn.time_unit do
      :microsecond -> 1
      :millisecond -> 1_000
      :second -> 1_000_000
      :minute -> 60_000_000
      :hour -> 3_600_000_000
      :day -> 86_400_000_000
    end

    # Scale by LOD resolution for appropriate precision
    base_unit_microseconds * stn.lod_resolution
  end
end
