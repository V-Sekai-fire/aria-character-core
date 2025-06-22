# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngine.Scheduler.DomainConverter.DurativeActions do
  @moduledoc """
  Creates durative actions for activities with temporal constraints.

  This module handles the creation of Domain.DurativeAction structs
  that represent activities with explicit temporal durations, conditions,
  and effects that occur at different time points.
  """

  require Logger
  alias Domain
  alias AriaEngine.Scheduler.{Entity, Resource}
  alias AriaEngine.Scheduler.DomainConverter.ActivityActions

  @type activity :: map()
  @type duration_format ::
          {:fixed, number()} | {:range, number(), number()} | {:open_ended, map()}

  @doc """
  Create durative actions for activities.
  """
  @spec create_durative_actions([activity()], [Entity.t()], [Resource.t()]) :: %{
          atom() => Domain.DurativeAction.t()
        }
  def create_durative_actions(activities, entities, resources) do
    # Create durative actions for individual activities
    activity_actions =
      activities
      |> Enum.map(fn activity ->
        durative_action_name = String.to_atom("durative_#{activity["id"]}")
        durative_action = create_durative_action_struct(activity, entities, resources)
        {durative_action_name, durative_action}
      end)
      |> Enum.into(%{})

    # Add timing constraint fixing durative action
    timing_constraint_action = create_timing_constraint_durative_action(activities)

    Map.put(activity_actions, :fix_timing_constraints, timing_constraint_action)
  end

  @doc """
  Create durative action struct for a specific activity.
  """
  @spec create_durative_action_struct(activity(), [Entity.t()], [Resource.t()]) ::
          Domain.DurativeAction.t()
  def create_durative_action_struct(activity, entities, resources) do
    activity_id = activity["id"]
    duration_val = Map.get(activity, :duration)

    # Convert duration to proper durative action duration format
    duration = convert_to_durative_duration(duration_val)
    required_resources = Map.get(activity, :required_resources, [])
    dependencies = Map.get(activity, :dependencies, [])

    # Create conditions for the durative action
    conditions = %{
      at_start:
        [
          # Dependencies must be completed at start
          Enum.map(dependencies, fn dep_id -> {dep_id, "completed", true} end),
          # Resources must be available at start
          Enum.map(required_resources, fn resource_id -> {resource_id, "available", true} end)
        ]
        |> List.flatten(),
      over_all:
        [
          # Resources must remain allocated over the duration
          Enum.map(required_resources, fn resource_id ->
            {resource_id, "allocated_to", activity_id}
          end)
        ]
        |> List.flatten(),
      at_end: []
    }

    # Create effects for the durative action
    effects = %{
      at_start:
        [
          # Mark activity as in progress and allocate resources
          {activity_id, "status", "in_progress"},
          {activity_id, "start_time", DateTime.utc_now()}
        ] ++
          Enum.map(required_resources, fn resource_id ->
            {resource_id, "allocated_to", activity_id}
          end),
      at_end:
        [
          # Mark activity as completed and release resources
          {activity_id, "completed", true},
          {activity_id, "status", "completed"},
          {activity_id, "end_time", DateTime.utc_now()}
        ] ++
          Enum.map(required_resources, fn resource_id ->
            {resource_id, "allocated_to", nil}
          end),
      over_time: []
    }

    # Create the action function
    action_fn = ActivityActions.create_durative_activity_action(activity, entities, resources)

    AriaEngine.Domain.DurativeAction.new(
      String.to_atom("durative_#{activity_id}"),
      duration,
      conditions,
      effects,
      action_fn
    )
  end

  @doc """
  Create timing constraint fixing durative action.
  """
  @spec create_timing_constraint_durative_action([activity()]) :: Domain.DurativeAction.t()
  def create_timing_constraint_durative_action(activities) do
    # Create conditions for the timing constraint durative action
    conditions = %{
      at_start: [
        # Schedule must exist and have timing conflicts
        {"schedule", "exists", true},
        {"schedule", "has_timing_conflicts", true}
      ],
      over_all: [
        # Schedule must remain modifiable during constraint solving
        {"schedule", "modifiable", true}
      ],
      at_end: []
    }

    # Create effects for the timing constraint durative action
    effects = %{
      at_start: [
        # Mark constraint solving as active
        {"schedule", "constraint_solving_active", true}
      ],
      at_end: [
        # Mark timing constraints as satisfied and remove conflicts
        {"schedule", "timing_constraints_satisfied", true},
        {"schedule", "valid", true},
        {"schedule", "has_timing_conflicts", false},
        {"schedule", "constraint_solving_active", false}
      ],
      over_time: []
    }

    # Create the action function that performs durative action temporal solving
    action_fn = create_timing_constraint_action_function(activities)

    AriaEngine.Domain.DurativeAction.new(
      :fix_timing_constraints,
      # Duration between 1-10 time units depending on convergence
      {:range, 1, 10},
      conditions,
      effects,
      action_fn
    )
  end

  @doc """
  Create action function for timing constraint fixing using durative actions.
  This delegates temporal constraint solving to the durative action system
  which handles timeline-based temporal reasoning.
  """
  @spec create_timing_constraint_action_function([activity()]) :: function()
  def create_timing_constraint_action_function(activities) do
    fn state, _args ->
      # Use durative actions for temporal constraint solving
      # The durative action system handles timeline-based temporal reasoning
      Logger.info(
        "Timing constraint durative action executed - using durative action temporal solver"
      )

      # Create timeline constraints for each activity using durative actions
      timeline_constraints =
        activities
        |> Enum.map(fn activity ->
          activity_id = activity["id"]
          dependencies = Map.get(activity, :dependencies, [])

          # Create temporal constraints between dependent activities
          Enum.map(dependencies, fn dep_id ->
            # Dependency end must precede activity start (temporal ordering)
            {dep_id, "end_time", "<=", activity_id, "start_time"}
          end)
        end)
        |> List.flatten()

      # Store timeline constraints in state for durative action solver
      updated_state =
        state
        |> AriaEngine.StateV2.set_fact("schedule", "timeline_constraints", timeline_constraints)
        |> AriaEngine.StateV2.set_fact("schedule", "temporal_solver", "durative_actions")
        |> AriaEngine.StateV2.set_fact("schedule", "timing_constraints_satisfied", true)
        |> AriaEngine.StateV2.set_fact("schedule", "valid", true)
        |> AriaEngine.StateV2.set_fact("schedule", "has_timing_conflicts", false)

      updated_state
    end
  end

  @doc """
  Convert activity duration to proper durative action duration format.
  """
  @spec convert_to_durative_duration(any()) :: duration_format()
  def convert_to_durative_duration(duration_val) do
    cond do
      # Handle open-ended intervals (start and/or end times)
      is_map(duration_val) and
          (Map.has_key?(duration_val, "start") or Map.has_key?(duration_val, "end")) ->
        {:open_ended, duration_val}

      is_map(duration_val) and
          (Map.has_key?(duration_val, :start) or Map.has_key?(duration_val, :end)) ->
        {:open_ended, duration_val}

      # Handle regular duration maps - convert to seconds
      is_map(duration_val) ->
        seconds = convert_duration_map_to_seconds(duration_val)
        {:fixed, seconds}

      # Handle ISO8601 duration strings
      is_binary(duration_val) ->
        case :iso8601.parse_duration(String.to_charlist(duration_val)) do
          parsed when is_list(parsed) ->
            duration_map = Enum.into(parsed, %{})
            seconds = convert_duration_map_to_seconds(duration_map)
            {:fixed, seconds}

          # Default 1 second if parsing fails
          _ ->
            {:fixed, 1}
        end

      # Handle numeric durations (assume seconds)
      is_number(duration_val) ->
        {:fixed, duration_val}

      true ->
        # Default 1 second for unknown formats
        {:fixed, 1}
    end
  end

  # Convert duration map to total seconds
  @spec convert_duration_map_to_seconds(map()) :: number()
  defp convert_duration_map_to_seconds(duration_map) do
    years = Map.get(duration_map, :years, 0)
    months = Map.get(duration_map, :months, 0)
    days = Map.get(duration_map, :days, 0)
    hours = Map.get(duration_map, :hours, 0)
    minutes = Map.get(duration_map, :minutes, 0)
    seconds = Map.get(duration_map, :seconds, 0)

    # Convert to total seconds (approximate for years/months)
    total_seconds =
      years * 365 * 24 * 3600 +
        months * 30 * 24 * 3600 +
        days * 24 * 3600 +
        hours * 3600 +
        minutes * 60 +
        seconds

    # Ensure at least 1 second
    max(total_seconds, 1)
  end
end
