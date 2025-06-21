# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngine.Scheduler.ResourceManager do
  @moduledoc """
  Resource allocation and management for the scheduler.

  Handles resource availability checking, allocation, and release operations
  for activities with resource requirements.
  """

  require Logger

  @doc """
  Allocate resources for an activity.

  Checks if required capabilities and resources are available, then allocates them.
  """
  def allocate_resources_for_activity(
        state,
        activity_id,
        required_capabilities,
        required_resources,
        entities,
        resources
      ) do
    # Find available entity with required capabilities
    available_entity =
      find_available_entity_with_capabilities(state, required_capabilities, entities)

    # Check resource availability
    resources_available =
      Enum.all?(required_resources, fn resource_id ->
        check_single_resource_availability(state, resource_id, resources)
      end)

    if available_entity and resources_available do
      # Allocate entity and resources
      updated_state =
        state
        |> AriaEngine.StateV2.set_fact(available_entity.id, "current_activity", activity_id)
        |> AriaEngine.StateV2.set_fact(available_entity.id, "available", false)

      # Update resource usage
      final_state =
        Enum.reduce(required_resources, updated_state, fn resource_id, acc_state ->
          current_usage =
            AriaEngine.StateV2.get_fact(acc_state, resource_id, "current_usage") || 0

          AriaEngine.StateV2.set_fact(acc_state, resource_id, "current_usage", current_usage + 1)
        end)

      {:ok, final_state}
    else
      {:error, "Required capabilities or resources not available"}
    end
  end

  @doc """
  Release resources for an activity.

  Frees up entity and decrements resource usage counters.
  """
  def release_resources_for_activity(state, activity_id, required_resources, entities) do
    # Find entity currently assigned to this activity
    assigned_entity =
      if Enum.empty?(entities) do
        nil
      else
        Enum.find(entities, fn entity ->
          current_activity = AriaEngine.StateV2.get_fact(state, entity.id, "current_activity")
          current_activity == activity_id
        end)
      end

    # Release entity
    updated_state =
      if assigned_entity do
        state
        |> AriaEngine.StateV2.set_fact(assigned_entity.id, "current_activity", nil)
        |> AriaEngine.StateV2.set_fact(assigned_entity.id, "available", true)
      else
        state
      end

    # Release resources
    final_state =
      Enum.reduce(required_resources, updated_state, fn resource_id, acc_state ->
        current_usage = AriaEngine.StateV2.get_fact(acc_state, resource_id, "current_usage") || 0

        if current_usage > 0 do
          AriaEngine.StateV2.set_fact(acc_state, resource_id, "current_usage", current_usage - 1)
        else
          acc_state
        end
      end)

    {:ok, final_state}
  end

  @doc """
  Check if resources are available for an activity.
  """
  def check_resource_availability(
        state,
        required_capabilities,
        required_resources,
        entities,
        resources
      ) do
    # Check if there's an available entity with required capabilities
    entity_available =
      if Enum.empty?(required_capabilities) do
        true
      else
        find_available_entity_with_capabilities(state, required_capabilities, entities) != nil
      end

    # Check if all required resources have capacity
    resources_available =
      Enum.all?(required_resources, fn resource_id ->
        check_single_resource_availability(state, resource_id, resources)
      end)

    entity_available and resources_available
  end

  @doc """
  Find an available entity with the required capabilities.
  """
  def find_available_entity_with_capabilities(state, required_capabilities, entities) do
    # Return nil if no entities available
    if Enum.empty?(entities) do
      nil
    else
      Enum.find(entities, fn entity ->
        is_available = AriaEngine.StateV2.matches_exactly?(state, entity.id, "available", true)

        has_capabilities =
          Enum.all?(required_capabilities, fn cap ->
            Enum.member?(entity.capabilities || [], cap)
          end)

        is_available and has_capabilities
      end)
    end
  end

  @doc """
  Check if a single resource has available capacity.
  """
  def check_single_resource_availability(state, resource_id, resources) do
    resource = Enum.find(resources, fn r -> r.id == resource_id end)

    if resource do
      current_usage = AriaEngine.StateV2.get_fact(state, resource_id, "current_usage") || 0
      current_usage < resource.capacity
    else
      false
    end
  end

  @doc """
  Create resource management actions for the domain.
  """
  def create_resource_management_actions(resources) do
    resources
    |> Enum.flat_map(fn resource ->
      [
        {String.to_atom("allocate_#{resource.id}"), create_allocate_resource_action(resource)},
        {String.to_atom("release_#{resource.id}"), create_release_resource_action(resource)}
      ]
    end)
    |> Enum.into(%{})
  end

  @doc """
  Get current resource utilization snapshot.
  """
  def get_resource_utilization_snapshot(state, resources) do
    resources
    |> Enum.map(fn resource ->
      current_usage = AriaEngine.StateV2.get_fact(state, resource.id, "current_usage") || 0

      utilization_percentage =
        if resource.capacity > 0 do
          current_usage / resource.capacity * 100
        else
          0
        end

      {resource.id,
       %{
         current_usage: current_usage,
         capacity: resource.capacity,
         utilization_percentage: utilization_percentage,
         available_capacity: resource.capacity - current_usage
       }}
    end)
    |> Enum.into(%{})
  end

  @doc """
  Validate resource constraints for a set of activities.
  """
  def validate_resource_constraints(activities, resources) do
    # Check if any activity requires more resources than available capacity
    violations =
      activities
      |> Enum.flat_map(fn activity ->
        required_resources = Map.get(activity, :required_resources, [])

        required_resources
        |> Enum.map(fn resource_id ->
          resource = Enum.find(resources, fn r -> r.id == resource_id end)

          if resource && resource.capacity < 1 do
            {activity.id, resource_id, "Insufficient capacity"}
          else
            nil
          end
        end)
        |> Enum.filter(&(&1 != nil))
      end)

    if Enum.empty?(violations) do
      :ok
    else
      {:error, violations}
    end
  end

  # Private helper functions

  defp create_allocate_resource_action(resource) do
    fn _args, state ->
      current_usage = AriaEngine.StateV2.get_fact(state, resource.id, "current_usage") || 0

      if current_usage < resource.capacity do
        AriaEngine.StateV2.set_fact(state, resource.id, "current_usage", current_usage + 1)
      else
        false
      end
    end
  end

  defp create_release_resource_action(resource) do
    fn _args, state ->
      current_usage = AriaEngine.StateV2.get_fact(state, resource.id, "current_usage") || 0

      if current_usage > 0 do
        AriaEngine.StateV2.set_fact(state, resource.id, "current_usage", current_usage - 1)
      else
        state
      end
    end
  end
end
