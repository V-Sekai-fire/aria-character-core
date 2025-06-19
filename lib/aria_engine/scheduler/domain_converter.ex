# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngine.Scheduler.DomainConverter do
  @moduledoc """
  Converts activities and resources into domain format for the hybrid planner.
  
  Uses two-phase approach:
  1. HTN decomposition with KHR primitives for feasibility
  2. Goal-based optimization for optimality
  """
  
  require Logger
  alias Domain
  alias AriaEngine.Scheduler.{Entity, Resource}
  
  @type activity :: map()
  @type task_methods :: %{String.t() => [{String.t(), function()}]}
  @type goal_methods :: %{String.t() => [{String.t(), function()}]}
  @type optimization_goal :: {String.t(), function()}
  @type khr_primitive :: {String.t(), list()}
  
  @doc """
  Convert activities to KHR-primitive-based domain with two-phase planning.
  """
  @spec convert_activities_to_khr_domain([activity()], [Entity.t()], [Resource.t()], map()) :: 
    {:ok, Domain.t()} | {:error, String.t()}
  def convert_activities_to_khr_domain(activities, entities, resources, _constraints) do
    try do
      # Create basic actions for activity execution
      basic_actions = create_basic_activity_actions(activities, entities, resources)
      
      # Phase 1: HTN task methods for feasible decomposition
      task_methods = create_htn_scheduling_methods(activities, entities, resources)
      
      # Phase 2: Goal methods for resource constraints and optimization
      goal_methods = create_goal_methods(activities, entities, resources)
      
      # Create domain using basic actions, task methods, and goal methods
      domain = Domain.new("scheduler_domain")
      |> Domain.add_actions(basic_actions)
      |> add_task_methods_to_domain(task_methods)
      |> add_goal_methods_to_domain(goal_methods)
      
      {:ok, domain}
    rescue
      e -> {:error, "Domain creation failed: #{Exception.message(e)}"}
    end
  end
  
  @doc """
  Create basic activity actions for the domain.
  """
  @spec create_basic_activity_actions([activity()], [Entity.t()], [Resource.t()]) :: %{atom() => function()}
  def create_basic_activity_actions(activities, entities, resources) do
    activities
    |> Enum.map(fn activity ->
      action_name = String.to_atom(activity.id)
      action_fn = create_activity_action(activity, entities, resources)
      {action_name, action_fn}
    end)
    |> Enum.into(%{})
  end
  
  @doc """
  Create action function for a specific activity.
  """
  @spec create_activity_action(activity(), [Entity.t()], [Resource.t()]) :: function()
  def create_activity_action(activity, _entities, _resources) do
    fn state, args ->
      activity_id = activity.id
      duration = Map.get(activity, :duration, 1)
      
      # Simple action: mark activity as completed
      # Note: Fixed parameter order to match hybrid planner expectations
      state
      |> AriaEngine.StateV2.set_fact(activity_id, "completed", true)
      |> AriaEngine.StateV2.set_fact(activity_id, "duration", duration)
      |> AriaEngine.StateV2.set_fact(activity_id, "execution_time", DateTime.utc_now())
    end
  end
  
  @doc """
  Create HTN scheduling methods for Phase 1 (feasibility).
  """
  @spec create_htn_scheduling_methods([activity()], [Entity.t()], [Resource.t()]) :: task_methods()
  def create_htn_scheduling_methods(activities, entities, resources) do
    %{
      "schedule_activities" => [{
        "htn_decomposition_method", fn args, state ->
          # Return proper todo list with tasks for individual activities
          activities
          |> Enum.map(fn activity ->
            {"execute_#{activity.id}", []}
          end)
        end
      }]
    } |> Map.merge(create_activity_task_methods(activities, entities, resources))
  end
  
  @doc """
  Create individual activity task methods using KHR primitives.
  """
  @spec create_activity_task_methods([activity()], [Entity.t()], [Resource.t()]) :: task_methods()
  def create_activity_task_methods(activities, entities, resources) do
    activities
    |> Enum.reduce(%{}, fn activity, acc ->
      task_name = "execute_#{activity.id}"
      method_name = "khr_activity_method"
      method_fn = create_khr_activity_method(activity, entities, resources)
      Map.put(acc, task_name, [{method_name, method_fn}])
    end)
  end
  
  @doc """
  Create activity method that returns proper todo list for hybrid planner.
  """
  @spec create_khr_activity_method(activity(), [Entity.t()], [Resource.t()]) :: function()
  def create_khr_activity_method(activity, entities, resources) do
    fn args, state ->
      activity_id = activity.id
      dependencies = Map.get(activity, :dependencies, [])
      required_resources = Map.get(activity, :required_resources, [])
      
      # Check if already completed
      if AriaEngine.StateV2.matches?(state, activity_id, "completed", true) do
        [] # Already completed, no actions needed
      else
        # Check dependencies
        incomplete_deps = Enum.filter(dependencies, fn dep_id ->
          not AriaEngine.StateV2.matches?(state, dep_id, "completed", true)
        end)
        
        if not Enum.empty?(incomplete_deps) do
          # Return dependency tasks first (proper task format)
          Enum.map(incomplete_deps, fn dep_id ->
            {"execute_#{dep_id}", []}
          end)
        else
          # Dependencies satisfied - check resources and execute activity
          todo_list = []
          
          # Add resource availability goals (StateV2 format: {subject, predicate, object})
          todo_list = todo_list ++ Enum.map(required_resources, fn resource_id ->
            {resource_id, "available", true}
          end)
          
          # Add action to execute the activity
          todo_list = todo_list ++ [{String.to_atom(activity_id), []}]
          
          # Add goal to mark activity as completed
          todo_list = todo_list ++ [{activity_id, "completed", true}]
          
          todo_list
        end
      end
    end
  end
  
  @doc """
  Create sequence of KHR primitive actions to complete an activity.
  """
  @spec create_khr_primitive_sequence(activity(), [Entity.t()], [Resource.t()]) :: [khr_primitive()]
  def create_khr_primitive_sequence(activity, entities, resources) do
    activity_id = activity.id
    required_resources = Map.get(activity, :required_resources, [])
    duration = Map.get(activity, :duration, 1)
    
    # Generate node indices for this activity's operations
    base_node = String.to_integer(String.replace(activity_id, ~r/[^\d]/, ""), 10) * 1000
    
    sequence = []
    
    # 1. Check resource availability using math/le (current_usage <= capacity)
    sequence = sequence ++ Enum.with_index(required_resources, fn resource_id, idx ->
      node_idx = base_node + idx * 10 + 1
      {"math/le", [node_idx, resource_id, "current_usage", resource_id, "capacity"]}
    end)
    
    # 2. Allocate resources using math/add (increment current_usage)
    sequence = sequence ++ Enum.with_index(required_resources, fn resource_id, idx ->
      node_idx = base_node + idx * 10 + 2
      {"math/add", [node_idx, resource_id, "current_usage", 1]}
    end)
    
    # 3. Set activity status to in_progress
    sequence = sequence ++ [
      {"variable/set", [base_node + 100, activity_id, "status", "in_progress"]},
      {"variable/set", [base_node + 101, activity_id, "start_time", DateTime.utc_now()]}
    ]
    
    # 4. Wait for duration (using flow/setDelay)
    sequence = sequence ++ [
      {"flow/setDelay", [base_node + 200, duration]}
    ]
    
    # 5. Complete activity and release resources
    sequence = sequence ++ [
      {"variable/set", [base_node + 300, activity_id, "completed", true]},
      {"variable/set", [base_node + 301, activity_id, "status", "completed"]},
      {"variable/set", [base_node + 302, activity_id, "end_time", DateTime.utc_now()]}
    ]
    
    # 6. Release resources using math/sub (decrement current_usage)
    sequence = sequence ++ Enum.with_index(required_resources, fn resource_id, idx ->
      node_idx = base_node + idx * 10 + 400
      {"math/sub", [node_idx, resource_id, "current_usage", 1]}
    end)
    
    sequence
  end
  
  @doc """
  Create goal methods for resource constraints and optimization.
  """
  @spec create_goal_methods([activity()], [Entity.t()], [Resource.t()]) :: goal_methods()
  def create_goal_methods(activities, entities, resources) do
    %{}
    |> Map.merge(create_resource_constraint_goals(resources))
    |> Map.merge(create_dependency_constraint_goals(activities))
    |> Map.merge(create_optimization_goals(activities, entities, resources))
  end
  
  @doc """
  Create unigoal methods for resource constraints.
  """
  def create_resource_constraint_goals(resources) do
    resources
    |> Enum.reduce(%{}, fn resource, acc ->
      goal_type = "resource_available_#{resource.id}"
      method_name = "check_resource_capacity"
      method_fn = fn args, state ->
        current_usage = AriaEngine.StateV2.get_fact(state, resource.id, "current_usage") || 0
        capacity = resource.capacity
        
        if current_usage < capacity do
          [] # Goal already satisfied
        else
          # Return proper task format to free up resources
          [{"wait_for_resource_#{resource.id}", []}]
        end
      end
      
      Map.put(acc, goal_type, [{method_name, method_fn}])
    end)
  end
  
  @doc """
  Create unigoal methods for dependency constraints.
  """
  def create_dependency_constraint_goals(activities) do
    activities
    |> Enum.reduce(%{}, fn activity, acc ->
      dependencies = Map.get(activity, :dependencies, [])
      
      if not Enum.empty?(dependencies) do
        goal_type = "dependencies_satisfied_#{activity.id}"
        method_name = "ensure_dependencies"
        method_fn = fn args, state ->
          incomplete_deps = Enum.filter(dependencies, fn dep_id ->
            not AriaEngine.StateV2.matches?(state, dep_id, "completed", true)
          end)
          
          if Enum.empty?(incomplete_deps) do
            [] # All dependencies satisfied
          else
            # Return tasks to complete dependencies (proper task format)
            Enum.map(incomplete_deps, fn dep_id ->
              {"execute_#{dep_id}", []}
            end)
          end
        end
        
        Map.put(acc, goal_type, [{method_name, method_fn}])
      else
        acc
      end
    end)
  end
  
  @doc """
  Create optimization goal methods.
  """
  def create_optimization_goals(activities, entities, resources) do
    %{
      "minimize_makespan" => [{
        "optimize_execution_time", fn args, state ->
          # Check if all activities are completed
          all_completed = Enum.all?(activities, fn activity ->
            AriaEngine.StateV2.matches?(state, activity.id, "completed", true)
          end)
          
          if all_completed do
            [] # Optimization goal satisfied
          else
            # Return proper task format for optimization
            [{"optimize_schedule", []}]
          end
        end
      }],
      "maximize_resource_efficiency" => [{
        "balance_resource_usage", fn args, state ->
          # Check resource utilization balance
          utilizations = resources
          |> Enum.map(fn resource ->
            current_usage = AriaEngine.StateV2.get_fact(state, resource.id, "current_usage") || 0
            capacity = resource.capacity
            if capacity > 0, do: current_usage / capacity, else: 0
          end)
          
          if Enum.empty?(utilizations) do
            []
          else
            avg_utilization = Enum.sum(utilizations) / length(utilizations)
            if avg_utilization > 0.8 do
              # Return proper task format for rebalancing
              [{"rebalance_resources", []}]
            else
              []
            end
          end
        end
      }]
    }
  end
  
  # Helper functions for domain construction
  
  defp add_task_methods_to_domain(domain, task_methods) do
    Enum.reduce(task_methods, domain, fn {task_name, methods}, acc_domain ->
      Domain.add_task_methods(acc_domain, task_name, methods)
    end)
  end
  
  defp add_goal_methods_to_domain(domain, goal_methods) do
    Enum.reduce(goal_methods, domain, fn {goal_type, methods}, acc_domain ->
      Domain.add_unigoal_methods(acc_domain, goal_type, methods)
    end)
  end
end
