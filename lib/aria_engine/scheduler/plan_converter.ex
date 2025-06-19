# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngine.Scheduler.PlanConverter do
  @moduledoc """
  Converts planning results back to scheduler format.
  
  Handles the translation from hybrid planner results (encapsulated plans)
  back to scheduler concepts (schedules with timing and resource assignments).
  """
  
  require Logger
  
  @doc """
  Convert plan to enhanced schedule format.
  """
  def convert_plan_to_enhanced_schedule(encapsulated_plan, activities, entities, resources) do
    try do
      # Extract primitive actions from the plan
      internal_plan = HybridPlanner.DataStructures.EncapsulatedPlan.get_internal_plan(encapsulated_plan)
      primitive_actions = AriaEngine.Plan.Utils.get_primitive_actions_dfs(internal_plan)
      
      # Convert actions to scheduled activities with entity/resource assignments
      scheduled_activities = primitive_actions
      |> Enum.with_index()
      |> Enum.map(fn {{action_name, _args}, index} ->
        activity_id = Atom.to_string(action_name)
        
        # Find original activity
        original_activity = Enum.find(activities, fn act -> act.id == activity_id end)
        
        if original_activity do
          duration = Map.get(original_activity, :duration, 1)
          required_capabilities = Map.get(original_activity, :required_capabilities, [])
          required_resources = Map.get(original_activity, :required_resources, [])
          
          # Assign entities and resources
          assigned_entity = assign_entity_for_activity(original_activity, entities)
          assigned_resources = assign_resources_for_activity(original_activity, resources)
          
          Map.merge(original_activity, %{
            start_time: index * duration,
            end_time: (index + 1) * duration,
            scheduled: true,
            execution_order: index,
            assigned_entity: assigned_entity,
            assigned_resources: assigned_resources,
            resource_requirements: %{
              capabilities: required_capabilities,
              resources: required_resources
            }
          })
        else
          # Fallback if activity not found
          %{
            id: activity_id,
            duration: 1,
            start_time: index,
            end_time: index + 1,
            scheduled: true,
            execution_order: index,
            assigned_entity: nil,
            assigned_resources: [],
            resource_requirements: %{capabilities: [], resources: []}
          }
        end
      end)
      
      scheduled_activities
    rescue
      e ->
        Logger.warning("Failed to convert plan to enhanced schedule: #{Exception.message(e)}")
        # Fallback to simple sequential schedule
        create_fallback_schedule(activities, entities, resources)
    end
  end
  
  @doc """
  Convert simulation results to schedule format.
  """
  def convert_simulation_to_schedule(encapsulated_plan, final_state, activities, entities, resources) do
    # Similar to convert_plan_to_enhanced_schedule but with simulation state information
    schedule = convert_plan_to_enhanced_schedule(encapsulated_plan, activities, entities, resources)
    
    # Enhance with simulation state data
    schedule
    |> Enum.map(fn activity ->
      activity_id = activity.id
      execution_time = AriaEngine.StateV2.get_fact(final_state, activity_id, "execution_time")
      
      Map.merge(activity, %{
        simulation_executed: true,
        simulation_execution_time: execution_time,
        simulation_state: "completed"
      })
    end)
  end
  
  @doc """
  Assign an entity to an activity based on required capabilities.
  """
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
  
  @doc """
  Assign resources to an activity based on required resources.
  """
  def assign_resources_for_activity(activity, resources) do
    required_resources = Map.get(activity, :required_resources, [])
    
    required_resources
    |> Enum.map(fn resource_id ->
      Enum.find(resources, fn resource -> resource.id == resource_id end)
    end)
    |> Enum.filter(& &1)
  end
  
  @doc """
  Create fallback schedule when plan conversion fails.
  """
  def create_fallback_schedule(activities, entities, resources) do
    activities
    |> Enum.with_index()
    |> Enum.map(fn {activity, index} ->
      duration = Map.get(activity, :duration, 1)
      assigned_entity = assign_entity_for_activity(activity, entities)
      assigned_resources = assign_resources_for_activity(activity, resources)
      
      Map.merge(activity, %{
        start_time: index * duration,
        end_time: (index + 1) * duration,
        scheduled: true,
        execution_order: index,
        assigned_entity: assigned_entity,
        assigned_resources: assigned_resources,
        resource_requirements: %{
          capabilities: Map.get(activity, :required_capabilities, []),
          resources: Map.get(activity, :required_resources, [])
        }
      })
    end)
  end
end
