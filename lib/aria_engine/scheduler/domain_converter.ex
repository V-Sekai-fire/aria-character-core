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
      
      # Create durative actions for temporal scheduling
      durative_actions = create_durative_actions(activities, entities, resources)
      
      # Phase 1: HTN task methods for feasible decomposition
      task_methods = create_htn_scheduling_methods(activities, entities, resources)
      
      # Phase 2: Goal methods for resource constraints and optimization
      goal_methods = create_goal_methods(activities, entities, resources)
      
      # Create domain using basic actions, task methods, and goal methods
      domain = Domain.new("scheduler_domain")
      |> Domain.add_actions(basic_actions)
      |> add_durative_actions_to_domain(durative_actions)
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
    # Create regular actions
    regular_actions = activities
    |> Enum.map(fn activity ->
      action_name = String.to_atom(activity.id)
      action_fn = create_activity_action(activity, entities, resources)
      {action_name, action_fn}
    end)
    |> Enum.into(%{})
    
    # Create durative actions
    durative_actions = activities
    |> Enum.map(fn activity ->
      durative_action_name = String.to_atom("durative_#{activity.id}")
      durative_action_fn = create_durative_activity_action(activity, entities, resources)
      {durative_action_name, durative_action_fn}
    end)
    |> Enum.into(%{})
    
    Map.merge(regular_actions, durative_actions)
  end
  
  @doc """
  Create action function for a specific activity.
  """
  @spec create_activity_action(activity(), [Entity.t()], [Resource.t()]) :: function()
  def create_activity_action(activity, _entities, _resources) do
    fn state, _args ->
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
  Create durative action function for a specific activity.
  """
  @spec create_durative_activity_action(activity(), [Entity.t()], [Resource.t()]) :: function()
  def create_durative_activity_action(activity, _entities, _resources) do
    fn state, _args ->
      activity_id = activity.id
      duration = Map.get(activity, :duration, 1)
      required_resources = Map.get(activity, :required_resources, [])
      
      # Durative action: handle resource allocation and activity execution over time
      updated_state = state
      |> AriaEngine.StateV2.set_fact(activity_id, "status", "in_progress")
      |> AriaEngine.StateV2.set_fact(activity_id, "start_time", DateTime.utc_now())
      |> AriaEngine.StateV2.set_fact(activity_id, "duration", duration)
      
      # Allocate resources
      final_state = Enum.reduce(required_resources, updated_state, fn resource_id, acc_state ->
        current_usage = AriaEngine.StateV2.get_fact(acc_state, resource_id, "current_usage") || 0
        acc_state
        |> AriaEngine.StateV2.set_fact(resource_id, "current_usage", current_usage + 1)
        |> AriaEngine.StateV2.set_fact(resource_id, "allocated_to", activity_id)
      end)
      
      # Mark as completed (for now - in a real temporal system this would be handled by the temporal planner)
      final_state
      |> AriaEngine.StateV2.set_fact(activity_id, "completed", true)
      |> AriaEngine.StateV2.set_fact(activity_id, "status", "completed")
      |> AriaEngine.StateV2.set_fact(activity_id, "end_time", DateTime.utc_now())
    end
  end
  
  @doc """
  Create durative actions for activities.
  """
  @spec create_durative_actions([activity()], [Entity.t()], [Resource.t()]) :: %{atom() => Domain.DurativeAction.t()}
  def create_durative_actions(activities, entities, resources) do
    # Create durative actions for individual activities
    activity_actions = activities
    |> Enum.map(fn activity ->
      durative_action_name = String.to_atom("durative_#{activity.id}")
      durative_action = create_durative_action_struct(activity, entities, resources)
      {durative_action_name, durative_action}
    end)
    |> Enum.into(%{})
    
    # Add timing constraint fixing durative action
    timing_constraint_action = create_timing_constraint_durative_action(activities)
    
    Map.put(activity_actions, :fix_timing_constraints, timing_constraint_action)
  end
  
  @doc """
  Create durative action struct for a specific activity.
  """
  @spec create_durative_action_struct(activity(), [Entity.t()], [Resource.t()]) :: Domain.DurativeAction.t()
  def create_durative_action_struct(activity, entities, resources) do
    activity_id = activity.id
    duration = Map.get(activity, :duration, 1)
    required_resources = Map.get(activity, :required_resources, [])
    dependencies = Map.get(activity, :dependencies, [])
    
    # Create conditions for the durative action
    conditions = %{
      at_start: [
        # Dependencies must be completed at start
        Enum.map(dependencies, fn dep_id -> {dep_id, "completed", true} end),
        # Resources must be available at start
        Enum.map(required_resources, fn resource_id -> {resource_id, "available", true} end)
      ] |> List.flatten(),
      over_all: [
        # Resources must remain allocated over the duration
        Enum.map(required_resources, fn resource_id -> {resource_id, "allocated_to", activity_id} end)
      ] |> List.flatten(),
      at_end: []
    }
    
    # Create effects for the durative action
    effects = %{
      at_start: [
        # Mark activity as in progress and allocate resources
        {activity_id, "status", "in_progress"},
        {activity_id, "start_time", DateTime.utc_now()}
      ] ++ Enum.map(required_resources, fn resource_id ->
        {resource_id, "allocated_to", activity_id}
      end),
      at_end: [
        # Mark activity as completed and release resources
        {activity_id, "completed", true},
        {activity_id, "status", "completed"},
        {activity_id, "end_time", DateTime.utc_now()}
      ] ++ Enum.map(required_resources, fn resource_id ->
        {resource_id, "allocated_to", nil}
      end),
      over_time: []
    }
    
    # Create the action function
    action_fn = create_durative_activity_action(activity, entities, resources)
    
    Domain.DurativeAction.new(
      String.to_atom("durative_#{activity_id}"),
      {:fixed, duration},
      conditions,
      effects,
      action_fn
    )
  end
  
  @doc """
  Create HTN scheduling methods for Phase 1 (feasibility).
  """
  @spec create_htn_scheduling_methods([activity()], [Entity.t()], [Resource.t()]) :: task_methods()
  def create_htn_scheduling_methods(activities, entities, resources) do
    # First check for circular dependencies and reject them
    case detect_circular_dependencies(activities) do
      :ok ->
        %{
          "schedule_activities" => [{
            "htn_decomposition_method", fn _args, _state ->
              # Return proper todo list with tasks for individual activities
              activities
              |> Enum.map(fn activity ->
                {activity.id, []}
              end)
            end
          }]
        } |> Map.merge(create_activity_task_methods(activities, entities, resources))
      
      {:error, cycle} ->
        Logger.error("DomainConverter: Circular dependency detected in activities: #{Enum.join(cycle, " → ")} → #{hd(cycle)}")
        # Return empty methods to prevent infinite loops
        %{
          "schedule_activities" => [{
            "safe_method", fn _args, _state ->
              Logger.warning("DomainConverter: Refusing to create methods due to circular dependencies")
              []
            end
          }]
        }
    end
  end
  
  @doc """
  Create individual activity task methods using KHR primitives.
  """
  @spec create_activity_task_methods([activity()], [Entity.t()], [Resource.t()]) :: task_methods()
  def create_activity_task_methods(activities, entities, resources) do
    activities
    |> Enum.reduce(%{}, fn activity, acc ->
      task_name = activity.id  # Use activity ID directly as task name
      method_name = "schedule_activity_method"
      method_fn = create_activity_scheduling_method(activity, entities, resources)
      Map.put(acc, task_name, [{method_name, method_fn}])
    end)
  end
  
  @doc """
  Create activity scheduling method that returns proper todo list for hybrid planner.
  """
  @spec create_activity_scheduling_method(activity(), [Entity.t()], [Resource.t()]) :: function()
  def create_activity_scheduling_method(activity, _entities, _resources) do
    fn _args, state ->
      activity_id = activity.id
      dependencies = Map.get(activity, :dependencies, [])
      required_resources = Map.get(activity, :required_resources, [])
      
      # Ensure we have a StateV2 struct
      statev2 = ensure_statev2(state)
      
      # Check if already completed
      if AriaEngine.StateV2.matches_exactly?(statev2, activity_id, "completed", true) do
        [] # Already completed, no actions needed
      else
        # Check dependencies
        incomplete_deps = Enum.filter(dependencies, fn dep_id ->
          not AriaEngine.StateV2.matches_exactly?(statev2, dep_id, "completed", true)
        end)
        
        if not Enum.empty?(incomplete_deps) do
          # Return dependency tasks first (proper task format)
          Enum.map(incomplete_deps, fn dep_id ->
            {dep_id, []}
          end)
        else
          # Dependencies satisfied - check resources and execute activity with durative action
          todo_list = []
          
          # Add resource availability goals (StateV2 format: {subject, predicate, object})
          todo_list = todo_list ++ Enum.map(required_resources, fn resource_id ->
            {resource_id, "available", true}
          end)
          
          # Add durative action to execute the activity (not regular action)
          durative_action_name = String.to_atom("durative_#{activity_id}")
          todo_list = todo_list ++ [{durative_action_name, []}]
          
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
  def create_khr_primitive_sequence(activity, _entities, _resources) do
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
      method_fn = fn _args, state ->
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
        method_fn = fn _args, state ->
          incomplete_deps = Enum.filter(dependencies, fn dep_id ->
            not AriaEngine.StateV2.matches_exactly?(state, dep_id, "completed", true)
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
  def create_optimization_goals(activities, _entities, resources) do
    %{
      "minimize_makespan" => [{
        "optimize_execution_time", fn _args, state ->
          # Check if all activities are completed
          all_completed = Enum.all?(activities, fn activity ->
            AriaEngine.StateV2.matches_exactly?(state, activity.id, "completed", true)
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
        "balance_resource_usage", fn _args, state ->
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
  
  defp add_durative_actions_to_domain(domain, durative_actions) do
    Enum.reduce(durative_actions, domain, fn {name, durative_action}, acc_domain ->
      Domain.add_action(acc_domain, name, durative_action)
    end)
  end
  
  @doc """
  Create timing constraint fixing durative action.
  """
  @spec create_timing_constraint_durative_action([activity()]) :: Domain.DurativeAction.t()
  def create_timing_constraint_durative_action(activities) do
    # Create conditions for the timing constraint durative action
    conditions = %{
      at_start: [
        # Schedule must exist and have timing conflicts
        {"schedule", "exists", true},
        {"schedule", "has_timing_conflicts", true}
      ],
      over_all: [
        # Schedule must remain modifiable during constraint solving
        {"schedule", "modifiable", true}
      ],
      at_end: []
    }
    
    # Create effects for the timing constraint durative action
    effects = %{
      at_start: [
        # Mark constraint solving as active
        {"schedule", "constraint_solving_active", true}
      ],
      at_end: [
        # Mark timing constraints as satisfied and remove conflicts
        {"schedule", "timing_constraints_satisfied", true},
        {"schedule", "valid", true},
        {"schedule", "has_timing_conflicts", false},
        {"schedule", "constraint_solving_active", false}
      ],
      over_time: []
    }
    
    # Create the action function that performs iterative constraint propagation
    action_fn = create_timing_constraint_action_function(activities)
    
    Domain.DurativeAction.new(
      :fix_timing_constraints,
      {:range, 1, 10},  # Duration between 1-10 time units depending on convergence
      conditions,
      effects,
      action_fn
    )
  end
  
  @doc """
  Create action function for timing constraint fixing.
  """
  @spec create_timing_constraint_action_function([activity()]) :: function()
  def create_timing_constraint_action_function(activities) do
    fn state, _args ->
      # Extract scheduled activities from state
      scheduled_activities = extract_scheduled_activities_from_state(state, activities)
      
      # Create dependency map for constraint propagation
      dependency_map = activities
      |> Enum.map(fn activity -> 
        {activity.id, Map.get(activity, :dependencies, [])} 
      end)
      |> Enum.into(%{})
      
      # Perform iterative constraint propagation
      fixed_activities = fix_timing_iteratively_in_planner(scheduled_activities, dependency_map, 0)
      
      # Update state with fixed timing
      update_state_with_fixed_timing(state, fixed_activities)
    end
  end
  
  # Extract scheduled activities from planner state.
  defp extract_scheduled_activities_from_state(state, activities) do
    activities
    |> Enum.map(fn activity ->
      activity_id = activity.id
      start_time = AriaEngine.StateV2.get_fact(state, activity_id, "start_time") || 0
      end_time = AriaEngine.StateV2.get_fact(state, activity_id, "end_time") || Map.get(activity, :duration, 1)
      duration = Map.get(activity, :duration, 1)
      
      Map.merge(activity, %{
        start_time: start_time,
        end_time: end_time,
        duration: duration
      })
    end)
  end
  
  # Iterative constraint propagation within the planner context.
  defp fix_timing_iteratively_in_planner(activities, dependency_map, iteration) do
    # Prevent infinite loops
    if iteration > 10 do
      Logger.warning("Timing constraint fixing reached maximum iterations in planner")
      activities
    else
      # Create activity lookup map with current timing
      activity_map = activities
      |> Enum.map(fn activity -> {activity.id, activity} end)
      |> Enum.into(%{})
      
      # Calculate new timing for each activity
      updated_activities = activities
      |> Enum.map(fn activity ->
        dependencies = Map.get(dependency_map, activity.id, [])
        
        # Calculate earliest start time based on current dependency timing
        earliest_start = if Enum.empty?(dependencies) do
          0
        else
          dependencies
          |> Enum.map(fn dep_id ->
            case Map.get(activity_map, dep_id) do
              nil -> 
                Logger.warning("Dependency #{dep_id} not found for activity #{activity.id}")
                0
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
      
      # Check if timing has converged (no changes from previous iteration)
      if timing_converged_in_planner?(activities, updated_activities) do
        updated_activities
      else
        # Continue iterating with updated timing
        fix_timing_iteratively_in_planner(updated_activities, dependency_map, iteration + 1)
      end
    end
  end
  
  # Check if timing has converged between iterations in planner context.
  defp timing_converged_in_planner?(old_activities, new_activities) do
    old_timing = old_activities |> Enum.map(fn a -> {a.id, a.start_time, a.end_time} end) |> Enum.sort()
    new_timing = new_activities |> Enum.map(fn a -> {a.id, a.start_time, a.end_time} end) |> Enum.sort()
    
    old_timing == new_timing
  end
  
  # Update planner state with fixed timing information.
  defp update_state_with_fixed_timing(state, fixed_activities) do
    Enum.reduce(fixed_activities, state, fn activity, acc_state ->
      activity_id = activity.id
      acc_state
      |> AriaEngine.StateV2.set_fact(activity_id, "start_time", activity.start_time)
      |> AriaEngine.StateV2.set_fact(activity_id, "end_time", activity.end_time)
      |> AriaEngine.StateV2.set_fact(activity_id, "timing_fixed", true)
    end)
  end

  # Helper function to ensure we have a StateV2 struct
  defp ensure_statev2(%AriaEngine.StateV2{} = state), do: state
  defp ensure_statev2(state) when is_map(state), do: AriaEngine.StateV2.new(state)
  defp ensure_statev2(_), do: AriaEngine.StateV2.new()

  # Detects circular dependencies in activities using depth-first search.
  defp detect_circular_dependencies(activities) do
    # Build dependency graph
    dependency_graph = build_dependency_graph(activities)
    activity_ids = Enum.map(activities, & &1.id)
    
    # Check each activity for cycles using DFS
    case find_cycle_in_graph(dependency_graph, activity_ids) do
      nil -> :ok
      cycle -> {:error, cycle}
    end
  end
  
  # Builds a dependency graph from activities.
  defp build_dependency_graph(activities) do
    Enum.reduce(activities, %{}, fn activity, graph ->
      activity_id = activity.id
      dependencies = Map.get(activity, :dependencies, [])
      Map.put(graph, activity_id, dependencies)
    end)
  end
  
  # Finds cycles in the dependency graph using DFS.
  defp find_cycle_in_graph(graph, activity_ids) do
    Enum.find_value(activity_ids, fn start_node ->
      visited = MapSet.new()
      path = []
      dfs_detect_cycle(graph, start_node, visited, path)
    end)
  end
  
  # Depth-first search to detect cycles.
  defp dfs_detect_cycle(graph, node, visited, path) do
    cond do
      node in path ->
        # Found a cycle - return the cycle path
        cycle_start_index = Enum.find_index(path, &(&1 == node))
        Enum.drop(path, cycle_start_index)
        
      MapSet.member?(visited, node) ->
        # Already visited this node in a different path, no cycle here
        nil
        
      true ->
        # Continue DFS
        updated_visited = MapSet.put(visited, node)
        updated_path = [node | path]
        dependencies = Map.get(graph, node, [])
        
        Enum.find_value(dependencies, fn dep ->
          dfs_detect_cycle(graph, dep, updated_visited, updated_path)
        end)
    end
  end
end
