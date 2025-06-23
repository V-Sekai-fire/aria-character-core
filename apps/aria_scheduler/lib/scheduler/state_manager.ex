# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngine.Scheduler.StateManager do
  @moduledoc "Manages state creation and resource allocation for the scheduler.\n\nHandles the creation of initial states with entities and resources,\nand manages resource allocation during planning execution.\n"
  require Logger
  @doc "Create enhanced initial state with entities and resources.\n"
  def create_enhanced_initial_state(entities, resources) do
    initial_state = AriaEngine.State.new()

    state_with_entities =
      entities
      |> Enum.reduce(initial_state, fn entity, state ->
        state
        |> AriaEngine.State.set_fact(entity.id, "type", entity.type)
        |> AriaEngine.State.set_fact(entity.id, "capabilities", entity.capabilities)
        |> AriaEngine.State.set_fact(entity.id, "available", true)
        |> AriaEngine.State.set_fact(entity.id, "current_activity", nil)
        |> AriaEngine.State.set_fact(entity.id, "resources_held", entity.resources_held || [])
      end)

    resources
    |> Enum.reduce(state_with_entities, fn resource, state ->
      state
      |> AriaEngine.State.set_fact(resource.id, "type", resource.type)
      |> AriaEngine.State.set_fact(resource.id, "capacity", resource.capacity)
      |> AriaEngine.State.set_fact(resource.id, "current_usage", resource.current_usage || 0)
      |> AriaEngine.State.set_fact(resource.id, "available", true)
    end)
  end

  @doc "Convert activities to tasks and goals format.\n"
  def convert_activities_to_tasks_and_goals(activities) do
    tasks = [{"schedule_activities", []}]

    goals =
      activities
      |> Enum.map(fn activity ->
        activity_id =
          if is_map(activity) and Map.has_key?(activity, "id") do
            Map.get(activity, "id")
          else
            Map.get(activity, :id)
          end

        {activity_id, "completed", true}
      end)

    {tasks, goals}
  end

  @doc "Convert activities to goals format (legacy support).\n"
  def convert_activities_to_goals(activities) do
    {_tasks, goals} = convert_activities_to_tasks_and_goals(activities)
    goals
  end

  @doc "Allocate resources for an activity.\n"
  def allocate_resources_for_activity(
        state,
        activity_id,
        required_capabilities,
        required_resources,
        entities,
        resources
      ) do
    available_entity =
      find_available_entity_with_capabilities(state, required_capabilities, entities)

    resources_available =
      Enum.all?(required_resources, fn resource_id ->
        check_single_resource_availability(state, resource_id, resources)
      end)

    if available_entity and resources_available do
      updated_state =
        state
        |> AriaEngine.State.set_fact(available_entity.id, "current_activity", activity_id)
        |> AriaEngine.State.set_fact(available_entity.id, "available", false)

      final_state =
        Enum.reduce(required_resources, updated_state, fn resource_id, acc_state ->
          current_usage = AriaEngine.State.get_fact(acc_state, resource_id, "current_usage") || 0
          AriaEngine.State.set_fact(acc_state, resource_id, "current_usage", current_usage + 1)
        end)

      {:ok, final_state}
    else
      {:error, "Required capabilities or resources not available"}
    end
  end

  @doc "Check resource availability for an activity.\n"
  def check_resource_availability(
        state,
        required_capabilities,
        required_resources,
        entities,
        resources
      ) do
    entity_available =
      if Enum.empty?(required_capabilities) do
        true
      else
        find_available_entity_with_capabilities(state, required_capabilities, entities) != nil
      end

    resources_available =
      Enum.all?(required_resources, fn resource_id ->
        check_single_resource_availability(state, resource_id, resources)
      end)

    entity_available and resources_available
  end

  defp find_available_entity_with_capabilities(state, required_capabilities, entities) do
    if Enum.empty?(entities) or Enum.empty?(required_capabilities) do
      nil
    else
      Enum.find(entities, fn entity ->
        is_available = AriaEngine.State.matches_exactly?(state, entity.id, "available", true)

        has_capabilities =
          Enum.all?(required_capabilities, fn cap ->
            Enum.member?(entity.capabilities || [], cap)
          end)

        is_available and has_capabilities
      end)
    end
  end

  defp check_single_resource_availability(state, resource_id, resources) do
    resource = Enum.find(resources, fn r -> r.id == resource_id end)

    if resource do
      current_usage = AriaEngine.State.get_fact(state, resource_id, "current_usage") || 0
      current_usage < resource.capacity
    else
      false
    end
  end
end