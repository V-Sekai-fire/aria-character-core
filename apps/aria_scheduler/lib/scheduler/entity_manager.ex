# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngine.Scheduler.EntityManager do
  @moduledoc "Manages entity allocation and capabilities.\n\nHandles the assignment of entities to activities based on required\ncapabilities and availability constraints.\n"
  require Logger
  alias AriaEngine.Scheduler.DurationParser
  @type entity :: AriaEngine.Scheduler.Entity.t()
  @type activity :: AriaEngine.Scheduler.activity()
  @type state :: AriaEngine.Scheduler.state()
  @type entity_list :: AriaEngine.Scheduler.entity_list()
  @type capability :: atom()
  @type entity_id :: String.t()
  @type activity_id :: String.t()
  @type utilization_metrics :: %{
          status: :available | :busy | :unknown,
          current_activity: String.t() | nil,
          capabilities: [capability()],
          availability_score: number()
        }
  @type workload_metrics :: %{
          assigned_activities: non_neg_integer(),
          activity_ids: [String.t()],
          capabilities: [capability()],
          workload_score: number()
        }
  @type workload_distribution :: %{
          entity_workloads: %{entity_id() => workload_metrics()},
          total_activities: non_neg_integer(),
          average_workload: float(),
          max_workload: non_neg_integer(),
          min_workload: non_neg_integer(),
          workload_variance: float()
        }
  @doc "Assign an entity to an activity based on capability requirements.\n"
  @spec assign_entity_for_activity(activity(), entity_list()) :: entity() | nil
  def assign_entity_for_activity(activity, entities) do
    required_capabilities = Map.get(activity, :required_capabilities, [])

    if Enum.empty?(required_capabilities) do
      nil
    else
      Enum.find(entities, fn entity ->
        Enum.all?(required_capabilities, fn cap ->
          Enum.member?(entity.capabilities || [], cap)
        end)
      end)
    end
  end

  @doc "Find the best available entity for an activity.\n\nConsiders both capability matching and current availability.\n"
  @spec find_best_available_entity(state(), activity(), entity_list()) :: entity() | nil
  def find_best_available_entity(state, activity, entities) do
    if Enum.empty?(entities) do
      nil
    else
      required_capabilities = Map.get(activity, :required_capabilities, [])

      if Enum.empty?(required_capabilities) do
        find_any_available_entity(state, entities)
      else
        entities
        |> Enum.filter(fn entity ->
          is_available = AriaEngine.State.matches_exactly?(state, entity.id, "available", true)

          has_capabilities =
            Enum.all?(required_capabilities, fn cap ->
              Enum.member?(entity.capabilities || [], cap)
            end)

          is_available and has_capabilities
        end)
        |> select_optimal_entity(required_capabilities)
      end
    end
  end

  @doc "Get entity utilization metrics.\n"
  @spec get_entity_utilization(state(), entity_list()) :: %{entity_id() => utilization_metrics()}
  def get_entity_utilization(state, entities) do
    entities
    |> Enum.map(fn entity ->
      is_available = AriaEngine.State.matches_exactly?(state, entity.id, "available", true)
      current_activity = AriaEngine.State.get_fact(state, entity.id, "current_activity")

      utilization_status =
        cond do
          current_activity != nil -> :busy
          is_available -> :available
          true -> :unknown
        end

      {entity.id,
       %{
         status: utilization_status,
         current_activity: current_activity,
         capabilities: entity.capabilities || [],
         availability_score: calculate_availability_score(entity, state)
       }}
    end)
    |> Enum.into(%{})
  end

  @doc "Initialize entity states in the planning state.\n"
  def initialize_entity_states(state, entities) do
    Enum.reduce(entities, state, fn entity, acc_state ->
      acc_state
      |> AriaEngine.State.set_fact(entity.id, "available", true)
      |> AriaEngine.State.set_fact(entity.id, "current_activity", nil)
      |> AriaEngine.State.set_fact(entity.id, "capabilities", entity.capabilities || [])
      |> AriaEngine.State.set_fact(entity.id, "entity_type", Map.get(entity, :type, "generic"))
    end)
  end

  @doc "Reserve an entity for an activity.\n"
  def reserve_entity(state, entity_id, activity_id) do
    state
    |> AriaEngine.State.set_fact(entity_id, "available", false)
    |> AriaEngine.State.set_fact(entity_id, "current_activity", activity_id)
    |> AriaEngine.State.set_fact(entity_id, "reserved_at", DateTime.utc_now())
  end

  @doc "Release an entity from an activity.\n"
  def release_entity(state, entity_id) do
    state
    |> AriaEngine.State.set_fact(entity_id, "available", true)
    |> AriaEngine.State.set_fact(entity_id, "current_activity", nil)
    |> AriaEngine.State.set_fact(entity_id, "released_at", DateTime.utc_now())
  end

  @doc "Check if an entity has the required capabilities.\n"
  def entity_has_capabilities?(entity, required_capabilities) do
    entity_capabilities = entity.capabilities || []
    Enum.all?(required_capabilities, fn cap -> Enum.member?(entity_capabilities, cap) end)
  end

  @doc "Get entities by capability.\n"
  def get_entities_by_capability(entities, capability) do
    Enum.filter(entities, fn entity -> Enum.member?(entity.capabilities || [], capability) end)
  end

  @doc "Calculate entity workload distribution.\n"
  def calculate_workload_distribution(activities, entities) do
    entity_workloads =
      entities
      |> Enum.map(fn entity ->
        assigned_activities =
          activities
          |> Enum.filter(fn activity ->
            assigned_entity = assign_entity_for_activity(activity, entities)
            assigned_entity && assigned_entity.id == entity.id
          end)

        {entity.id,
         %{
           assigned_activities: length(assigned_activities),
           activity_ids: Enum.map(assigned_activities, & &1.id),
           capabilities: entity.capabilities || [],
           workload_score: calculate_workload_score(assigned_activities)
         }}
      end)
      |> Enum.into(%{})

    workload_values =
      entity_workloads |> Enum.map(fn {_id, metrics} -> metrics.assigned_activities end)

    %{
      entity_workloads: entity_workloads,
      total_activities: length(activities),
      average_workload:
        if length(entities) > 0 do
          length(activities) / length(entities)
        else
          0
        end,
      max_workload: Enum.max(workload_values ++ [0]),
      min_workload: Enum.min(workload_values ++ [0]),
      workload_variance: calculate_variance(workload_values)
    }
  end

  @doc "Suggest entity optimizations.\n"
  def suggest_entity_optimizations(workload_distribution) do
    recommendations = []
    variance = workload_distribution.workload_variance

    recommendations =
      if variance > 2.0 do
        [
          "High workload variance detected. Consider redistributing activities for better balance."
          | recommendations
        ]
      else
        recommendations
      end

    overloaded =
      workload_distribution.entity_workloads
      |> Enum.filter(fn {_id, metrics} ->
        metrics.assigned_activities > workload_distribution.average_workload * 1.5
      end)

    recommendations =
      if not Enum.empty?(overloaded) do
        overloaded_ids = Enum.map(overloaded, fn {id, _} -> id end)

        [
          "Overloaded entities detected: #{Enum.join(overloaded_ids, ", ")}. Consider adding more entities with similar capabilities."
          | recommendations
        ]
      else
        recommendations
      end

    underutilized =
      workload_distribution.entity_workloads
      |> Enum.filter(fn {_id, metrics} -> metrics.assigned_activities == 0 end)

    recommendations =
      if not Enum.empty?(underutilized) do
        underutilized_ids = Enum.map(underutilized, fn {id, _} -> id end)

        [
          "Underutilized entities detected: #{Enum.join(underutilized_ids, ", ")}. Consider reassigning capabilities or removing excess entities."
          | recommendations
        ]
      else
        recommendations
      end

    recommendations
  end

  @doc "Validate entity capability coverage.\n"
  def validate_capability_coverage(activities, entities) do
    required_capabilities =
      activities
      |> Enum.flat_map(fn activity -> Map.get(activity, :required_capabilities, []) end)
      |> Enum.uniq()

    available_capabilities =
      entities |> Enum.flat_map(fn entity -> entity.capabilities || [] end) |> Enum.uniq()

    missing_capabilities = required_capabilities -- available_capabilities

    if Enum.empty?(missing_capabilities) do
      :ok
    else
      {:error, "Missing capabilities: #{Enum.join(missing_capabilities, ", ")}"}
    end
  end

  defp find_any_available_entity(state, entities) do
    Enum.find(entities, fn entity ->
      AriaEngine.State.matches_exactly?(state, entity.id, "available", true)
    end)
  end

  defp select_optimal_entity([], _required_capabilities) do
    nil
  end

  defp select_optimal_entity(available_entities, required_capabilities) do
    available_entities
    |> Enum.min_by(fn entity ->
      extra_capabilities = (entity.capabilities || []) -- required_capabilities
      length(extra_capabilities)
    end)
  end

  defp calculate_availability_score(entity, state) do
    is_available = AriaEngine.State.matches_exactly?(state, entity.id, "available", true)
    capability_count = length(entity.capabilities || [])

    base_score =
      if is_available do
        100
      else
        0
      end

    capability_bonus = min(capability_count * 5, 50)
    base_score + capability_bonus
  end

  defp calculate_workload_score(activities) do
    total_duration =
      activities
      |> Enum.map(fn activity ->
        duration_val = Map.get(activity, :duration)

        cond do
          is_map(duration_val) and Map.has_key?(duration_val, :start) and
              Map.has_key?(duration_val, :end) ->
            {:ok, start_dt, _} = DateTime.from_iso8601(duration_val[:start])
            {:ok, end_dt, _} = DateTime.from_iso8601(duration_val[:end])
            DateTime.diff(end_dt, start_dt)

          is_map(duration_val) ->
            AriaEngine.Utils.duration_struct_to_seconds(duration_val)

          is_binary(duration_val) ->
            case DurationParser.parse_duration(duration_val) do
              {:ok, duration_map} ->
                AriaEngine.Utils.duration_struct_to_seconds(duration_map)

              {:error, _reason} ->
                0
            end

          true ->
            0
        end
      end)
      |> Enum.sum()

    activity_count = length(activities)
    total_duration * 2 + activity_count
  end

  defp calculate_variance(values) when length(values) <= 1 do
    0.0
  end

  defp calculate_variance(values) do
    mean = Enum.sum(values) / length(values)
    variance_sum = values |> Enum.map(fn value -> :math.pow(value - mean, 2) end) |> Enum.sum()
    variance_sum / length(values)
  end
end
