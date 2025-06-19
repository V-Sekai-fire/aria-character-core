# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngine.Scheduler.Analyzer do
  @moduledoc """
  Analyzes activities and resources for scheduling optimization.
  
  Provides analysis functions for dependency detection, resource conflicts,
  critical path calculation, and entity utilization assessment.
  """
  
  require Logger
  
  @doc """
  Enhanced activity analysis with resource considerations.
  """
  def analyze_activities_with_resources(activities, entities, resources, verbose) do
    if verbose > 2 do
      Logger.debug("AriaEngine.Scheduler: Analyzing #{length(activities)} activities with resource constraints")
    end
    
    # Count dependencies
    dependencies_found = activities
    |> Enum.map(fn activity -> Map.get(activity, :dependencies, []) end)
    |> List.flatten()
    |> length()
    
    # Detect circular dependencies
    circular_dependencies = detect_circular_dependencies(activities, verbose)
    
    # Detect resource conflicts with entity capabilities
    resource_conflicts = detect_enhanced_resource_conflicts(activities, entities, resources, verbose)
    
    # Calculate critical path length with resource constraints
    critical_path_length = calculate_resource_aware_critical_path(activities, entities, resources, verbose)
    
    # Analyze entity utilization
    entity_utilization = analyze_entity_utilization(activities, entities)
    
    %{
      activities_analyzed: length(activities),
      dependencies_found: dependencies_found,
      resource_conflicts: resource_conflicts,
      circular_dependencies: circular_dependencies,
      critical_path_length: critical_path_length,
      entity_utilization: entity_utilization,
      resource_availability: analyze_resource_availability(resources),
      hybrid_planner_used: true
    }
  end
  
  @doc """
  Detect circular dependencies in activities.
  """
  def detect_circular_dependencies(activities, verbose) do
    if verbose > 2 do
      Logger.debug("AriaEngine.Scheduler: Checking for circular dependencies")
    end
    
    # Build dependency graph
    dependency_graph = activities
    |> Enum.reduce(%{}, fn activity, acc ->
      dependencies = Map.get(activity, :dependencies, [])
      Map.put(acc, activity.id, dependencies)
    end)
    
    # Use depth-first search to detect cycles
    visited = MapSet.new()
    rec_stack = MapSet.new()
    
    activities
    |> Enum.reduce(0, fn activity, cycle_count ->
      if has_cycle?(dependency_graph, activity.id, visited, rec_stack) do
        cycle_count + 1
      else
        cycle_count
      end
    end)
  end
  
  @doc """
  Detect enhanced resource conflicts.
  """
  def detect_enhanced_resource_conflicts(activities, entities, resources, verbose) do
    if verbose > 2 do
      Logger.debug("AriaEngine.Scheduler: Analyzing resource conflicts")
    end
    
    # Check for capability conflicts
    capability_conflicts = detect_capability_conflicts(activities, entities)
    
    # Check for resource capacity conflicts
    capacity_conflicts = detect_capacity_conflicts(activities, resources)
    
    capability_conflicts + capacity_conflicts
  end
  
  @doc """
  Calculate resource-aware critical path.
  """
  def calculate_resource_aware_critical_path(activities, entities, resources, verbose) do
    if verbose > 2 do
      Logger.debug("AriaEngine.Scheduler: Calculating critical path with resource constraints")
    end
    
    # Build activity graph with durations and resource constraints
    activity_durations = activities
    |> Enum.reduce(%{}, fn activity, acc ->
      duration = Map.get(activity, :duration, 1)
      resource_delay = calculate_resource_delay(activity, entities, resources)
      total_duration = duration + resource_delay
      Map.put(acc, activity.id, total_duration)
    end)
    
    # Calculate longest path considering dependencies
    calculate_longest_path(activities, activity_durations)
  end
  
  @doc """
  Analyze entity utilization.
  """
  def analyze_entity_utilization(activities, entities) do
    # Calculate how many activities each entity type can handle
    entity_capabilities = entities
    |> Enum.group_by(fn entity -> entity.type end)
    |> Enum.map(fn {type, entities_of_type} ->
      total_capacity = length(entities_of_type)
      required_activities = count_activities_requiring_capabilities(activities, entities_of_type)
      
      {type, %{
        total_capacity: total_capacity,
        required_activities: required_activities,
        utilization_ratio: if(total_capacity > 0, do: required_activities / total_capacity, else: 0)
      }}
    end)
    |> Enum.into(%{})
    
    entity_capabilities
  end
  
  @doc """
  Analyze resource availability.
  """
  def analyze_resource_availability(resources) do
    resources
    |> Enum.map(fn resource ->
      {resource.id, %{
        type: resource.type,
        capacity: resource.capacity,
        current_usage: resource.current_usage || 0,
        available_capacity: resource.capacity - (resource.current_usage || 0),
        availability_ratio: if(resource.capacity > 0, do: (resource.capacity - (resource.current_usage || 0)) / resource.capacity, else: 0)
      }}
    end)
    |> Enum.into(%{})
  end
  
  # Private helper functions
  
  defp has_cycle?(graph, node, visited, rec_stack) do
    if MapSet.member?(rec_stack, node) do
      true
    else
      if MapSet.member?(visited, node) do
        false
      else
        visited = MapSet.put(visited, node)
        rec_stack = MapSet.put(rec_stack, node)
        
        dependencies = Map.get(graph, node, [])
        
        cycle_found = Enum.any?(dependencies, fn dep ->
          has_cycle?(graph, dep, visited, rec_stack)
        end)
        
        _rec_stack = MapSet.delete(rec_stack, node)
        cycle_found
      end
    end
  end
  
  defp detect_capability_conflicts(activities, entities) do
    # Count activities that require capabilities not available in entities
    activities
    |> Enum.count(fn activity ->
      required_capabilities = Map.get(activity, :required_capabilities, [])
      
      if Enum.empty?(required_capabilities) do
        false
      else
        # Check if any entity has all required capabilities
        not Enum.any?(entities, fn entity ->
          Enum.all?(required_capabilities, fn cap ->
            Enum.member?(entity.capabilities || [], cap)
          end)
        end)
      end
    end)
  end
  
  defp detect_capacity_conflicts(activities, resources) do
    # Count activities that require more resources than available
    resource_demands = activities
    |> Enum.flat_map(fn activity ->
      Map.get(activity, :required_resources, [])
    end)
    |> Enum.frequencies()
    
    resource_demands
    |> Enum.count(fn {resource_id, demand} ->
      resource = Enum.find(resources, fn r -> r.id == resource_id end)
      if resource do
        demand > resource.capacity
      else
        true  # Resource not found is a conflict
      end
    end)
  end
  
  defp calculate_resource_delay(activity, entities, resources) do
    # Calculate additional delay due to resource constraints
    required_capabilities = Map.get(activity, :required_capabilities, [])
    required_resources = Map.get(activity, :required_resources, [])
    
    capability_delay = if Enum.empty?(required_capabilities) do
      0
    else
      # Estimate delay based on entity availability
      available_entities = Enum.count(entities, fn entity ->
        Enum.all?(required_capabilities, fn cap ->
          Enum.member?(entity.capabilities || [], cap)
        end)
      end)
      
      if available_entities == 0, do: 10, else: max(0, 5 - available_entities)
    end
    
    resource_delay = required_resources
    |> Enum.map(fn resource_id ->
      resource = Enum.find(resources, fn r -> r.id == resource_id end)
      if resource do
        utilization = (resource.current_usage || 0) / resource.capacity
        round(utilization * 3)  # Higher utilization = more delay
      else
        5  # Unknown resource = significant delay
      end
    end)
    |> Enum.sum()
    
    capability_delay + resource_delay
  end
  
  defp calculate_longest_path(activities, activity_durations) do
    # Simple longest path calculation
    # In a real implementation, this would use topological sort and dynamic programming
    activities
    |> Enum.map(fn activity ->
      duration = Map.get(activity_durations, activity.id, 1)
      dependency_path = calculate_dependency_path_length(activity, activities, activity_durations)
      duration + dependency_path
    end)
    |> Enum.max(fn -> 0 end)
  end
  
  defp calculate_dependency_path_length(activity, activities, activity_durations) do
    dependencies = Map.get(activity, :dependencies, [])
    
    if Enum.empty?(dependencies) do
      0
    else
      dependencies
      |> Enum.map(fn dep_id ->
        dep_activity = Enum.find(activities, fn a -> a.id == dep_id end)
        if dep_activity do
          dep_duration = Map.get(activity_durations, dep_id, 1)
          dep_path = calculate_dependency_path_length(dep_activity, activities, activity_durations)
          dep_duration + dep_path
        else
          0
        end
      end)
      |> Enum.max(fn -> 0 end)
    end
  end
  
  defp count_activities_requiring_capabilities(activities, entities_of_type) do
    # Count activities that could be handled by this entity type
    sample_entity = List.first(entities_of_type)
    if sample_entity do
      activities
      |> Enum.count(fn activity ->
        required_capabilities = Map.get(activity, :required_capabilities, [])
        Enum.all?(required_capabilities, fn cap ->
          Enum.member?(sample_entity.capabilities || [], cap)
        end)
      end)
    else
      0
    end
  end
end
