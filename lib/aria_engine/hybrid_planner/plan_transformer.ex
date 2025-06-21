# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngine.HybridPlanner.PlanTransformer do
  @moduledoc """
  Transforms MCP scheduling requests into planning parameters for the hybrid planner.

  This module serves as the bridge between the MCP pipeline and the hybrid planner,
  converting activities, entities, and resources from MCP format into the domain
  and state structures that the planner expects.

  ## Usage

      mcp_request = %{
        activities: [...],
        entities: [...],
        resources: [...],
        constraints: %{...}
      }
      
      {:ok, planning_params} = AriaEngine.HybridPlanner.PlanTransformer.convert_to_planning_params(mcp_request)
  """

  require Logger

  @doc """
  Convert MCP scheduling request to planning parameters.

  Takes an MCP request containing activities, entities, resources, and constraints,
  and transforms them into the format expected by the hybrid planner.

  ## Parameters

  - `mcp_request` - Map containing:
    - `:activities` - List of activity maps
    - `:entities` - List of entity maps (optional)
    - `:resources` - List of resource maps (optional)
    - `:constraints` - Constraint map (optional)

  ## Returns

  - `{:ok, planning_params}` - Success with planning parameters
  - `{:error, reason}` - Transformation failed
  """
  @spec convert_to_planning_params(map()) :: {:ok, map()} | {:error, String.t()}
  def convert_to_planning_params(mcp_request) do
    Logger.info("🔧 PlanTransformer: Converting MCP request to planning parameters")

    activities = Map.get(mcp_request, :activities, [])
    entities = Map.get(mcp_request, :entities, [])
    resources = Map.get(mcp_request, :resources, [])
    constraints = Map.get(mcp_request, :constraints, %{})

    Logger.info(
      "🔧 PlanTransformer: #{length(activities)} activities, #{length(entities)} entities, #{length(resources)} resources"
    )

    try do
      # Transform activities to domain format
      {:ok, domain} = transform_activities_to_domain(activities, entities, resources, constraints)
      
      # Create initial state with entities and resources
      initial_state = create_initial_state(entities, resources)

      # Generate tasks and goals from activities
      {tasks, goals} = generate_tasks_and_goals(activities)

      planning_params = %{
        domain: domain,
        initial_state: initial_state,
        tasks: tasks,
        goals: goals,
        metadata: %{
          source: "MCP",
          activities_count: length(activities),
          entities_count: length(entities),
          resources_count: length(resources),
          transformed_at: DateTime.utc_now()
        }
      }

      Logger.info("🔧 PlanTransformer: Successfully created planning parameters")
      {:ok, planning_params}
    rescue
      e ->
        error_msg = "PlanTransformer error: #{Exception.message(e)}"
        Logger.error(error_msg)
        {:error, error_msg}
    end
  end

  @doc """
  Transform activities to domain format.

  Converts MCP activities into a domain structure with actions and methods
  that the hybrid planner can use.
  """
  @spec transform_activities_to_domain(list(), list(), list(), map()) ::
          {:ok, map()} | {:error, String.t()}
  def transform_activities_to_domain(activities, entities, resources, constraints) do
    Logger.debug("🔧 PlanTransformer: Transforming #{length(activities)} activities to domain")

    # Create actions for each activity
    actions = create_activity_actions(activities, entities, resources)

    # Create methods for task decomposition
    methods = create_activity_methods(activities, entities, resources)

    # Create resource management actions
    resource_actions = create_resource_actions(resources)

    # Combine all actions
    all_actions = Map.merge(actions, resource_actions)

    # Create domain structure
    domain = %{
      actions: all_actions,
      methods: methods,
      metadata: %{
        activities: length(activities),
        entities: length(entities),
        resources: length(resources),
        constraints: constraints
      }
    }

    {:ok, domain}
  end

  @doc """
  Create initial state with entities and resources.
  """
  @spec create_initial_state(list(), list()) :: map()
  def create_initial_state(entities, resources) do
    initial_state = AriaEngine.StateV2.new()

    # Add entity states
    state_with_entities =
      entities
      |> Enum.reduce(initial_state, fn entity, state ->
        entity_id = Map.get(entity, :id) || Map.get(entity, "id")
        entity_type = Map.get(entity, :type) || Map.get(entity, "type", :agent)
        capabilities = Map.get(entity, :capabilities) || Map.get(entity, "capabilities", [])

        state
        |> AriaEngine.StateV2.set_fact(entity_id, "type", entity_type)
        |> AriaEngine.StateV2.set_fact(entity_id, "capabilities", capabilities)
        |> AriaEngine.StateV2.set_fact(entity_id, "available", true)
        |> AriaEngine.StateV2.set_fact(entity_id, "current_activity", nil)
      end)

    # Add resource states
    resources
    |> Enum.reduce(state_with_entities, fn resource, state ->
      resource_id = Map.get(resource, :id) || Map.get(resource, "id")
      resource_type = Map.get(resource, :type) || Map.get(resource, "type", :computational)
      capacity = Map.get(resource, :capacity) || Map.get(resource, "capacity", 1)
      current_usage = Map.get(resource, :current_usage) || Map.get(resource, "current_usage", 0)

      state
      |> AriaEngine.StateV2.set_fact(resource_id, "type", resource_type)
      |> AriaEngine.StateV2.set_fact(resource_id, "capacity", capacity)
      |> AriaEngine.StateV2.set_fact(resource_id, "current_usage", current_usage)
      |> AriaEngine.StateV2.set_fact(resource_id, "available", true)
    end)
  end

  @doc """
  Generate tasks and goals from activities.
  """
  @spec generate_tasks_and_goals(list()) :: {list(), list()}
  def generate_tasks_and_goals(activities) do
    # Primary task: schedule all activities
    tasks = [{"schedule_activities", []}]

    # Goals: each activity should be completed
    goals =
      activities
      |> Enum.map(fn activity ->
        activity_id = Map.get(activity, :id) || Map.get(activity, "id")
        {activity_id, "completed", true}
      end)

    {tasks, goals}
  end

  # Private helper functions

  defp create_activity_actions(activities, entities, resources) do
    activities
    |> Enum.map(fn activity ->
      activity_id = Map.get(activity, :id) || Map.get(activity, "id")
      action_name = String.to_atom(activity_id)
      action_fn = create_activity_action_function(activity, entities, resources)

      {action_name, action_fn}
    end)
    |> Enum.into(%{})
  end

  defp create_activity_action_function(activity, _entities, _resources) do
    activity_id = Map.get(activity, :id) || Map.get(activity, "id")
    duration = Map.get(activity, :duration) || Map.get(activity, "duration")

    fn _args, state ->
      # Mark activity as completed
      state
      |> AriaEngine.StateV2.set_fact(activity_id, "completed", true)
      |> AriaEngine.StateV2.set_fact(activity_id, "duration", duration)
      |> AriaEngine.StateV2.set_fact(activity_id, "execution_time", DateTime.utc_now())
    end
  end

  defp create_activity_methods(activities, _entities, _resources) do
    # Create a method for scheduling all activities
    schedule_method = {
      "sequential_scheduling",
      fn _args, _state ->
        # Return all activities as sequential tasks
        activities
        |> Enum.map(fn activity ->
          activity_id = Map.get(activity, :id) || Map.get(activity, "id")
          {String.to_atom(activity_id), []}
        end)
      end
    }

    %{
      "schedule_activities" => [schedule_method]
    }
  end

  defp create_resource_actions(resources) do
    resources
    |> Enum.flat_map(fn resource ->
      resource_id = Map.get(resource, :id) || Map.get(resource, "id")

      [
        {String.to_atom("allocate_#{resource_id}"), create_allocate_action(resource)},
        {String.to_atom("release_#{resource_id}"), create_release_action(resource)}
      ]
    end)
    |> Enum.into(%{})
  end

  defp create_allocate_action(resource) do
    resource_id = Map.get(resource, :id) || Map.get(resource, "id")
    capacity = Map.get(resource, :capacity) || Map.get(resource, "capacity", 1)

    fn _args, state ->
      current_usage = AriaEngine.StateV2.get_fact(state, resource_id, "current_usage") || 0

      if current_usage < capacity do
        AriaEngine.StateV2.set_fact(state, resource_id, "current_usage", current_usage + 1)
      else
        false
      end
    end
  end

  defp create_release_action(resource) do
    resource_id = Map.get(resource, :id) || Map.get(resource, "id")

    fn _args, state ->
      current_usage = AriaEngine.StateV2.get_fact(state, resource_id, "current_usage") || 0

      if current_usage > 0 do
        AriaEngine.StateV2.set_fact(state, resource_id, "current_usage", current_usage - 1)
      else
        state
      end
    end
  end
end
