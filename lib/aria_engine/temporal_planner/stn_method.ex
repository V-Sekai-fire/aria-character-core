# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngine.TemporalPlanner.STNMethod do
  @moduledoc """
  STN-based method representation for hierarchical temporal planning.

  This module groups related STNActions into methods, creating method-level STN segments
  that can be composed hierarchically. Methods act as the middle layer in the
  hierarchical STN composition: Action → Method → Goal.

  ## Method Decomposition

  Methods decompose into one of several patterns:
  - **Sequential**: Actions must execute in order (chain composition)
  - **Parallel**: Actions can execute simultaneously (parallel_join composition)  
  - **Alternative**: One action from a set (union composition)
  - **Conditional**: Actions based on state/preconditions (intersection composition)

  ## Non-temporal Bridge Handling

  Methods can contain non-temporal actions that act as bridges between temporal segments:
  - **Bridge actions**: Instantaneous decisions, computations, conditions
  - **Segment boundaries**: Natural breaking points for STN composition
  - **Temporal consistency**: Maintain constraint propagation across bridges

  ## Hierarchical Composition

  Methods enable O(k * (n/k)³) complexity reduction by:
  - Grouping related actions into method-level STN segments
  - Solving method segments in parallel
  - Composing method results using STN boolean operations
  """

  alias AriaEngine.TemporalPlanner.STNAction
  alias AriaEngine.Timeline.STN
  alias AriaEngine.FlowAdapter

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
          method_stn: STN.t(),
          temporal_segments: [STN.t()],
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

  @doc """
  Creates a new STN method with the specified decomposition pattern.

  ## Examples

      iex> actions = [
      ...>   STNAction.new("move", duration: {2000, 3000}),
      ...>   STNAction.new("observe", duration: {1000, 2000})
      ...> ]
      iex> method = STNMethod.new("patrol", :sequential, actions)
      iex> method.method_id
      "patrol"

  """
  @spec new(method_id(), decomposition_pattern(), [STNAction.t()], keyword()) :: t()
  def new(method_id, pattern, stn_actions, opts \\ []) when pattern in [:sequential, :parallel, :alternative, :conditional] do
    bridge_actions = Keyword.get(opts, :bridge_actions, [])
    preconditions = Keyword.get(opts, :preconditions, [])
    effects = Keyword.get(opts, :effects, [])
    metadata = Keyword.get(opts, :metadata, %{})

    # Compute method-level STN based on decomposition pattern
    method_stn = compute_method_stn(pattern, stn_actions, bridge_actions)
    
    # Create temporal segments separated by bridge actions
    temporal_segments = create_temporal_segments(stn_actions, bridge_actions, pattern)
    
    # Estimate overall method duration
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

  @doc """
  Adds a bridge action to separate temporal segments within the method.

  Bridge actions are non-temporal (instantaneous) actions that create natural
  segment boundaries for hierarchical STN composition.

  ## Examples

      iex> method = STNMethod.new("recon", :sequential, [])
      iex> bridge = %{action_id: "decide_route", type: :decision, duration: :instantaneous}
      iex> updated_method = STNMethod.add_bridge_action(method, bridge)
      iex> length(updated_method.bridge_actions)
      1

  """
  @spec add_bridge_action(t(), bridge_action()) :: t()
  def add_bridge_action(%__MODULE__{} = method, bridge_action) do
    updated_bridges = method.bridge_actions ++ [bridge_action]
    
    # Recompute method STN with new bridge
    updated_method_stn = compute_method_stn(
      method.decomposition_pattern, 
      method.stn_actions, 
      updated_bridges
    )
    
    # Recreate temporal segments
    updated_segments = create_temporal_segments(
      method.stn_actions, 
      updated_bridges,
      method.decomposition_pattern
    )

    %{method | 
      bridge_actions: updated_bridges,
      method_stn: updated_method_stn,
      temporal_segments: updated_segments
    }
  end

  @doc """
  Converts the STN method to a standard STN for composition with other methods.

  ## Examples

      iex> method = STNMethod.new("example", :sequential, [])
      iex> stn = STNMethod.to_stn(method)
      iex> STN.consistent?(stn)
      true

  """
  @spec to_stn(t()) :: STN.t()
  def to_stn(%__MODULE__{method_stn: stn}), do: stn

  @doc """
  Creates a sequential chain of STN methods using STN chain operation.

  ## Examples

      iex> method1 = STNMethod.new("setup", :sequential, [])
      iex> method2 = STNMethod.new("execute", :parallel, [])
      iex> chained_stn = STNMethod.chain([method1, method2])
      iex> STN.consistent?(chained_stn)
      true

  """
  @spec chain([t()]) :: STN.t()
  def chain(methods) when is_list(methods) do
    methods
    |> Enum.map(&to_stn/1)
    |> STN.chain()
  end

  @doc """
  Creates parallel execution of STN methods using STN parallel_join operation.

  ## Examples

      iex> method1 = STNMethod.new("surveillance", :sequential, [])
      iex> method2 = STNMethod.new("communication", :parallel, [])
      iex> parallel_stn = STNMethod.parallel([method1, method2])
      iex> STN.consistent?(parallel_stn)
      true

  """
  @spec parallel([t()]) :: STN.t()
  def parallel(methods) when is_list(methods) do
    methods
    |> Enum.map(&to_stn/1)
    |> STN.parallel_join()
  end

  @doc """
  Creates alternative method choices using STN union operation.

  ## Examples

      iex> method1 = STNMethod.new("approach_a", :sequential, [])
      iex> method2 = STNMethod.new("approach_b", :parallel, [])
      iex> alternative_stn = STNMethod.alternative([method1, method2])
      iex> STN.consistent?(alternative_stn)
      true

  """
  @spec alternative([t()]) :: STN.t()
  def alternative(methods) when is_list(methods) do
    methods
    |> Enum.map(&to_stn/1)
    |> Enum.reduce(&STN.union/2)
  end

  @doc """
  Solves method segments in parallel and composes results.

  This enables O(k * (n/k)³) complexity reduction by solving each temporal
  segment independently and then composing results.

  ## Examples

      iex> method = STNMethod.new("complex_method", :sequential, actions)
      iex> solved_stn = STNMethod.solve_parallel(method)
      iex> STN.consistent?(solved_stn)
      true

  """
  @spec solve_parallel(t()) :: STN.t()
  def solve_parallel(%__MODULE__{temporal_segments: segments, decomposition_pattern: pattern}) do
    case length(segments) do
      0 -> STN.new()
      1 -> hd(segments) |> STN.apply_pc2()
      _segment_count ->
        # Solve segments in parallel using FlowAdapter
        solved_segments = FlowAdapter.process_stn_segments(segments, &STN.apply_pc2/1, %{})
        
        # Compose solved segments based on decomposition pattern
        compose_solved_segments(solved_segments, pattern)
    end
  end

  @doc """
  Checks if a method can execute given current temporal constraints.

  ## Examples

      iex> method = STNMethod.new("example", :sequential, [])
      iex> world_stn = STN.new()
      iex> STNMethod.can_execute?(method, world_stn)
      true

  """
  @spec can_execute?(t(), STN.t()) :: boolean()
  def can_execute?(%__MODULE__{method_stn: method_stn}, world_stn) do
    # Check if method STN is consistent with world constraints
    merged_stn = STN.intersection(method_stn, world_stn)
    STN.consistent?(merged_stn)
  end

  @doc """
  Updates method timing based on execution results.

  ## Examples

      iex> method = STNMethod.new("example", :sequential, [])
      iex> updated = STNMethod.update_timing(method, actual_duration: 5000)
      iex> is_map(updated.metadata.execution_history)
      true

  """
  @spec update_timing(t(), keyword()) :: t()
  def update_timing(%__MODULE__{} = method, opts) do
    actual_duration = Keyword.get(opts, :actual_duration)
    actual_start = Keyword.get(opts, :actual_start)
    actual_end = Keyword.get(opts, :actual_end)

    updated_metadata = Map.merge(method.metadata, %{
      execution_history: [
        %{
          actual_duration: actual_duration,
          actual_start: actual_start,
          actual_end: actual_end,
          timestamp: DateTime.utc_now()
        } | Map.get(method.metadata, :execution_history, [])
      ]
    })

    %{method | metadata: updated_metadata}
  end

  # Private helper functions

  defp compute_method_stn(pattern, stn_actions, bridge_actions) do
    # Convert actions to STNs
    action_stns = Enum.map(stn_actions, &STNAction.to_stn/1)
    
    # Apply decomposition pattern
    composed_stn = case pattern do
      :sequential -> 
        STN.chain(action_stns)
      :parallel -> 
        STN.parallel_join(action_stns)
      :alternative ->
        case action_stns do
          [] -> STN.new()
          [single] -> single
          multiple -> Enum.reduce(multiple, &STN.union/2)
        end
      :conditional ->
        # Conditional methods use intersection to tighten constraints
        case action_stns do
          [] -> STN.new()
          [single] -> single
          multiple -> Enum.reduce(multiple, &STN.intersection/2)
        end
    end
    
    # Add bridge action constraints (instantaneous, so they don't affect duration)
    add_bridge_constraints(composed_stn, bridge_actions)
  end

  defp create_temporal_segments(stn_actions, bridge_actions, pattern) do
    if Enum.empty?(bridge_actions) do
      # No bridges, single segment
      case stn_actions do
        [] -> []
        actions -> [compute_actions_stn(actions, pattern)]
      end
    else
      # Split actions by bridge boundaries
      split_actions_by_bridges(stn_actions, bridge_actions, pattern)
    end
  end

  defp compute_actions_stn(actions, pattern) do
    action_stns = Enum.map(actions, &STNAction.to_stn/1)
    
    case pattern do
      :sequential -> STN.chain(action_stns)
      :parallel -> STN.parallel_join(action_stns)
      :alternative -> 
        case action_stns do
          [] -> STN.new()
          [single] -> single
          multiple -> Enum.reduce(multiple, &STN.union/2)
        end
      :conditional ->
        case action_stns do
          [] -> STN.new()
          [single] -> single
          multiple -> Enum.reduce(multiple, &STN.intersection/2)
        end
    end
  end

  defp split_actions_by_bridges(stn_actions, _bridge_actions, pattern) do
    # For now, create a single segment with all actions
    # TODO: Implement proper segmentation based on bridge action positions
    case stn_actions do
      [] -> []
      actions -> [compute_actions_stn(actions, pattern)]
    end
  end

  defp add_bridge_constraints(stn, bridge_actions) do
    # Bridge actions are instantaneous, so they create timepoint markers
    # but don't add duration constraints
    Enum.reduce(bridge_actions, stn, fn bridge, acc_stn ->
      bridge_timepoint = "#{bridge.action_id}_bridge"
      acc_stn
      |> STN.add_time_point(bridge_timepoint)
      |> STN.add_constraint(bridge_timepoint, bridge_timepoint, {0, 0})
    end)
  end

  defp estimate_method_duration(pattern, stn_actions, _bridge_actions) do
    action_durations = Enum.map(stn_actions, & &1.estimated_duration)
    
    case pattern do
      :sequential ->
        # Sum all durations for sequential execution
        Enum.reduce(action_durations, {0, 0}, fn
          {min, max}, {acc_min, acc_max} ->
            new_max = if max == :infinity or acc_max == :infinity, do: :infinity, else: max + acc_max
            {min + acc_min, new_max}
        end)
      :parallel ->
        # Take maximum duration for parallel execution
        Enum.reduce(action_durations, {0, 0}, fn
          {min, max}, {acc_min, acc_max} ->
            new_max = if max == :infinity or acc_max == :infinity, do: :infinity, else: max(max, acc_max)
            {max(min, acc_min), new_max}
        end)
      :alternative ->
        # Take average duration for alternative execution
        case action_durations do
          [] -> {0, 0}
          durations ->
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
      :conditional ->
        # Take minimum duration for conditional execution (most optimistic)
        Enum.reduce(action_durations, {:infinity, :infinity}, fn
          {min, max}, {acc_min, acc_max} ->
            new_min = if acc_min == :infinity, do: min, else: min(min, acc_min)
            new_max = if max == :infinity, do: acc_max, 
                     else: (if acc_max == :infinity, do: max, else: min(max, acc_max))
            {new_min, new_max}
        end)
    end
  end

  defp compose_solved_segments(segments, pattern) do
    case pattern do
      :sequential -> STN.chain(segments)
      :parallel -> STN.parallel_join(segments)
      :alternative -> Enum.reduce(segments, &STN.union/2)
      :conditional -> Enum.reduce(segments, &STN.intersection/2)
    end
  end
end
