defmodule AriaEngine.Timeline do
  @moduledoc "Timeline module with interval-based storage using Path Consistency (PC-2) algorithm\nfor Simple Temporal Network (STN) solving.\n\nAccepts time input in seconds but solves at 1ms tick precision.\nSupports Allen's interval algebra with usability improvements.\nRespects agent vs entity distinction in temporal constraints.\n\n## Time Representation\n- External API: seconds (float/integer)\n- Internal storage/solving: milliseconds (integer)\n- Precision: 1ms ticks as per ADR-006\n\n## Features\n- All 13 Allen interval relations\n- Path Consistency (PC-2) STN solving\n- Agent/entity distinction\n- Fluent API for constraint building\n- Comprehensive edge case handling\n\n## Module Organization\n\nThis module has been split into focused sub-modules for better maintainability:\n\n- `AriaEngine.Timeline.Core` - Core Timeline operations and STN integration\n- `AriaEngine.Timeline.Bridges` - Bridge management and validation\n- `AriaEngine.Timeline.Segmentation` - Timeline segmentation functionality\n- `AriaEngine.Timeline.Builder` - Builder pattern and fluent API\n\n## Examples\n\n    iex> timeline = AriaEngine.Timeline.new()\n    iex> alias AriaEngine.Timeline.Interval\n    iex> start_time = DateTime.from_naive!(~N[2025-01-01 10:00:00], \"Etc/UTC\")\n    iex> end_time = DateTime.from_naive!(~N[2025-01-01 12:00:00], \"Etc/UTC\")\n    iex> interval =\n  Interval.new_fixed_schedule(DateTime.to_iso8601(start_time), DateTime.to_iso8601(end_time))\n    iex> timeline = AriaEngine.Timeline.add_interval(timeline, interval)\n    iex> length(Map.keys(timeline.intervals))\n    1\n\n## References\n\n- ADR-078: Timeline Module PC-2 STN Implementation\n- ADR-079: Timeline Module Implementation Progress\n- ADR-045: Allen's Interval Algebra Temporal Relationships\n- ADR-040: Temporal Constraint Solver Selection\n- ADR-046: Interval Notation Usability\n- ADR-006: Game Engine Real-time Execution (1ms tick requirement)\n"
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
  defstruct intervals: %{}, bridges: %{}, stn: STN.new(), metadata: %{}

  @doc "Creates a new Timeline.\n\n## Examples\n\n    iex> timeline = AriaEngine.Timeline.new()\n    iex> map_size(timeline.intervals)\n    0\n\n"
  @spec new(keyword()) :: t()
  def new(opts \\ []) do
    core_timeline = IntervalOperations.new(opts)
    struct(__MODULE__, core_timeline)
  end

  @doc "Adds an interval to the timeline.\n\n## Examples\n\n    iex> timeline = AriaEngine.Timeline.new()\n    iex> start_time = DateTime.from_naive!(~N[2025-01-01 10:00:00], \"Etc/UTC\")\n    iex> end_time = DateTime.from_naive!(~N[2025-01-01 12:00:00], \"Etc/UTC\")\n    iex> interval =\n  AriaEngine.Timeline.Interval.new_fixed_schedule(\n    DateTime.to_iso8601(start_time),\n    DateTime.to_iso8601(end_time)\n  )\n    iex> updated_timeline = AriaEngine.Timeline.add_interval(timeline, interval)\n    iex> map_size(updated_timeline.intervals)\n    1\n\n"
  @spec add_interval(t(), Interval.t()) :: t()
  def add_interval(%__MODULE__{} = timeline, interval) do
    core_timeline = to_core_timeline(timeline)
    updated_core = IntervalOperations.add_interval(core_timeline, interval)
    struct(__MODULE__, updated_core)
  end

  @doc "Adds multiple intervals to the timeline.\n\n## Examples\n\n    iex> timeline = AriaEngine.Timeline.new()\n    iex> start1 = DateTime.from_naive!(~N[2025-01-01 10:00:00], \"Etc/UTC\")\n    iex> end1 = DateTime.from_naive!(~N[2025-01-01 11:00:00], \"Etc/UTC\")\n    iex> start2 = DateTime.from_naive!(~N[2025-01-01 12:00:00], \"Etc/UTC\")\n    iex> end2 = DateTime.from_naive!(~N[2025-01-01 13:00:00], \"Etc/UTC\")\n    iex> interval1 =\n  AriaEngine.Timeline.Interval.new_fixed_schedule(\n    DateTime.to_iso8601(start1),\n    DateTime.to_iso8601(end1)\n  )\n    iex> interval2 =\n  AriaEngine.Timeline.Interval.new_fixed_schedule(\n    DateTime.to_iso8601(start2),\n    DateTime.to_iso8601(end2)\n  )\n    iex> updated_timeline = AriaEngine.Timeline.add_intervals(timeline, [interval1, interval2])\n    iex> map_size(updated_timeline.intervals)\n    2\n\n"
  @spec add_intervals(t(), list(Interval.t())) :: t()
  def add_intervals(%__MODULE__{} = timeline, intervals) do
    core_timeline = to_core_timeline(timeline)
    updated_core = IntervalOperations.add_intervals(core_timeline, intervals)
    struct(__MODULE__, updated_core)
  end

  @doc "Gets an interval by ID.\n\n## Examples\n\n    iex> timeline = AriaEngine.Timeline.new()\n    iex> start_time = DateTime.from_naive!(~N[2025-01-01 10:00:00], \"Etc/UTC\")\n    iex> end_time = DateTime.from_naive!(~N[2025-01-01 12:00:00], \"Etc/UTC\")\n    iex> interval =\n  AriaEngine.Timeline.Interval.new_fixed_schedule(\n    DateTime.to_iso8601(start_time),\n    DateTime.to_iso8601(end_time)\n  )\n    iex> timeline = AriaEngine.Timeline.add_interval(timeline, interval)\n    iex> retrieved = AriaEngine.Timeline.get_interval(timeline, interval.id)\n    iex> retrieved.id == interval.id\n    true\n\n"
  @spec get_interval(t(), Interval.id()) :: Interval.t() | nil
  def get_interval(%__MODULE__{} = timeline, id) do
    core_timeline = to_core_timeline(timeline)
    IntervalOperations.get_interval(core_timeline, id)
  end

  @doc "Updates an interval in the timeline.\n"
  @spec update_interval(t(), Interval.t()) :: t()
  def update_interval(%__MODULE__{} = timeline, interval) do
    core_timeline = to_core_timeline(timeline)
    updated_core = IntervalOperations.update_interval(core_timeline, interval)
    struct(__MODULE__, updated_core)
  end

  @doc "Removes an interval from the timeline.\n"
  @spec remove_interval(t(), Interval.id()) :: t()
  def remove_interval(%__MODULE__{} = timeline, id) do
    core_timeline = to_core_timeline(timeline)
    updated_core = IntervalOperations.remove_interval(core_timeline, id)
    struct(__MODULE__, updated_core)
  end

  @doc "Adds a constraint between two time points.\n"
  @spec add_constraint(t(), String.t(), String.t(), {number(), number()}) :: t()
  def add_constraint(%__MODULE__{} = timeline, from_point, to_point, constraint) do
    core_timeline = to_core_timeline(timeline)

    updated_core =
      IntervalOperations.add_constraint(core_timeline, from_point, to_point, constraint)

    struct(__MODULE__, updated_core)
  end

  @doc "Solves the timeline's temporal constraints.\n"
  @spec solve(t()) :: t()
  def solve(%__MODULE__{} = timeline) do
    core_timeline = to_core_timeline(timeline)
    updated_core = IntervalOperations.solve(core_timeline)
    struct(__MODULE__, updated_core)
  end

  @doc "Adds a bridge to the timeline.\n\n## Examples\n\n    iex> timeline = AriaEngine.Timeline.new()\n    iex> position = DateTime.from_naive!(~N[2025-01-01 12:00:00], \"Etc/UTC\")\n    iex> bridge = AriaEngine.Timeline.Bridge.new(\"decision_1\", position, :decision)\n    iex> updated_timeline = AriaEngine.Timeline.add_bridge(timeline, bridge)\n    iex> Map.has_key?(updated_timeline.bridges, \"decision_1\")\n    true\n\n"
  @spec add_bridge(t(), Bridge.t()) :: t()
  def add_bridge(%__MODULE__{} = timeline, bridge) do
    core_timeline = to_core_timeline(timeline)
    updated_core = BridgeOperations.add_bridge(core_timeline, bridge)
    struct(__MODULE__, updated_core)
  end

  @doc "Removes a bridge from the timeline.\n"
  @spec remove_bridge(t(), Bridge.id()) :: t()
  def remove_bridge(%__MODULE__{} = timeline, bridge_id) do
    core_timeline = to_core_timeline(timeline)
    updated_core = BridgeOperations.remove_bridge(core_timeline, bridge_id)
    struct(__MODULE__, updated_core)
  end

  @doc "Gets a bridge by ID.\n"
  @spec get_bridge(t(), Bridge.id()) :: Bridge.t() | nil
  def get_bridge(%__MODULE__{} = timeline, bridge_id) do
    core_timeline = to_core_timeline(timeline)
    BridgeOperations.get_bridge(core_timeline, bridge_id)
  end

  @doc "Gets all bridges in the timeline, sorted by position.\n"
  @spec get_bridges(t()) :: [Bridge.t()]
  def get_bridges(%__MODULE__{} = timeline) do
    core_timeline = to_core_timeline(timeline)
    BridgeOperations.get_bridges(core_timeline)
  end

  @doc "Updates a bridge in the timeline.\n"
  @spec update_bridge(t(), Bridge.t()) :: t()
  def update_bridge(%__MODULE__{} = timeline, bridge) do
    core_timeline = to_core_timeline(timeline)
    updated_core = BridgeOperations.update_bridge(core_timeline, bridge)
    struct(__MODULE__, updated_core)
  end

  @doc "Gets the temporal positions of all bridges in the timeline.\n"
  @spec bridge_positions(t()) :: [DateTime.t()]
  def bridge_positions(%__MODULE__{} = timeline) do
    core_timeline = to_core_timeline(timeline)
    BridgeOperations.bridge_positions(core_timeline)
  end

  @doc "Validates that a bridge can be placed at the specified position.\n"
  @spec validate_bridge_placement(t(), Bridge.t()) :: :ok | {:error, String.t()}
  def validate_bridge_placement(%__MODULE__{} = timeline, bridge) do
    core_timeline = to_core_timeline(timeline)
    BridgeOperations.validate_bridge_placement(core_timeline, bridge)
  end

  @doc "Finds bridges within a specific time range.\n"
  @spec bridges_in_range(t(), DateTime.t(), DateTime.t()) :: [Bridge.t()]
  def bridges_in_range(%__MODULE__{} = timeline, start_time, end_time) do
    core_timeline = to_core_timeline(timeline)
    BridgeOperations.bridges_in_range(core_timeline, start_time, end_time)
  end

  @doc "Validates all bridge placements in the timeline.\n"
  @spec validate_all_bridge_placements(t()) :: :ok | {:error, String.t()}
  def validate_all_bridge_placements(%__MODULE__{} = timeline) do
    core_timeline = to_core_timeline(timeline)
    BridgeOperations.validate_all_bridge_placements(core_timeline)
  end

  @doc "Segments the timeline by bridge positions.\n\nReturns a list of timeline segments, where each segment contains intervals\nthat occur between bridge points.\n\n## Examples\n\n    iex> timeline = AriaEngine.Timeline.new()\n    iex> start1 = DateTime.from_naive!(~N[2025-01-01 10:00:00], \"Etc/UTC\")\n    iex> end1 = DateTime.from_naive!(~N[2025-01-01 11:00:00], \"Etc/UTC\")\n    iex> interval1 =\n  AriaEngine.Timeline.Interval.new_fixed_schedule(\n    DateTime.to_iso8601(start1),\n    DateTime.to_iso8601(end1)\n  )\n    iex> timeline = AriaEngine.Timeline.add_interval(timeline, interval1)\n    iex> bridge_pos = DateTime.from_naive!(~N[2025-01-01 10:30:00], \"Etc/UTC\")\n    iex> bridge = AriaEngine.Timeline.Bridge.new(\"decision_1\", bridge_pos, :decision)\n    iex> timeline = AriaEngine.Timeline.add_bridge(timeline, bridge)\n    iex> segments = AriaEngine.Timeline.segment_by_bridges(timeline)\n    iex> length(segments)\n    2\n\n"
  @spec segment_by_bridges(t()) :: [t()]
  def segment_by_bridges(%__MODULE__{} = timeline) do
    core_timeline = to_core_timeline(timeline)
    core_segments = TimelineSegmenter.segment_by_bridges(core_timeline)
    Enum.map(core_segments, &struct(__MODULE__, &1))
  end

  @doc "Gets the temporal bounds of a timeline (earliest start, latest end).\n"
  @spec get_timeline_bounds(t()) :: {DateTime.t(), DateTime.t()}
  def get_timeline_bounds(%__MODULE__{} = timeline) do
    core_timeline = to_core_timeline(timeline)
    TimelineSegmenter.get_timeline_bounds(core_timeline)
  end

  @doc "Creates a new Timeline with STN configuration options.\n"
  @spec new_with_stn_opts(keyword()) :: t()
  def new_with_stn_opts(stn_opts) do
    core_timeline = IntervalOperations.new_with_stn_opts(stn_opts)
    struct(__MODULE__, core_timeline)
  end

  @doc "Creates a new Timeline with constant work pattern enabled.\n"
  @spec new_constant_work(keyword()) :: t()
  def new_constant_work(opts \\ []) do
    core_timeline = IntervalOperations.new_constant_work(opts)
    struct(__MODULE__, core_timeline)
  end

  @doc "Checks if the Timeline's temporal constraints are consistent.\n"
  @spec consistent?(t()) :: boolean()
  def consistent?(%__MODULE__{} = timeline) do
    core_timeline = to_core_timeline(timeline)
    IntervalOperations.consistent?(core_timeline)
  end

  @doc "Gets all time points in the Timeline's STN.\n"
  @spec time_points(t()) :: [String.t()]
  def time_points(%__MODULE__{} = timeline) do
    core_timeline = to_core_timeline(timeline)
    IntervalOperations.time_points(core_timeline)
  end

  @doc "Adds a time point to the Timeline's STN.\n"
  @spec add_time_point(t(), String.t()) :: t()
  def add_time_point(%__MODULE__{} = timeline, time_point) do
    core_timeline = to_core_timeline(timeline)
    updated_core = IntervalOperations.add_time_point(core_timeline, time_point)
    struct(__MODULE__, updated_core)
  end

  @doc "Gets a constraint between two time points.\n"
  @spec get_constraint(t(), String.t(), String.t()) :: {number(), number()} | nil
  def get_constraint(%__MODULE__{} = timeline, from_point, to_point) do
    core_timeline = to_core_timeline(timeline)
    IntervalOperations.get_constraint(core_timeline, from_point, to_point)
  end

  @doc "TOMBSTONE: PC-2 algorithm was removed in favor of MiniZinc-based STN solving.\n"
  @spec apply_pc2(t()) :: t()
  def apply_pc2(%__MODULE__{} = timeline) do
    core_timeline = to_core_timeline(timeline)
    updated_core = IntervalOperations.apply_pc2(core_timeline)
    struct(__MODULE__, updated_core)
  end

  @doc "Computes the intersection of two Timelines.\n"
  @spec intersection(t(), t()) :: t()
  def intersection(%__MODULE__{} = timeline1, %__MODULE__{} = timeline2) do
    core1 = to_core_timeline(timeline1)
    core2 = to_core_timeline(timeline2)
    updated_core = IntervalOperations.intersection(core1, core2)
    struct(__MODULE__, updated_core)
  end

  @doc "Computes the union of two Timelines.\n"
  @spec union(t(), t()) :: t()
  def union(%__MODULE__{} = timeline1, %__MODULE__{} = timeline2) do
    core1 = to_core_timeline(timeline1)
    core2 = to_core_timeline(timeline2)
    updated_core = IntervalOperations.union(core1, core2)
    struct(__MODULE__, updated_core)
  end

  @doc "Chains multiple Timelines sequentially.\n"
  @spec chain([t()]) :: t()
  def chain([]) do
    new()
  end

  def chain([single_timeline]) do
    single_timeline
  end

  def chain(timelines) when is_list(timelines) do
    core_timelines = Enum.map(timelines, &to_core_timeline/1)
    updated_core = IntervalOperations.chain(core_timelines)
    struct(__MODULE__, updated_core)
  end

  @doc "Joins multiple Timelines in parallel.\n"
  @spec parallel_join([t()]) :: t()
  def parallel_join([]) do
    new()
  end

  def parallel_join([single_timeline]) do
    single_timeline
  end

  def parallel_join(timelines) when is_list(timelines) do
    core_timelines = Enum.map(timelines, &to_core_timeline/1)
    updated_core = IntervalOperations.parallel_join(core_timelines)
    struct(__MODULE__, updated_core)
  end

  @doc "Composes two Timelines.\n"
  @spec compose(t(), t()) :: t()
  def compose(%__MODULE__{} = timeline1, %__MODULE__{} = timeline2) do
    core1 = to_core_timeline(timeline1)
    core2 = to_core_timeline(timeline2)
    updated_core = IntervalOperations.compose(core1, core2)
    struct(__MODULE__, updated_core)
  end

  @doc "Segments a Timeline for parallel processing.\n"
  @spec segment(t(), pos_integer()) :: t()
  def segment(%__MODULE__{} = timeline, max_segments) do
    core_timeline = to_core_timeline(timeline)
    updated_core = IntervalOperations.segment(core_timeline, max_segments)
    struct(__MODULE__, updated_core)
  end

  @doc "Solves a Timeline using parallel processing.\n"
  @spec parallel_solve(t(), pos_integer()) :: t()
  def parallel_solve(%__MODULE__{} = timeline, max_segments) do
    core_timeline = to_core_timeline(timeline)
    updated_core = IntervalOperations.parallel_solve(core_timeline, max_segments)
    struct(__MODULE__, updated_core)
  end

  @doc "Gets the underlying STN for compatibility during migration.\n"
  @spec get_stn(t()) :: STN.t()
  def get_stn(%__MODULE__{} = timeline) do
    core_timeline = to_core_timeline(timeline)
    IntervalOperations.get_stn(core_timeline)
  end

  @doc "Creates a Timeline from an existing STN.\n"
  @spec from_stn(STN.t()) :: t()
  def from_stn(stn) do
    core_timeline = IntervalOperations.from_stn(stn)
    struct(__MODULE__, core_timeline)
  end

  @doc "Enable automatic bridge segmentation for this timeline.\n"
  @spec with_bridge_segmentation(t()) :: t()
  def with_bridge_segmentation(%__MODULE__{} = timeline) do
    updated_metadata = Map.put(timeline.metadata, :auto_bridge_mode, true)
    %{timeline | metadata: updated_metadata}
  end

  @doc "Automatically insert bridges at logical decision points.\n"
  @spec auto_insert_bridges(t(), [atom()]) :: t()
  def auto_insert_bridges(%__MODULE__{} = timeline, rules \\ [:action_type_transitions]) do
    bridges_to_add = analyze_and_create_bridges(timeline, rules)

    Enum.reduce(bridges_to_add, timeline, fn bridge, acc_timeline ->
      add_bridge(acc_timeline, bridge)
    end)
  end

  @doc "Add a phase of intervals with automatic bridge insertion.\n"
  @spec add_phase(t(), String.t(), [Interval.t()]) :: t()
  def add_phase(%__MODULE__{} = timeline, phase_name, intervals) do
    timeline_with_intervals = add_intervals(timeline, intervals)

    case Map.get(timeline.metadata, :auto_bridge_mode, false) do
      true ->
        phase_end_time = get_phase_end_time(intervals)
        bridge_id = "#{phase_name}_end"
        bridge = Bridge.new(bridge_id, phase_end_time, :decision, %{phase: phase_name})
        add_bridge(timeline_with_intervals, bridge)

      false ->
        timeline_with_intervals
    end
  end

  defp to_core_timeline(%__MODULE__{} = timeline) do
    %{
      intervals: timeline.intervals,
      bridges: timeline.bridges,
      stn: timeline.stn,
      metadata: timeline.metadata
    }
  end

  defp analyze_and_create_bridges(%__MODULE__{} = timeline, rules) do
    intervals = Map.values(timeline.intervals)

    Enum.flat_map(rules, fn rule ->
      case rule do
        :action_type_transitions -> create_action_transition_bridges(intervals)
        :resource_changes -> create_resource_change_bridges(intervals)
        :phase_boundaries -> create_phase_boundary_bridges(intervals)
        :decision_points -> create_decision_point_bridges(intervals)
        _ -> []
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
          phase_end_time = phase_intervals |> Enum.map(& &1.end_time) |> Enum.max(DateTime)
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
    Map.get(metadata, :has_decision, false) or Map.get(metadata, :decision_point, false)
  end

  defp get_phase_end_time(intervals) when is_list(intervals) do
    case intervals do
      [] -> DateTime.utc_now()
      _ -> intervals |> Enum.map(& &1.end_time) |> Enum.max(DateTime)
    end
  end
end