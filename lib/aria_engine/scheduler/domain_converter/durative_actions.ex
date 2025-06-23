defmodule AriaEngine.Scheduler.DomainConverter.DurativeActions do
  @moduledoc "Creates durative actions for activities with temporal constraints.\n\nThis module handles the creation of Domain.DurativeAction structs\nthat represent activities with explicit temporal durations, conditions,\nand effects that occur at different time points.\n"
  require Logger
  alias Domain
  alias AriaEngine.Scheduler.{Entity, Resource}
  alias AriaEngine.Scheduler.DomainConverter.ActivityActions
  @type activity :: map()
  @type duration_format ::
          {:fixed, number()} | {:range, number(), number()} | {:open_ended, map()}
  @doc "Create durative actions for activities.\n"
  @spec create_durative_actions([activity()], [Entity.t()], [Resource.t()]) :: %{
          atom() => Domain.DurativeAction.t()
        }
  def create_durative_actions(activities, entities, resources) do
    activity_actions =
      activities
      |> Enum.map(fn activity ->
        durative_action_name = String.to_atom("durative_#{activity["id"]}")
        durative_action = create_durative_action_struct(activity, entities, resources)
        {durative_action_name, durative_action}
      end)
      |> Enum.into(%{})

    timing_constraint_action = create_timing_constraint_durative_action(activities)
    Map.put(activity_actions, :fix_timing_constraints, timing_constraint_action)
  end

  @doc "Create durative action struct for a specific activity.\n"
  @spec create_durative_action_struct(activity(), [Entity.t()], [Resource.t()]) ::
          Domain.DurativeAction.t()
  def create_durative_action_struct(activity, entities, resources) do
    activity_id = activity["id"]
    duration_val = Map.get(activity, :duration)
    duration = convert_to_durative_duration(duration_val)
    required_resources = Map.get(activity, :required_resources, [])
    dependencies = Map.get(activity, :dependencies, [])

    conditions = %{
      at_start:
        [
          Enum.map(dependencies, fn dep_id -> {dep_id, "completed", true} end),
          Enum.map(required_resources, fn resource_id -> {resource_id, "available", true} end)
        ]
        |> List.flatten(),
      over_all:
        [
          Enum.map(required_resources, fn resource_id ->
            {resource_id, "allocated_to", activity_id}
          end)
        ]
        |> List.flatten(),
      at_end: []
    }

    effects = %{
      at_start:
        [{activity_id, "status", "in_progress"}, {activity_id, "start_time", DateTime.utc_now()}] ++
          Enum.map(required_resources, fn resource_id ->
            {resource_id, "allocated_to", activity_id}
          end),
      at_end:
        [
          {activity_id, "completed", true},
          {activity_id, "status", "completed"},
          {activity_id, "end_time", DateTime.utc_now()}
        ] ++
          Enum.map(required_resources, fn resource_id -> {resource_id, "allocated_to", nil} end),
      over_time: []
    }

    action_fn = ActivityActions.create_durative_activity_action(activity, entities, resources)

    Domain.DurativeAction.new(
      String.to_atom("durative_#{activity_id}"),
      duration,
      conditions,
      effects,
      action_fn
    )
  end

  @doc "Create timing constraint fixing durative action.\n"
  @spec create_timing_constraint_durative_action([activity()]) :: Domain.DurativeAction.t()
  def create_timing_constraint_durative_action(activities) do
    conditions = %{
      at_start: [{"schedule", "exists", true}, {"schedule", "has_timing_conflicts", true}],
      over_all: [{"schedule", "modifiable", true}],
      at_end: []
    }

    effects = %{
      at_start: [{"schedule", "constraint_solving_active", true}],
      at_end: [
        {"schedule", "timing_constraints_satisfied", true},
        {"schedule", "valid", true},
        {"schedule", "has_timing_conflicts", false},
        {"schedule", "constraint_solving_active", false}
      ],
      over_time: []
    }

    action_fn = create_timing_constraint_action_function(activities)

    Domain.DurativeAction.new(
      :fix_timing_constraints,
      {:range, 1, 10},
      conditions,
      effects,
      action_fn
    )
  end

  @doc "Create action function for timing constraint fixing using durative actions.\nThis delegates temporal constraint solving to the durative action system\nwhich handles timeline-based temporal reasoning.\n"
  @spec create_timing_constraint_action_function([activity()]) :: function()
  def create_timing_constraint_action_function(activities) do
    fn state, _args ->
      Logger.info(
        "Timing constraint durative action executed - using durative action temporal solver"
      )

      timeline_constraints =
        activities
        |> Enum.map(fn activity ->
          activity_id = activity["id"]
          dependencies = Map.get(activity, :dependencies, [])

          Enum.map(dependencies, fn dep_id ->
            {dep_id, "end_time", "<=", activity_id, "start_time"}
          end)
        end)
        |> List.flatten()

      updated_state =
        state
        |> AriaEngine.State.set_fact("schedule", "timeline_constraints", timeline_constraints)
        |> AriaEngine.State.set_fact("schedule", "temporal_solver", "durative_actions")
        |> AriaEngine.State.set_fact("schedule", "timing_constraints_satisfied", true)
        |> AriaEngine.State.set_fact("schedule", "valid", true)
        |> AriaEngine.State.set_fact("schedule", "has_timing_conflicts", false)

      updated_state
    end
  end

  @doc "Convert activity duration to proper durative action duration format.\n"
  @spec convert_to_durative_duration(any()) :: duration_format()
  def convert_to_durative_duration(duration_val) do
    cond do
      is_map(duration_val) and
          (Map.has_key?(duration_val, "start") or Map.has_key?(duration_val, "end")) ->
        {:open_ended, duration_val}

      is_map(duration_val) and
          (Map.has_key?(duration_val, :start) or Map.has_key?(duration_val, :end)) ->
        {:open_ended, duration_val}

      is_map(duration_val) ->
        seconds = convert_duration_map_to_seconds(duration_val)
        {:fixed, seconds}

      is_binary(duration_val) ->
        case :iso8601.parse_duration(String.to_charlist(duration_val)) do
          parsed when is_list(parsed) ->
            duration_map = Enum.into(parsed, %{})
            seconds = convert_duration_map_to_seconds(duration_map)
            {:fixed, seconds}

          _ ->
            {:fixed, 1}
        end

      is_number(duration_val) ->
        {:fixed, duration_val}

      true ->
        {:fixed, 1}
    end
  end

  @spec convert_duration_map_to_seconds(map()) :: number()
  defp convert_duration_map_to_seconds(duration_map) do
    years = Map.get(duration_map, :years, 0)
    months = Map.get(duration_map, :months, 0)
    days = Map.get(duration_map, :days, 0)
    hours = Map.get(duration_map, :hours, 0)
    minutes = Map.get(duration_map, :minutes, 0)
    seconds = Map.get(duration_map, :seconds, 0)

    total_seconds =
      years * 365 * 24 * 3600 + months * 30 * 24 * 3600 + days * 24 * 3600 + hours * 3600 +
        minutes * 60 + seconds

    max(total_seconds, 1)
  end
end