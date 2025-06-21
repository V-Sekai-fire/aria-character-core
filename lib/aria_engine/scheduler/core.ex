# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngine.Scheduler.Core do
  @moduledoc """
  Private implementation core for AriaEngine.Scheduler.
  
  Orchestrates the scheduling process by coordinating between specialized modules
  for domain conversion, state management, plan conversion, and analysis.
  
  This module should not be used directly - use AriaEngine.Scheduler instead.
  """
  
  require Logger
  
  alias AriaEngine.Scheduler.{DomainConverter, StateManager, PlanConverter, ResourceManager}
  
  @doc """
  Main scheduling function with enhanced features.
  """
  def schedule_with_enhanced_features(schedule_name, activities, entities, resources, constraints, simulation_mode, activity_log, verbose) do
    if verbose > 1 do
      Logger.debug("AriaEngine.Scheduler: Initializing enhanced scheduling system")
    end
    
    # Handle empty activities case
    if Enum.empty?(activities) do
      return_empty_schedule_result(schedule_name, entities, resources, simulation_mode, activity_log)
    else
      
      # Attempt enhanced scheduling
      case attempt_enhanced_scheduling(schedule_name, activities, entities, resources, constraints, simulation_mode, activity_log, verbose) do
        {:ok, schedule} ->
          default_analysis = %{
            schedule_name: schedule_name,
            method: "Critical Path Method with Enhanced Resource-Aware Scheduling",
            activities_analyzed: 0,
            dependencies_found: 0,
            resource_conflicts: 0,
            circular_dependencies: 0,
            critical_path_length: 0,
            simulation_mode: simulation_mode,
            entities_used: length(entities),
            resources_managed: length(resources),
            hybrid_planner_used: true,
            empty_plan_reason: "Empty todo list results in empty plan (valid solution)"
          }
          result = %AriaEngine.Scheduler.SimulationResult{
            status: "success",
            reason: if(simulation_mode, do: "Simulation completed successfully", else: "Schedule successfully generated"),
            schedule: schedule,
            analysis: default_analysis,
            resource_utilization: %{},
            simulation_metadata: %{
              generated_at: DateTime.utc_now(),
              simulation_duration: 0,
              entities_count: length(entities),
              resources_count: length(resources)
            }
          }
          {:ok, result}
          
        {:error, reason} ->
          {:error, reason}
      end
    end
  end
  
  @doc """
  Handle empty activities case.
  """
  def return_empty_schedule_result(schedule_name, entities, resources, simulation_mode, _activity_log) do
    default_analysis = %{
      schedule_name: schedule_name,
      method: "Critical Path Method with Enhanced Resource-Aware Scheduling",
      activities_analyzed: 0,
      dependencies_found: 0,
      resource_conflicts: 0,
      circular_dependencies: 0,
      critical_path_length: 0,
      simulation_mode: simulation_mode,
      entities_used: length(entities),
      resources_managed: length(resources),
      hybrid_planner_used: true,
      empty_plan_reason: "Empty todo list results in empty plan (valid solution)"
    }
    result = %AriaEngine.Scheduler.SimulationResult{
      status: "success",
      reason: "Empty plan successfully generated - valid solution for empty todo list",
      schedule: [],
      analysis: default_analysis,
      resource_utilization: %{},
      simulation_metadata: %{
        generated_at: DateTime.utc_now(),
        simulation_duration: 0,
        entities_count: length(entities),
        resources_count: length(resources)
      }
    }
  
    {:ok, result}
  end
  
  
  @doc """
  Enhanced scheduling with entity/resource management.
  """
  def attempt_enhanced_scheduling(_schedule_name, activities, entities, resources, constraints, simulation_mode, activity_log, verbose, opts \\ []) do
    Logger.info("🔧 Scheduler.Core.attempt_enhanced_scheduling() called with #{length(activities)} activities")
    Logger.info("🔧 Entities: #{length(entities)}, Resources: #{length(resources)}")
    Logger.info("🔧 Verbose: #{verbose}, Simulation mode: #{simulation_mode}")
    
    if verbose > 1 do
      Logger.debug("AriaEngine.Scheduler: Attempting enhanced scheduling with #{length(entities)} entities and #{length(resources)} resources")
    end
    
    # Convert to domain format for hybrid planner
    Logger.info("🔧 Calling convert_activities_to_enhanced_domain()...")
    case convert_activities_to_enhanced_domain(activities, entities, resources, constraints) do
      {:ok, domain} ->
        Logger.info("🔧 Domain conversion successful!")
        # Create enhanced initial state with entities and resources
        Logger.info("🔧 Creating enhanced initial state...")
        initial_state = create_enhanced_initial_state(entities, resources)
        
        # Generate tasks and goals from activities
        Logger.info("🔧 Converting activities to tasks and goals...")
        {tasks, goals} = StateManager.convert_activities_to_tasks_and_goals(activities)
        Logger.info("🔧 Generated #{length(tasks)} tasks and #{length(goals)} goals")
        
        if verbose > 2 do
          Logger.debug("AriaEngine.Scheduler: Created enhanced domain with #{map_size(domain.actions)} actions")
          Logger.debug("AriaEngine.Scheduler: Generated #{length(tasks)} tasks and #{length(goals)} goals")
        end
        
        # Use AriaEngine.PlannerAdapter for HTN task decomposition with temporal validation
        Logger.info("🔧 About to call AriaEngine.PlannerAdapter.plan_tasks()...")
        planner_opts = [verbose: verbose]
        case AriaEngine.PlannerAdapter.plan_tasks(domain, initial_state, tasks, planner_opts) do
          {:ok, solution_tree} ->
            # Wrap raw solution tree in EncapsulatedPlan for PlanConverter compatibility
            encapsulated_plan = HybridPlanner.DataStructures.EncapsulatedPlan.new(solution_tree, %{
              source: "AriaEngine.PlannerAdapter.plan_tasks",
              scheduler_wrapped: true
            })
            
            if simulation_mode do
              # Run simulation using run_lazy_refineahead
              simulate_plan_execution(domain, initial_state, encapsulated_plan, activities, entities, resources, activity_log, verbose)
            else
              # Convert plan to schedule format
              base_datetime =
                Keyword.get(opts, :base_datetime) ||
                  DateTime.utc_now()
              schedule = convert_plan_to_enhanced_schedule(encapsulated_plan, activities, entities, resources, base_datetime)
              
              {:ok, schedule}
            end
          {:error, reason} ->
            {:error, "Enhanced planning failed: #{reason}"}
        end
      {:error, reason} ->
        Logger.error("🔧 Domain conversion FAILED: #{reason}")
        {:error, "Enhanced domain conversion failed: #{reason}"}
    end
  end
  
  @doc """
  Simulate plan execution using run_lazy_refineahead.
  """
  def simulate_plan_execution(domain, initial_state, encapsulated_plan, activities, entities, resources, _activity_log, verbose) do
    if verbose > 1 do
      Logger.debug("AriaEngine.Scheduler: Running simulation with run_lazy_refineahead")
    end
    
    # Extract internal plan from encapsulated plan
    internal_plan = HybridPlanner.DataStructures.EncapsulatedPlan.get_internal_plan(encapsulated_plan)
    
    # Execute plan using run_lazy_refineahead
    case Plan.run_lazy_refineahead(domain, initial_state, internal_plan, [verbose: verbose]) do
      {:ok, final_state} ->
        # Convert simulation results to schedule format
        schedule = convert_simulation_to_schedule(encapsulated_plan, final_state, activities, entities, resources)
        
        {:ok, schedule}
      {:error, reason} ->
        {:error, "Simulation execution failed: #{reason}"}
    end
  end
  
  @doc """
  Convert activities to KHR domain with two-phase planning.
  """
  def convert_activities_to_enhanced_domain(activities, entities, resources, constraints) do
    DomainConverter.convert_activities_to_khr_domain(activities, entities, resources, constraints)
  end
  
  @doc """
  Create enhanced initial state with entities and resources.
  """
  def create_enhanced_initial_state(entities, resources) do
    StateManager.create_enhanced_initial_state(entities, resources)
  end
  
  @doc """
  Convert activities to goals format.
  """
  def convert_activities_to_goals(activities) do
    StateManager.convert_activities_to_goals(activities)
  end
  
  @doc """
  Create enhanced activity action with resource management.
  """
  def create_enhanced_activity_action(activity, entities, resources) do
    fn _args, state ->
      activity_id = activity.id
      duration_val = Map.get(activity, :duration)
      {duration, fixed_start, fixed_end} =
        cond do
          is_map(duration_val) and Map.has_key?(duration_val, :start) and Map.has_key?(duration_val, :end) ->
            {duration_val, duration_val[:start], duration_val[:end]}
          is_map(duration_val) ->
            {duration_val, nil, nil}
          is_binary(duration_val) ->
            case :iso8601.parse_duration(String.to_charlist(duration_val)) do
              parsed when is_list(parsed) ->
                map = Enum.into(parsed, %{})
                {map, nil, nil}
              _ -> {nil, nil, nil}
            end
          true ->
            {nil, nil, nil}
        end
      required_capabilities = Map.get(activity, :required_capabilities, [])
      required_resources = Map.get(activity, :required_resources, [])
      
      # Check if required capabilities and resources are available
      case allocate_resources_for_activity(state, activity_id, required_capabilities, required_resources, entities, resources) do
        {:ok, updated_state} ->
          # Mark activity as completed and update resource usage
          updated_state
          |> AriaEngine.StateV2.set_fact(activity_id, "completed", true)
          |> AriaEngine.StateV2.set_fact(activity_id, "duration", duration)
          |> AriaEngine.StateV2.set_fact(activity_id, "execution_time", DateTime.utc_now())
        
        {:error, _reason} ->
          # Resource allocation failed
          false
      end
    end
  end
  
  @doc """
  Create enhanced activity method with resource constraints.
  """
  def create_enhanced_activity_method(activity, entities, resources) do
    fn _args, state ->
      activity_id = activity.id
      dependencies = Map.get(activity, :dependencies, [])
      required_capabilities = Map.get(activity, :required_capabilities, [])
      required_resources = Map.get(activity, :required_resources, [])
      
      # Check if dependencies are satisfied
      deps_satisfied = Enum.all?(dependencies, fn dep_id ->
        AriaEngine.StateV2.matches_exactly?(state, dep_id, "completed", true)
      end)
      
      # Check if required capabilities and resources are available
      resources_available = check_resource_availability(state, required_capabilities, required_resources, entities, resources)
      
      if deps_satisfied and resources_available do
        # Return action to complete this activity
        [{String.to_atom(activity_id), []}]
      else
        # Dependencies not satisfied or resources unavailable
        incomplete_deps = Enum.filter(dependencies, fn dep_id ->
          not AriaEngine.StateV2.matches_exactly?(state, dep_id, "completed", true)
        end)
        
        if not Enum.empty?(incomplete_deps) do
          # Return tasks to complete dependencies first
          dep_tasks = Enum.map(incomplete_deps, fn dep_id ->
            "complete_#{dep_id}"
          end)
          dep_tasks ++ [{String.to_atom(activity_id), []}]
        else
          # Resources unavailable - return false to try later
          false
        end
      end
    end
  end
  
  # Resource management helper functions (delegated to ResourceManager)
  
  defp allocate_resources_for_activity(state, activity_id, required_capabilities, required_resources, entities, resources) do
    ResourceManager.allocate_resources_for_activity(state, activity_id, required_capabilities, required_resources, entities, resources)
  end
  
  
  defp check_resource_availability(state, required_capabilities, required_resources, entities, resources) do
    ResourceManager.check_resource_availability(state, required_capabilities, required_resources, entities, resources)
  end
  
  
  @doc """
  Create resource management actions.
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
  
  @doc """
  Create enhanced scheduling methods.
  """
  def create_enhanced_scheduling_methods(activities, _entities, _resources) do
    %{
      "schedule_all" => [{
        "resource_aware_sequential", fn _args, _state ->
          # Return all activities as sequential tasks with resource considerations
          activities
          |> Enum.map(fn activity ->
            "complete_#{activity.id}"
          end)
        end
      }]
    }
  end
  
  @doc """
  Create action metadata for durative actions.
  """
  def create_action_metadata(activities, _entities, _resources) do
    activities
    |> Enum.map(fn activity ->
      action_name = String.to_atom(activity.id)
      duration_val = Map.get(activity, :duration)
      {duration, fixed_start, fixed_end} =
        cond do
          is_map(duration_val) and Map.has_key?(duration_val, :start) and Map.has_key?(duration_val, :end) ->
            {duration_val, duration_val[:start], duration_val[:end]}
          is_map(duration_val) ->
            {duration_val, nil, nil}
          is_binary(duration_val) ->
            case :iso8601.parse_duration(String.to_charlist(duration_val)) do
              parsed when is_list(parsed) ->
                map = Enum.into(parsed, %{})
                {map, nil, nil}
              _ -> {nil, nil, nil}
            end
          true ->
            {nil, nil, nil}
        end
      
      metadata = %{
        duration: {duration, duration},
        required_capabilities: Map.get(activity, :required_capabilities, []),
        required_resources: Map.get(activity, :required_resources, []),
        activity_type: Map.get(activity, :type, :standard)
      }
      
      {action_name, metadata}
    end)
    |> Enum.into(%{})
  end
  
  @doc """
  Convert plan to enhanced schedule format.
  """
  def convert_plan_to_enhanced_schedule(encapsulated_plan, activities, entities, resources, base_datetime) do
    PlanConverter.convert_plan_to_enhanced_schedule(encapsulated_plan, activities, entities, resources, base_datetime)
  end
  
  @doc """
  Convert simulation results to schedule format.
  """
  def convert_simulation_to_schedule(encapsulated_plan, final_state, activities, entities, resources) do
    base_datetime = DateTime.utc_now()
    PlanConverter.convert_simulation_to_schedule(encapsulated_plan, final_state, activities, entities, resources, base_datetime)
  end
  
  # Entity and resource assignment helpers (delegated to specialized modules)
  
  # Resource utilization calculation functions
  
  
end
