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
    # Extract primitive actions from the plan
    internal_plan = HybridPlanner.DataStructures.EncapsulatedPlan.get_internal_plan(encapsulated_plan)
    primitive_actions = AriaEngine.Plan.Utils.get_primitive_actions_dfs(internal_plan)
    
    # Convert actions to scheduled activities with proper timing and assignments
    scheduled_activities = primitive_actions
    |> Enum.with_index()
    |> Enum.map(fn {action_step, index} ->
      # Handle different action step formats
      activity_id = case action_step do
        {action_name, _args} when is_atom(action_name) -> 
          Atom.to_string(action_name)
        {action_name, _args} when is_binary(action_name) -> 
          action_name
        action_name when is_atom(action_name) -> 
          Atom.to_string(action_name)
        action_name when is_binary(action_name) -> 
          action_name
        other -> 
          Logger.warning("Unexpected action step format: #{inspect(other)}")
          "unknown_action_#{index}"
      end
      
      # Find original activity
      original_activity = Enum.find(activities, fn act -> act.id == activity_id end)
      
      if original_activity do
        duration = Map.get(original_activity, :duration, 1)
        required_capabilities = Map.get(original_activity, :required_capabilities, [])
        required_resources = Map.get(original_activity, :required_resources, [])
        
        # Assign entities and resources with improved logic
        assigned_entity = assign_entity_for_activity(original_activity, entities)
        assigned_resources = assign_resources_for_activity(original_activity, resources)
        
        # Get the first required resource for compatibility with JSON generator
        primary_resource = case required_resources do
          [first_resource | _] -> first_resource
          [] -> nil
        end
        
        # Store activity with temporary timing (will be fixed in Phase 2)
        Map.merge(original_activity, %{
          start_time: index * duration,
          end_time: (index + 1) * duration,
          scheduled: true,
          execution_order: index,
          assigned_entity: assigned_entity,
          assigned_resources: assigned_resources,
          # Add fields expected by JSON generator
          agent_id: if(assigned_entity, do: assigned_entity.id, else: nil),
          resource_id: primary_resource,
          resource_requirements: %{
            capabilities: required_capabilities,
            resources: required_resources
          }
        })
      else
        # Return error if activity not found in original list
        raise "Activity #{activity_id} from plan not found in original activities list"
      end
    end)
    
    # Phase 2: Fix timing to respect dependencies
    scheduled_activities_with_proper_timing = fix_timing_constraints(scheduled_activities, activities)
    
    scheduled_activities_with_proper_timing
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
  Fix timing constraints to respect dependencies.
  """
  def fix_timing_constraints(scheduled_activities, original_activities) do
    # Create a map for quick lookup of dependencies
    dependency_map = original_activities
    |> Enum.map(fn activity -> 
      {activity.id, Map.get(activity, :dependencies, [])} 
    end)
    |> Enum.into(%{})
    
    # Create a map for quick lookup of scheduled activities
    activity_map = scheduled_activities
    |> Enum.map(fn activity -> {activity.id, activity} end)
    |> Enum.into(%{})
    
    # Calculate proper start times based on dependencies
    scheduled_activities
    |> Enum.map(fn activity ->
      dependencies = Map.get(dependency_map, activity.id, [])
      
      # Calculate earliest start time based on dependencies
      earliest_start = if Enum.empty?(dependencies) do
        0
      else
        dependencies
        |> Enum.map(fn dep_id ->
          case Map.get(activity_map, dep_id) do
            nil -> 0
            dep_activity -> dep_activity.end_time
          end
        end)
        |> Enum.max()
      end
      
      # Update timing
      duration = Map.get(activity, :duration, 1)
      %{activity | 
        start_time: earliest_start,
        end_time: earliest_start + duration
      }
    end)
  end
  
end
