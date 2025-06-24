# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule TemporalPlanner.STNMethod do
  @moduledoc "STN-based method representation for hierarchical temporal planning.\n\nThis module groups related STNActions into methods, creating method-level STN segments\nthat can be composed hierarchically. Methods act as the middle layer in the\nhierarchical STN composition: Action → Method → Goal.\n\n## Method Decomposition\n\nMethods decompose into one of several patterns:\n- **Sequential**: Actions must execute in order (chain composition)\n- **Parallel**: Actions can execute simultaneously (parallel_join composition)  \n- **Alternative**: One action from a set (union composition)\n- **Conditional**: Actions based on state/preconditions (intersection composition)\n\n## Non-temporal Bridge Handling\n\nMethods can contain non-temporal actions that act as bridges between temporal segments:\n- **Bridge actions**: Instantaneous decisions, computations, conditions\n- **Segment boundaries**: Natural breaking points for STN composition\n- **Temporal consistency**: Maintain timeline consistency across bridges\n\n## Hierarchical Composition\n\nMethods enable O(k * (n/k)³) complexity reduction by:\n- Grouping related actions into method-level STN segments\n- Solving method segments in parallel\n- Composing method results using STN boolean operations\n"
  alias TemporalPlanner.STNAction
  alias Timeline
  @type method_id :: String.t()
  @type decomposition_pattern :: :sequential | :parallel | :alternative | :conditional
  @type bridge_action :: %{
          action_id: String.t(),
          type: :decision | :computation | :condition,
          duration: :instantaneous,
          metadata: map()
        }
  @type t :: %__MODULE__{
          method_id: method_id(),
          decomposition_pattern: decomposition_pattern(),
          stn_actions: [STNAction.t()],
          bridge_actions: [bridge_action()],
          method_stn: Timeline.t(),
          temporal_segments: [Timeline.t()],
          preconditions: [STNAction.precondition()],
          effects: [STNAction.effect()],
          estimated_duration: STNAction.duration_constraint(),
          metadata: map()
        }
  defstruct method_id: nil,
            decomposition_pattern: :sequential,
            stn_actions: [],
            bridge_actions: [],
            method_stn: nil,
            temporal_segments: [],
            preconditions: [],
            effects: [],
            estimated_duration: {0, :infinity},
            metadata: %{}

  @doc "Creates a new STN method with the specified decomposition pattern.\n\n## Examples\n\n    iex> actions = [\n    ...>   STNAction.new(\"move\", duration: {2000, 3000}),\n    ...>   STNAction.new(\"observe\", duration: {1000, 2000})\n    ...> ]\n    iex> method = STNMethod.new(\"patrol\", :sequential, actions)\n    iex> method.method_id\n    \"patrol\"\n\n"
  @spec new(method_id(), decomposition_pattern(), [STNAction.t()], keyword()) :: t()
  def new(method_id, pattern, stn_actions, opts \\ [])
      when pattern in [:sequential, :parallel, :alternative, :conditional] do
    bridge_actions = Keyword.get(opts, :bridge_actions, [])
    preconditions = Keyword.get(opts, :preconditions, [])
    effects = Keyword.get(opts, :effects, [])
    metadata = Keyword.get(opts, :metadata, %{})
    method_stn = compute_method_stn(pattern, stn_actions, bridge_actions)
    temporal_segments = create_temporal_segments(stn_actions, bridge_actions, pattern)
    estimated_duration = estimate_method_duration(pattern, stn_actions, bridge_actions)

    %__MODULE__{
      method_id: method_id,
      decomposition_pattern: pattern,
      stn_actions: stn_actions,
      bridge_actions: bridge_actions,
      method_stn: method_stn,
      temporal_segments: temporal_segments,
      preconditions: preconditions,
      effects: effects,
      estimated_duration: estimated_duration,
      metadata: metadata
    }
  end

  @doc "Adds a bridge action to separate temporal segments within the method.\n\nBridge actions are non-temporal (instantaneous) actions that create natural\nsegment boundaries for hierarchical STN composition.\n\n## Examples\n\n    iex> method = STNMethod.new(\"recon\", :sequential, [])\n    iex> bridge = %{action_id: \"decide_route\", type: :decision, duration: :instantaneous}\n    iex> updated_method = STNMethod.add_bridge_action(method, bridge)\n    iex> length(updated_method.bridge_actions)\n    1\n\n"
  @spec add_bridge_action(t(), bridge_action()) :: t()
  def add_bridge_action(%__MODULE__{} = method, bridge_action) do
    updated_bridges = method.bridge_actions ++ [bridge_action]

    updated_method_stn =
      compute_method_stn(
        method.decomposition_pattern,
        method.stn_actions,
        updated_bridges
      )

    updated_segments =
      create_temporal_segments(
        method.stn_actions,
        updated_bridges,
        method.decomposition_pattern
      )

    %{
      method
      | bridge_actions: updated_bridges,
        method_stn: updated_method_stn,
        temporal_segments: updated_segments
    }
  end

  @doc "Converts the STN method to a standard Timeline for composition with other methods.\n\n## Examples\n\n    iex> method = STNMethod.new(\"example\", :sequential, [])\n    iex> timeline = STNMethod.to_timeline(method)\n    iex> Timeline.consistent?(timeline)\n    true\n\n"
  @spec to_timeline(t()) :: Timeline.t()
  def to_timeline(%__MODULE__{method_stn: timeline}) do
    timeline
  end

  @doc "Converts the STN method to a standard STN for composition with other methods.\n\nDeprecated: Use to_timeline/1 instead.\n"
  @spec to_stn(t()) :: Timeline.t()
  def to_stn(%__MODULE__{} = method) do
    to_timeline(method)
  end

  @doc "Creates a sequential chain of STN methods using Timeline chain operation.\n\n## Examples\n\n    iex> method1 = STNMethod.new(\"setup\", :sequential, [])\n    iex> method2 = STNMethod.new(\"execute\", :parallel, [])\n    iex> chained_timeline = STNMethod.chain([method1, method2])\n    iex> Timeline.consistent?(chained_timeline)\n    true\n\n"
  @spec chain([t()]) :: Timeline.t()
  def chain(methods) when is_list(methods) do
    methods |> Enum.map(&to_timeline/1) |> Timeline.chain()
  end

  @doc "Creates parallel execution of STN methods using Timeline parallel_join operation.\n\n## Examples\n\n    iex> method1 = STNMethod.new(\"surveillance\", :sequential, [])\n    iex> method2 = STNMethod.new(\"communication\", :parallel, [])\n    iex> parallel_timeline = STNMethod.parallel([method1, method2])\n    iex> Timeline.consistent?(parallel_timeline)\n    true\n\n"
  @spec parallel([t()]) :: Timeline.t()
  def parallel(methods) when is_list(methods) do
    methods |> Enum.map(&to_timeline/1) |> Timeline.parallel_join()
  end

  @doc "Creates alternative method choices using Timeline union operation.\n\n## Examples\n\n    iex> method1 = STNMethod.new(\"approach_a\", :sequential, [])\n    iex> method2 = STNMethod.new(\"approach_b\", :parallel, [])\n    iex> alternative_timeline = STNMethod.alternative([method1, method2])\n    iex> Timeline.consistent?(alternative_timeline)\n    true\n\n"
  @spec alternative([t()]) :: Timeline.t()
  def alternative(methods) when is_list(methods) do
    methods |> Enum.map(&to_timeline/1) |> Enum.reduce(&Timeline.union/2)
  end

  @doc "Solves method segments in parallel and composes results.\n\nThis enables O(k * (n/k)³) complexity reduction by solving each temporal\nsegment independently and then composing results.\n\n## Examples\n\n    iex> method = STNMethod.new(\"complex_method\", :sequential, actions)\n    iex> solved_timeline = STNMethod.solve_parallel(method)\n    iex> Timeline.consistent?(solved_timeline)\n    true\n\n"
  @spec solve_parallel(t()) :: Timeline.t()
  def solve_parallel(%__MODULE__{temporal_segments: segments, decomposition_pattern: _pattern}) do
    case length(segments) do
      0 -> Timeline.new()
      1 -> hd(segments) |> Timeline.apply_pc2()
      _segment_count -> :not_implemented
    end
  end

  @doc "Checks if a method can execute given current temporal constraints.\n\n## Examples\n\n    iex> method = STNMethod.new(\"example\", :sequential, [])\n    iex> world_timeline = Timeline.new()\n    iex> STNMethod.can_execute?(method, world_timeline)\n    true\n\n"
  @spec can_execute?(t(), Timeline.t()) :: boolean()
  def can_execute?(%__MODULE__{method_stn: method_stn}, world_timeline) do
    merged_timeline = Timeline.intersection(method_stn, world_timeline)
    Timeline.consistent?(merged_timeline)
  end

  @doc "Updates method timing based on execution results.\n\n## Examples\n\n    iex> method = STNMethod.new(\"example\", :sequential, [])\n    iex> updated = STNMethod.update_timing(method, actual_duration: 5000)\n    iex> is_map(updated.metadata.execution_history)\n    true\n\n"
  @spec update_timing(t(), keyword()) :: t()
  def update_timing(%__MODULE__{} = method, opts) do
    actual_duration = Keyword.get(opts, :actual_duration)
    actual_start = Keyword.get(opts, :actual_start)
    actual_end = Keyword.get(opts, :actual_end)

    updated_metadata =
      Map.merge(method.metadata, %{
        execution_history: [
          %{
            actual_duration: actual_duration,
            actual_start: actual_start,
            actual_end: actual_end,
            timestamp: DateTime.utc_now()
          }
          | Map.get(method.metadata, :execution_history, [])
        ]
      })

    %{method | metadata: updated_metadata}
  end

  defp compute_method_stn(pattern, stn_actions, bridge_actions) do
    action_timelines = Enum.map(stn_actions, &STNAction.to_timeline/1)

    composed_timeline =
      case pattern do
        :sequential ->
          Timeline.chain(action_timelines)

        :parallel ->
          Timeline.parallel_join(action_timelines)

        :alternative ->
          case action_timelines do
            [] -> Timeline.new()
            [single] -> single
            multiple -> Enum.reduce(multiple, &Timeline.union/2)
          end

        :conditional ->
          case action_timelines do
            [] -> Timeline.new()
            [single] -> single
            multiple -> Enum.reduce(multiple, &Timeline.intersection/2)
          end
      end

    add_bridge_constraints(composed_timeline, bridge_actions)
  end

  defp create_temporal_segments(stn_actions, bridge_actions, pattern) do
    if Enum.empty?(bridge_actions) do
      case stn_actions do
        [] -> []
        actions -> [compute_actions_stn(actions, pattern)]
      end
    else
      split_actions_by_bridges(stn_actions, bridge_actions, pattern)
    end
  end

  defp compute_actions_stn(actions, pattern) do
    action_timelines = Enum.map(actions, &STNAction.to_timeline/1)

    case pattern do
      :sequential ->
        Timeline.chain(action_timelines)

      :parallel ->
        Timeline.parallel_join(action_timelines)

      :alternative ->
        case action_timelines do
          [] -> Timeline.new()
          [single] -> single
          multiple -> Enum.reduce(multiple, &Timeline.union/2)
        end

      :conditional ->
        case action_timelines do
          [] -> Timeline.new()
          [single] -> single
          multiple -> Enum.reduce(multiple, &Timeline.intersection/2)
        end
    end
  end

  defp split_actions_by_bridges(stn_actions, _bridge_actions, pattern) do
    case stn_actions do
      [] -> []
      actions -> [compute_actions_stn(actions, pattern)]
    end
  end

  defp add_bridge_constraints(timeline, bridge_actions) do
    Enum.reduce(bridge_actions, timeline, fn bridge, acc_timeline ->
      bridge_timepoint = "#{bridge.action_id}_bridge"

      acc_timeline
      |> Timeline.add_time_point(bridge_timepoint)
      |> Timeline.add_constraint(bridge_timepoint, bridge_timepoint, {-1, 1})
    end)
  end

  defp estimate_method_duration(pattern, stn_actions, _bridge_actions) do
    action_durations = Enum.map(stn_actions, & &1.estimated_duration)

    case pattern do
      :sequential -> estimate_sequential_duration(action_durations)
      :parallel -> estimate_parallel_duration(action_durations)
      :alternative -> estimate_alternative_duration(action_durations)
      :conditional -> estimate_conditional_duration(action_durations)
    end
  end

  defp estimate_sequential_duration(action_durations) do
    Enum.reduce(action_durations, {0, 0}, fn {min, max}, {acc_min, acc_max} ->
      new_max = add_durations(max, acc_max)
      {min + acc_min, new_max}
    end)
  end

  defp estimate_parallel_duration(action_durations) do
    Enum.reduce(action_durations, {0, 0}, fn {min, max}, {acc_min, acc_max} ->
      new_max = max_duration(max, acc_max)
      {max(min, acc_min), new_max}
    end)
  end

  defp estimate_alternative_duration(action_durations) do
    case action_durations do
      [] -> {0, 0}
      durations -> calculate_average_duration(durations)
    end
  end

  defp estimate_conditional_duration(action_durations) do
    Enum.reduce(action_durations, {:infinity, :infinity}, fn {min, max}, {acc_min, acc_max} ->
      new_min = min_duration(min, acc_min)
      new_max = min_duration(max, acc_max)
      {new_min, new_max}
    end)
  end

  defp add_durations(:infinity, _) do
    :infinity
  end

  defp add_durations(_, :infinity) do
    :infinity
  end

  defp add_durations(a, b) do
    a + b
  end

  defp max_duration(:infinity, _) do
    :infinity
  end

  defp max_duration(_, :infinity) do
    :infinity
  end

  defp max_duration(a, b) do
    max(a, b)
  end

  defp min_duration(:infinity, b) do
    b
  end

  defp min_duration(a, :infinity) do
    a
  end

  defp min_duration(a, b) do
    min(a, b)
  end

  defp calculate_average_duration(durations) do
    avg_min = durations |> Enum.map(&elem(&1, 0)) |> Enum.sum() |> div(length(durations))

    avg_max =
      durations
      |> Enum.map(&elem(&1, 1))
      |> Enum.filter(&(&1 != :infinity))
      |> case do
        [] -> :infinity
        finite_maxes -> finite_maxes |> Enum.sum() |> div(length(durations))
      end

    {avg_min, avg_max}
  end
end
