# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngine.TemporalPlanner.STNAction do
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

  alias AriaEngine.Timeline.STN

  @type action_id :: String.t()
  @type resource_id :: String.t()
  @type timepoint :: String.t()
  @type temporal_constraint :: STN.constraint()
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
          stn_segment: STN.segment(),
          base_stn: STN.t(),
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

    # Create base STN with action duration constraint
    base_stn = STN.new()
    |> STN.add_constraint(start_timepoint, end_timepoint, duration)

    # Add precondition constraints
    stn_with_preconditions = 
      Enum.reduce(preconditions, base_stn, fn precond, stn ->
        precond_timepoint = "#{action_id}_precond_#{precond.resource}"
        stn
        |> STN.add_constraint(precond_timepoint, start_timepoint, precond.constraint)
      end)

    # Add effect constraints  
    stn_with_effects =
      Enum.reduce(effects, stn_with_preconditions, fn effect, stn ->
        effect_timepoint = "#{action_id}_effect_#{effect.resource}"
        stn
        |> STN.add_constraint(end_timepoint, effect_timepoint, effect.constraint)
      end)

    # Add resource requirement constraints
    final_stn =
      Enum.reduce(resource_requirements, stn_with_effects, fn req, stn ->
        resource_start = "#{action_id}_resource_#{req.resource}_start"
        resource_end = "#{action_id}_resource_#{req.resource}_end"
        stn
        |> STN.add_constraint(resource_start, resource_end, req.duration)
        |> STN.add_constraint(start_timepoint, resource_start, {0, 0})
        |> STN.add_constraint(resource_end, end_timepoint, {0, 0})
      end)

    # Create STN segment representation
    segment = %{
      id: action_id,
      time_points: STN.time_points(final_stn) |> MapSet.new(),
      constraints: final_stn.constraints,
      boundary_points: [start_timepoint, end_timepoint],
      consistent: STN.consistent?(final_stn)
    }

    %__MODULE__{
      action_id: action_id,
      stn_segment: segment,
      base_stn: final_stn,
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
  @spec to_stn(t()) :: STN.t()
  def to_stn(%__MODULE__{base_stn: stn}), do: stn

  @doc """
  Creates a sequential chain of STN actions using STN chain operation.

  ## Examples

      iex> action1 = STNAction.new("first")  
      iex> action2 = STNAction.new("second")
      iex> chained_stn = STNAction.chain([action1, action2])
      iex> STN.consistent?(chained_stn)
      true

  """
  @spec chain([t()]) :: STN.t()
  def chain(actions) when is_list(actions) do
    actions
    |> Enum.map(&to_stn/1)
    |> STN.chain()
  end

  @doc """
  Creates parallel execution of STN actions using STN parallel_join operation.

  ## Examples

      iex> action1 = STNAction.new("parallel_1")
      iex> action2 = STNAction.new("parallel_2") 
      iex> parallel_stn = STNAction.parallel([action1, action2])
      iex> STN.consistent?(parallel_stn)
      true

  """
  @spec parallel([t()]) :: STN.t()
  def parallel(actions) when is_list(actions) do
    actions
    |> Enum.map(&to_stn/1)
    |> STN.parallel_join()
  end

  @doc """
  Creates alternative action choices using STN union operation.

  ## Examples

      iex> action1 = STNAction.new("option_1")
      iex> action2 = STNAction.new("option_2")
      iex> alternative_stn = STNAction.alternative([action1, action2])
      iex> STN.consistent?(alternative_stn)
      true

  """
  @spec alternative([t()]) :: STN.t()
  def alternative(actions) when is_list(actions) do
    actions
    |> Enum.map(&to_stn/1)
    |> Enum.reduce(&STN.union/2)
  end

  @doc """
  Checks if an action can execute given current temporal constraints.

  """
  @spec can_execute?(t(), STN.t()) :: boolean()
  def can_execute?(%__MODULE__{base_stn: action_stn}, world_stn) do
    # Check if action STN is consistent with world constraints
    merged_stn = STN.intersection(action_stn, world_stn)
    STN.consistent?(merged_stn)
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
