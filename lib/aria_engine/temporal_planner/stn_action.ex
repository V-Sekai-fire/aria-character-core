# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule TemporalPlanner.STNAction do
  @moduledoc """
  STN-based action representation for unified temporal planning.

  This module converts individual actions into STN segments with temporal constraints,
  enabling seamless integration between action execution and temporal constraint solving.
  Each action becomes an atomic STN segment with start/end timepoints and associated
  temporal constraints for preconditions, effects, and resource usage.

  ## Action-to-STN Mapping

  - **Action execution** → STN segment with duration constraints
  - **Preconditions** → Temporal constraints on start timepoint
  - **Effects** → Temporal constraints on end timepoint  
  - **Resource usage** → Duration constraints spanning execution interval
  - **Dependencies** → Inter-segment boundary constraints

  ## Integration with STN Operations

  Actions represented as STN segments can leverage all STN boolean operations:
  - **Sequential actions** → `chain/1` operation
  - **Parallel actions** → `parallel_join/1` operation
  - **Alternative actions** → `union/2` operation
  - **Resource conflicts** → `intersection/2` for constraint tightening
  """

  alias Timeline

  @type action_id :: String.t()
  @type resource_id :: String.t()
  @type timepoint :: String.t()
  @type temporal_constraint :: {number(), number()}
  @type duration_constraint :: {min_duration :: number(), max_duration :: number()}

  @type precondition :: %{
          resource: resource_id(),
          constraint: temporal_constraint(),
          timepoint: timepoint()
        }

  @type effect :: %{
          resource: resource_id(),
          constraint: temporal_constraint(),
          timepoint: timepoint()
        }

  @type resource_requirement :: %{
          resource: resource_id(),
          duration: duration_constraint(),
          exclusive: boolean()
        }

  @type t :: %__MODULE__{
          action_id: action_id(),
          stn_segment: map(),
          base_stn: Timeline.t(),
          preconditions: [precondition()],
          effects: [effect()],
          resource_requirements: [resource_requirement()],
          start_timepoint: timepoint(),
          end_timepoint: timepoint(),
          estimated_duration: duration_constraint(),
          metadata: map()
        }

  defstruct action_id: nil,
            stn_segment: nil,
            base_stn: nil,
            preconditions: [],
            effects: [],
            resource_requirements: [],
            start_timepoint: nil,
            end_timepoint: nil,
            estimated_duration: {0, :infinity},
            metadata: %{}

  @doc """
  Creates a new STN-based action with the specified parameters.

  ## Examples

      iex> action = STNAction.new("move_to_position", 
      ...>   duration: {5000, 10000},
      ...>   preconditions: [%{resource: "location", constraint: {0, 0}}],
      ...>   effects: [%{resource: "position", constraint: {0, 0}}]
      ...> )
      iex> action.action_id
      "move_to_position"

  """
  @spec new(action_id(), keyword()) :: t()
  def new(action_id, opts \\ []) do
    duration = Keyword.get(opts, :duration, {1000, 5000})
    preconditions = Keyword.get(opts, :preconditions, [])
    effects = Keyword.get(opts, :effects, [])
    resource_requirements = Keyword.get(opts, :resource_requirements, [])
    metadata = Keyword.get(opts, :metadata, %{})

    # Generate unique timepoints for this action
    start_timepoint = "#{action_id}_start"
    end_timepoint = "#{action_id}_end"

    # Create base Timeline with action duration constraint
    base_timeline = Timeline.new()
    |> Timeline.add_constraint(start_timepoint, end_timepoint, duration)

    # Add precondition constraints
    timeline_with_preconditions = 
      Enum.reduce(preconditions, base_timeline, fn precond, timeline ->
        precond_timepoint = "#{action_id}_precond_#{precond.resource}"
        timeline
        |> Timeline.add_constraint(precond_timepoint, start_timepoint, precond.constraint)
      end)

    # Add effect constraints  
    timeline_with_effects =
      Enum.reduce(effects, timeline_with_preconditions, fn effect, timeline ->
        effect_timepoint = "#{action_id}_effect_#{effect.resource}"
        timeline
        |> Timeline.add_constraint(end_timepoint, effect_timepoint, effect.constraint)
      end)

    # Add resource requirement constraints
    final_timeline =
      Enum.reduce(resource_requirements, timeline_with_effects, fn req, timeline ->
        resource_start = "#{action_id}_resource_#{req.resource}_start"
        resource_end = "#{action_id}_resource_#{req.resource}_end"
        timeline
        |> Timeline.add_constraint(resource_start, resource_end, req.duration)
        |> Timeline.add_constraint(start_timepoint, resource_start, {0, 0})
        |> Timeline.add_constraint(resource_end, end_timepoint, {0, 0})
      end)

    # Create STN segment representation
    segment = %{
      id: action_id,
      time_points: Timeline.time_points(final_timeline) |> MapSet.new(),
      constraints: Timeline.get_stn(final_timeline).constraints,
      boundary_points: [start_timepoint, end_timepoint],
      consistent: Timeline.consistent?(final_timeline)
    }

    %__MODULE__{
      action_id: action_id,
      stn_segment: segment,
      base_stn: final_timeline,
      preconditions: normalize_preconditions(preconditions, action_id),
      effects: normalize_effects(effects, action_id),
      resource_requirements: resource_requirements,
      start_timepoint: start_timepoint,
      end_timepoint: end_timepoint,
      estimated_duration: duration,
      metadata: metadata
    }
  end

  @doc """
  Converts the STN action to a standard STN for integration with STN operations.

  ## Examples

      iex> action = STNAction.new("example_action")
      iex> stn = STNAction.to_stn(action)
      iex> STN.consistent?(stn)
      true

  """
  @spec to_timeline(t()) :: Timeline.t()
  def to_timeline(%__MODULE__{base_stn: timeline}), do: timeline

  @doc """
  Creates a sequential chain of STN actions using Timeline chain operation.

  ## Examples

      iex> action1 = STNAction.new("first")  
      iex> action2 = STNAction.new("second")
      iex> chained_timeline = STNAction.chain([action1, action2])
      iex> Timeline.consistent?(chained_timeline)
      true

  """
  @spec chain([t()]) :: Timeline.t()
  def chain(actions) when is_list(actions) do
    actions
    |> Enum.map(&to_timeline/1)
    |> Timeline.chain()
  end

  @doc """
  Creates parallel execution of STN actions using Timeline parallel_join operation.

  ## Examples

      iex> action1 = STNAction.new("parallel_1")
      iex> action2 = STNAction.new("parallel_2") 
      iex> parallel_timeline = STNAction.parallel([action1, action2])
      iex> Timeline.consistent?(parallel_timeline)
      true

  """
  @spec parallel([t()]) :: Timeline.t()
  def parallel(actions) when is_list(actions) do
    actions
    |> Enum.map(&to_timeline/1)
    |> Timeline.parallel_join()
  end

  @doc """
  Creates alternative action choices using Timeline union operation.

  ## Examples

      iex> action1 = STNAction.new("option_1")
      iex> action2 = STNAction.new("option_2")
      iex> alternative_timeline = STNAction.alternative([action1, action2])
      iex> Timeline.consistent?(alternative_timeline)
      true

  """
  @spec alternative([t()]) :: Timeline.t()
  def alternative(actions) when is_list(actions) do
    actions
    |> Enum.map(&to_timeline/1)
    |> Enum.reduce(&Timeline.union/2)
  end

  @doc """
  Checks if an action can execute given current temporal constraints.

  """
  @spec can_execute?(t(), Timeline.t()) :: boolean()
  def can_execute?(%__MODULE__{base_stn: action_timeline}, world_timeline) do
    # Check if action Timeline is consistent with world constraints
    merged_timeline = Timeline.intersection(action_timeline, world_timeline)
    Timeline.consistent?(merged_timeline)
  end

  @doc """
  Updates action timing based on execution results.

  """
  @spec update_timing(t(), keyword()) :: t()
  def update_timing(%__MODULE__{} = action, opts) do
    actual_duration = Keyword.get(opts, :actual_duration)
    actual_start = Keyword.get(opts, :actual_start)
    actual_end = Keyword.get(opts, :actual_end)

    updated_metadata = Map.merge(action.metadata, %{
      execution_history: [
        %{
          actual_duration: actual_duration,
          actual_start: actual_start,
          actual_end: actual_end,
          timestamp: DateTime.utc_now()
        } | Map.get(action.metadata, :execution_history, [])
      ]
    })

    %{action | metadata: updated_metadata}
  end

  # Private helper functions

  defp normalize_preconditions(preconditions, action_id) do
    Enum.map(preconditions, fn
      %{resource: resource, constraint: constraint} ->
        %{
          resource: resource,
          constraint: constraint,
          timepoint: "#{action_id}_precond_#{resource}"
        }
      precond -> precond
    end)
  end

  defp normalize_effects(effects, action_id) do
    Enum.map(effects, fn
      %{resource: resource, constraint: constraint} ->
        %{
          resource: resource,
          constraint: constraint,
          timepoint: "#{action_id}_effect_#{resource}"
        }
      effect -> effect
    end)
  end
end
