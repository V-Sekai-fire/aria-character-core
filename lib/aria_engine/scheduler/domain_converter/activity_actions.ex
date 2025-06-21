# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngine.Scheduler.DomainConverter.ActivityActions do
  @moduledoc """
  Creates basic activity actions for the domain.

  This module handles the creation of durative actions for activities,
  converting activity definitions into executable domain actions with
  proper resource allocation and temporal constraints.
  """

  require Logger
  alias AriaEngine.Scheduler.{Entity, Resource}

  @type activity :: map()
  @type duration_value :: map() | binary() | number()

  @doc """
  Create basic activity actions for the domain.
  All actions are now durative actions; "instantaneous" actions are durative actions with duration 0.
  """
  @spec create_basic_activity_actions([activity()], [Entity.t()], [Resource.t()]) :: %{
          atom() => function()
        }
  def create_basic_activity_actions(activities, entities, resources) do
    # Only create durative actions for all activities
    activities
    |> Enum.map(fn activity ->
      durative_action_name = String.to_atom("durative_#{activity["id"]}")
      durative_action_fn = create_durative_activity_action(activity, entities, resources)
      {durative_action_name, durative_action_fn}
    end)
    |> Enum.into(%{})
  end

  @doc """
  Create durative action function for a specific activity.
  """
  @spec create_durative_activity_action(activity(), [Entity.t()], [Resource.t()]) :: function()
  def create_durative_activity_action(activity, _entities, _resources) do
    fn state, _args ->
      activity_id = activity["id"]
      duration_val = Map.get(activity, :duration)

      duration = parse_duration(duration_val)
      required_resources = Map.get(activity, :required_resources, [])

      # Durative action: handle resource allocation and activity execution over time
      updated_state =
        state
        |> AriaEngine.StateV2.set_fact(activity_id, "status", "in_progress")
        |> AriaEngine.StateV2.set_fact(activity_id, "start_time", DateTime.utc_now())
        |> AriaEngine.StateV2.set_fact(activity_id, "duration", duration)

      # Allocate resources
      final_state =
        Enum.reduce(required_resources, updated_state, fn resource_id, acc_state ->
          current_usage =
            AriaEngine.StateV2.get_fact(acc_state, resource_id, "current_usage") || 0

          acc_state
          |> AriaEngine.StateV2.set_fact(resource_id, "current_usage", current_usage + 1)
          |> AriaEngine.StateV2.set_fact(resource_id, "allocated_to", activity_id)
        end)

      # Mark as completed (for now - in a real temporal system this would be handled by the temporal planner)
      final_state
      |> AriaEngine.StateV2.set_fact(activity_id, "completed", true)
      |> AriaEngine.StateV2.set_fact(activity_id, "status", "completed")
      |> AriaEngine.StateV2.set_fact(activity_id, "end_time", DateTime.utc_now())
    end
  end

  @doc """
  Parse duration value into a standardized format.
  """
  @spec parse_duration(duration_value()) :: map() | nil
  def parse_duration(duration_val) do
    cond do
      # Handle open-ended intervals (start and/or end times)
      is_map(duration_val) and
          (Map.has_key?(duration_val, "start") or Map.has_key?(duration_val, "end")) ->
        duration_val

      is_map(duration_val) and
          (Map.has_key?(duration_val, :start) or Map.has_key?(duration_val, :end)) ->
        duration_val

      # Handle regular duration maps
      is_map(duration_val) ->
        duration_val

      is_binary(duration_val) ->
        case :iso8601.parse_duration(String.to_charlist(duration_val)) do
          parsed when is_list(parsed) ->
            _keys = [:years, :months, :days, :hours, :minutes, :seconds]
            map = Enum.into(parsed, %{})

            %{
              years: Map.get(map, :years, 0),
              months: Map.get(map, :months, 0),
              days: Map.get(map, :days, 0),
              hours: Map.get(map, :hours, 0),
              minutes: Map.get(map, :minutes, 0),
              seconds: Map.get(map, :seconds, 0)
            }

          _ ->
            nil
        end

      true ->
        nil
    end
  end
end
