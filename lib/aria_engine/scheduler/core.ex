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
  
  alias AriaEngine.{StateV2}
  alias AriaEngine.Scheduler.{SimulationResult}
  alias AriaEngine.Scheduler.{DomainConverter, StateManager, PlanConverter, ResourceAnalyzer, ActivityLogger, Analyzer, ResourceManager, EntityManager}
  
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
      # Analyze activities and resources
      analysis = analyze_activities_with_resources(activities, entities, resources, verbose)
      
      # Attempt enhanced scheduling
      case attempt_enhanced_scheduling(schedule_name, activities, entities, resources, constraints, simulation_mode, activity_log, verbose) do
        {:ok, schedule, enhanced_activity_log, resource_utilization, timeline} ->
          result = %SimulationResult{
            status: "success",
            reason: if(simulation_mode, do: "Simulation completed successfully", else: "Schedule successfully generated"),
            schedule: schedule,
            analysis: Map.merge(analysis, %{
              schedule_name: schedule_name,
              method: "Critical Path Method with Enhanced Resource-Aware Scheduling",
              simulation_mode: simulation_mode,
              entities_used: length(entities),
              resources_managed: length(resources)
            }),
            activity_log: enhanced_activity_log,
            resource_utilization: resource_utilization,
            timeline: timeline,
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
  def return_empty_schedule_result(schedule_name, entities, resources, simulation_mode, activity_log) do
      analysis = %{
        schedule_name: schedule_name,
        method: "Enhanced Resource-Aware Scheduling",
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
    
    result = %SimulationResult{
      status: "success",
      reason: "Empty plan successfully generated - valid solution for empty todo list",
      schedule: [],
      analysis: analysis,
      activity_log: activity_log || [],
      resource_utilization: %{},
      timeline: [],
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
  Enhanced activity analysis with resource considerations.
  """
  def analyze_activities_with_resources(activities, entities, resources, verbose) do
    Analyzer.analyze_activities_with_resources(activities, entities, resources, verbose)
  end
  
  @doc """
  Enhanced scheduling with entity/resource management.
  """
  def attempt_enhanced_scheduling(schedule_name, activities, entities, resources, constraints, simulation_mode, activity_log, verbose) do
    if verbose > 1 do
      Logger.debug("AriaEngine.Scheduler: Attempting enhanced scheduling with #{length(entities)} entities and #{length(resources)} resources")
    end
    
    # Convert to domain format for hybrid planner
    case convert_activities_to_enhanced_domain(activities, entities, resources, constraints) do
      {:ok, domain} ->
        # Create enhanced initial state with entities and resources
        initial_state = create_enhanced_initial_state(entities, resources)
        
        # Generate tasks and goals from activities
        {tasks, goals} = StateManager.convert_activities_to_tasks_and_goals(activities)
        
        if verbose > 2 do
          Logger.debug("AriaEngine.Scheduler: Created enhanced domain with #{map_size(domain.actions)} actions")
          Logger.debug("AriaEngine.Scheduler: Generated #{length(tasks)} tasks and #{length(goals)} goals")
        end
        
        # Use PlannerAdapter for HTN task decomposition with temporal validation
        planner_opts = [verbose: verbose]
        case PlannerAdapter.plan_tasks(domain, initial_state, tasks, planner_opts) do
          {:ok, encapsulated_plan} ->
            if simulation_mode do
              # Run simulation using run_lazy_refineahead
              simulate_plan_execution(domain, initial_state, encapsulated_plan, activities, entities, resources, activity_log, verbose)
            else
              # Convert plan to schedule format
              schedule = convert_plan_to_enhanced_schedule(encapsulated_plan, activities, entities, resources)
              enhanced_activity_log = if activity_log, do: generate_activity_log(schedule, entities), else: []
              resource_utilization = calculate_resource_utilization(schedule, resources)
              timeline = generate_timeline(schedule, entities, resources)
              
              {:ok, schedule, enhanced_activity_log, resource_utilization, timeline}
            end
          {:error, reason} ->
            {:error, "Enhanced planning failed: #{reason}"}
        end
      {:error, reason} ->
        {:error, "Enhanced domain conversion failed: #{reason}"}
    end
  end
  
  @doc """
  Simulate plan execution using run_lazy_refineahead.
  """
  def simulate_plan_execution(domain, initial_state, encapsulated_plan, activities, entities, resources, activity_log, verbose) do
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
        enhanced_activity_log = if activity_log, do: generate_simulation_activity_log(schedule, entities, final_state), else: []
        resource_utilization = calculate_resource_utilization(schedule, resources)
        timeline = generate_timeline(schedule, entities, resources)
        
        {:ok, schedule, enhanced_activity_log, resource_utilization, timeline}
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
      duration = Map.get(activity, :duration, 1)
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
        AriaEngine.StateV2.matches?(state, dep_id, "completed", true)
      end)
      
      # Check if required capabilities and resources are available
      resources_available = check_resource_availability(state, required_capabilities, required_resources, entities, resources)
      
      if deps_satisfied and resources_available do
        # Return action to complete this activity
        [{String.to_atom(activity_id), []}]
      else
        # Dependencies not satisfied or resources unavailable
        incomplete_deps = Enum.filter(dependencies, fn dep_id ->
          not AriaEngine.StateV2.matches?(state, dep_id, "completed", true)
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
  
  defp find_available_entity_with_capabilities(state, required_capabilities, entities) do
    ResourceManager.find_available_entity_with_capabilities(state, required_capabilities, entities)
  end
  
  defp check_resource_availability(state, required_capabilities, required_resources, entities, resources) do
    ResourceManager.check_resource_availability(state, required_capabilities, required_resources, entities, resources)
  end
  
  defp check_single_resource_availability(state, resource_id, resources) do
    ResourceManager.check_single_resource_availability(state, resource_id, resources)
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
  def create_enhanced_scheduling_methods(activities, entities, resources) do
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
  def create_action_metadata(activities, entities, resources) do
    activities
    |> Enum.map(fn activity ->
      action_name = String.to_atom(activity.id)
      duration = Map.get(activity, :duration, 1)
      
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
  def convert_plan_to_enhanced_schedule(encapsulated_plan, activities, entities, resources) do
    PlanConverter.convert_plan_to_enhanced_schedule(encapsulated_plan, activities, entities, resources)
  end
  
  @doc """
  Convert simulation results to schedule format.
  """
  def convert_simulation_to_schedule(encapsulated_plan, final_state, activities, entities, resources) do
    PlanConverter.convert_simulation_to_schedule(encapsulated_plan, final_state, activities, entities, resources)
  end
  
  # Entity and resource assignment helpers (delegated to specialized modules)
  
  defp assign_entity_for_activity(activity, entities) do
    EntityManager.assign_entity_for_activity(activity, entities)
  end
  
  defp assign_resources_for_activity(activity, resources) do
    required_resources = Map.get(activity, :required_resources, [])
    
    required_resources
    |> Enum.map(fn resource_id ->
      Enum.find(resources, fn resource -> resource.id == resource_id end)
    end)
    |> Enum.filter(& &1)
  end
  
  @doc """
  Create fallback schedule.
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
  
  # Resource utilization calculation functions
  
  @doc """
  Calculate resource utilization metrics.
  """
  def calculate_resource_utilization(schedule, resources) do
    ResourceAnalyzer.calculate_resource_utilization(schedule, resources)
  end
  
  defp calculate_peak_usage(schedule, resource_id) do
    # Calculate peak concurrent usage of a resource
    schedule
    |> Enum.filter(fn activity ->
      required_resources = get_in(activity, [:resource_requirements, :resources]) || []
      Enum.member?(required_resources, resource_id)
    end)
    |> length()
  end
  
  defp calculate_average_usage(schedule, resource_id) do
    # Calculate average usage over time
    total_activities = length(schedule)
    activities_using_resource = schedule
    |> Enum.filter(fn activity ->
      required_resources = get_in(activity, [:resource_requirements, :resources]) || []
      Enum.member?(required_resources, resource_id)
    end)
    |> length()
    
    if total_activities > 0 do
      activities_using_resource / total_activities
    else
      0
    end
  end
  
  defp calculate_efficiency_score(peak_usage, average_usage, total_capacity) do
    if total_capacity > 0 do
      # Efficiency score based on how well capacity is utilized
      utilization_ratio = average_usage / total_capacity
      peak_ratio = peak_usage / total_capacity
      
      # Balance between high utilization and avoiding overload
      cond do
        peak_ratio > 1.0 -> 0.5  # Overloaded
        utilization_ratio > 0.8 -> 0.9  # High efficiency
        utilization_ratio > 0.6 -> 0.8  # Good efficiency
        utilization_ratio > 0.4 -> 0.6  # Moderate efficiency
        true -> 0.3  # Low efficiency
      end
    else
      0
    end
  end
  
  defp calculate_overall_efficiency(resource_usage) do
    if map_size(resource_usage) > 0 do
      total_efficiency = resource_usage
      |> Enum.map(fn {_id, metrics} -> metrics.efficiency_score end)
      |> Enum.sum()
      
      total_efficiency / map_size(resource_usage)
    else
      0
    end
  end
  
  defp identify_bottlenecks(resource_usage) do
    resource_usage
    |> Enum.filter(fn {_id, metrics} ->
      metrics.utilization_percentage > 90
    end)
    |> Enum.map(fn {id, _metrics} -> id end)
  end
  
  defp generate_optimization_recommendations(resource_usage) do
    recommendations = []
    
    # Check for overutilized resources
    overutilized = resource_usage
    |> Enum.filter(fn {_id, metrics} -> metrics.utilization_percentage > 90 end)
    
    recommendations = if not Enum.empty?(overutilized) do
      ["Consider increasing capacity for overutilized resources: #{Enum.map(overutilized, fn {id, _} -> id end) |> Enum.join(", ")}" | recommendations]
    else
      recommendations
    end
    
    # Check for underutilized resources
    underutilized = resource_usage
    |> Enum.filter(fn {_id, metrics} -> metrics.utilization_percentage < 30 end)
    
    recommendations = if not Enum.empty?(underutilized) do
      ["Consider reducing capacity or reassigning underutilized resources: #{Enum.map(underutilized, fn {id, _} -> id end) |> Enum.join(", ")}" | recommendations]
    else
      recommendations
    end
    
    recommendations
  end
  
  # Activity logging functions
  
  @doc """
  Generate activity log from schedule.
  """
  def generate_activity_log(schedule, entities) do
    ActivityLogger.generate_activity_log(schedule, entities)
  end
  
  @doc """
  Generate simulation activity log.
  """
  def generate_simulation_activity_log(schedule, entities, final_state) do
    ActivityLogger.generate_simulation_activity_log(schedule, entities, final_state)
  end
  
  @doc """
  Generate timeline from schedule.
  """
  def generate_timeline(schedule, entities, resources) do
    ActivityLogger.generate_timeline(schedule, entities, resources)
  end
  
  # Analysis helper functions (stubs for missing functions)
  
  defp detect_circular_dependencies(_activities, _verbose), do: 0
  defp detect_enhanced_resource_conflicts(_activities, _entities, _resources, _verbose), do: 0
  defp calculate_resource_aware_critical_path(_activities, _entities, _resources, _verbose), do: 0
  defp analyze_entity_utilization(_activities, _entities), do: %{}
  defp analyze_resource_availability(_resources), do: %{}
end
