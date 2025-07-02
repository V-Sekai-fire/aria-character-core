# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaHybridPlanner.TemporalPlanner.STNMethod do
  @moduledoc "STN-based method representation for hierarchical temporal planning.\n\nThis module groups related STNActions into methods, creating method-level STN segments\nthat can be composed hierarchically. Methods act as the middle layer in the\nhierarchical STN composition: Action → Method → Goal.\n\n## Method Decomposition\n\nMethods decompose into one of several patterns:\n- **Sequential**: Actions must execute in order (chain composition)\n- **Parallel**: Actions can execute simultaneously (parallel_join composition)  \n- **Alternative**: One action from a set (union composition)\n- **Conditional**: Actions based on state/preconditions (intersection composition)\n\n## Non-temporal Bridge Handling\n\nMethods can contain non-temporal actions that act as bridges between temporal segments:\n- **Bridge actions**: Instantaneous decisions, computations, conditions\n- **Segment boundaries**: Natural breaking points for STN composition\n- **Temporal consistency**: Maintain timeline consistency across bridges\n\n## Hierarchical Composition\n\nMethods enable O(k * (n/k)³) complexity reduction by:\n- Grouping related actions into method-level STN segments\n- Solving method segments in parallel\n- Composing method results using STN boolean operations\n"
  alias AriaHybridPlanner.TemporalPlanner.STNAction
  alias AriaTimeline, as: Timeline
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
    estimated_duration = estimate_method_duration(pattern, stn_actions, bridge_actions)

    %__MODULE__{
      method_id: method_id,
      decomposition_pattern: pattern,
      stn_actions: stn_actions,
      bridge_actions: bridge_actions,
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

    %{
      method
      | bridge_actions: updated_bridges,
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
