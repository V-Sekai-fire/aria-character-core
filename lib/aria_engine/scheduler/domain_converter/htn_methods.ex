# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngine.Scheduler.DomainConverter.HTNMethods do
  @moduledoc """
  Creates HTN (Hierarchical Task Network) scheduling methods for Phase 1 feasibility.

  This module handles the creation of task methods that decompose high-level
  scheduling goals into executable actions, with proper dependency handling
  and circular dependency detection.
  """

  require Logger
  alias AriaEngine.Scheduler.{Entity, Resource}

  @type activity :: map()
  @type task_methods :: %{String.t() => [{String.t(), function()}]}

  @doc """
  Create HTN scheduling methods for Phase 1 (feasibility).
  """
  @spec create_htn_scheduling_methods([activity()], [Entity.t()], [Resource.t()]) ::
          task_methods()
  def create_htn_scheduling_methods(activities, entities, resources) do
    # First check for circular dependencies and reject them
    case detect_circular_dependencies(activities) do
      :ok ->
        %{
          "schedule_activities" => [
            {
              "htn_decomposition_method",
              fn _args, _state ->
                # Return proper todo list with tasks for individual activities
                activities
                |> Enum.map(fn activity ->
                  {activity["id"], []}
                end)
              end
            }
          ]
        }
        |> Map.merge(create_activity_task_methods(activities, entities, resources))

      {:error, cycle} ->
        Logger.error(
          "DomainConverter: Circular dependency detected in activities: #{Enum.join(cycle, " → ")} → #{hd(cycle)}"
        )

        # Return empty methods to prevent infinite loops
        %{
          "schedule_activities" => [
            {
              "safe_method",
              fn _args, _state ->
                Logger.warning(
                  "DomainConverter: Refusing to create methods due to circular dependencies"
                )

                []
              end
            }
          ]
        }
    end
  end

  @doc """
  Create individual activity task methods using KHR primitives.
  For each activity, generate a method for the goal named after the activity ID,
  decomposing to the corresponding durative action.
  """
  @spec create_activity_task_methods([activity()], [Entity.t()], [Resource.t()]) :: task_methods()
  def create_activity_task_methods(activities, _entities, _resources) do
    activities
    |> Enum.reduce(%{}, fn activity, acc ->
      # Use activity ID directly as task name
      task_name = activity["id"]
      method_name = "decompose_to_durative"

      method_fn = fn _args, _state ->
        # Decompose this goal to the corresponding durative action
        [{String.to_atom("durative_#{activity["id"]}"), []}]
      end

      Map.put(acc, task_name, [{method_name, method_fn}])
    end)
  end

  @doc """
  Create activity scheduling method that returns proper todo list for hybrid planner.
  """
  @spec create_activity_scheduling_method(activity(), [Entity.t()], [Resource.t()]) :: function()
  def create_activity_scheduling_method(activity, _entities, _resources) do
    fn _args, state ->
      activity_id = activity["id"]
      dependencies = Map.get(activity, :dependencies, [])
      required_resources = Map.get(activity, :required_resources, [])

      # Ensure we have a StateV2 struct
      statev2 = ensure_statev2(state)

      # Check if already completed
      if AriaEngine.StateV2.matches_exactly?(statev2, activity_id, "completed", true) do
        # Already completed, no actions needed
        []
      else
        # Check dependencies
        incomplete_deps =
          Enum.filter(dependencies, fn dep_id ->
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
          todo_list =
            todo_list ++
              Enum.map(required_resources, fn resource_id ->
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
  Detects circular dependencies in activities using depth-first search.
  """
  @spec detect_circular_dependencies([activity()]) :: :ok | {:error, [String.t()]}
  def detect_circular_dependencies(activities) do
    # Build dependency graph
    dependency_graph = build_dependency_graph(activities)
    activity_ids = Enum.map(activities, & &1["id"])

    # Check each activity for cycles using DFS
    case find_cycle_in_graph(dependency_graph, activity_ids) do
      nil -> :ok
      cycle -> {:error, cycle}
    end
  end

  # Helper function to ensure we have a StateV2 struct
  @spec ensure_statev2(any()) :: AriaEngine.StateV2.t()
  defp ensure_statev2(%AriaEngine.StateV2{} = state), do: state
  defp ensure_statev2(state) when is_map(state), do: AriaEngine.StateV2.new(state)
  defp ensure_statev2(_), do: AriaEngine.StateV2.new()

  # Builds a dependency graph from activities.
  @spec build_dependency_graph([activity()]) :: %{String.t() => [String.t()]}
  defp build_dependency_graph(activities) do
    Enum.reduce(activities, %{}, fn activity, graph ->
      activity_id = activity["id"]
      dependencies = Map.get(activity, :dependencies, [])
      Map.put(graph, activity_id, dependencies)
    end)
  end

  # Finds cycles in the dependency graph using DFS.
  @spec find_cycle_in_graph(%{String.t() => [String.t()]}, [String.t()]) :: [String.t()] | nil
  defp find_cycle_in_graph(graph, activity_ids) do
    Enum.find_value(activity_ids, fn start_node ->
      visited = MapSet.new()
      path = []
      dfs_detect_cycle(graph, start_node, visited, path)
    end)
  end

  # Depth-first search to detect cycles.
  @spec dfs_detect_cycle(%{String.t() => [String.t()]}, String.t(), MapSet.t(), [String.t()]) ::
          [String.t()] | nil
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
