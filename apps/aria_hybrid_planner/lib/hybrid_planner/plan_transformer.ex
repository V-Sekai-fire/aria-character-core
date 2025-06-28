# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngine.HybridPlanner.PlanTransformer do

  @moduledoc "Transforms MCP scheduling requests into planning parameters for the hybrid planner.\n\nThis module serves as the bridge between the MCP pipeline and the hybrid planner,\nconverting activities, entities, and resources from MCP format into the domain\nand state structures that the planner expects.\n\n## Usage\n\n    mcp_request = %{\n      activities: [...],\n      entities: [...],\n      resources: [...],\n      constraints: %{...}\n    }\n    \n    {:ok, planning_params} = AriaEngine.HybridPlanner.PlanTransformer.convert_to_planning_params(mcp_request)\n"
  require Logger

  @doc "Convert MCP scheduling request to planning parameters.\n\nTakes an MCP request containing activities, entities, resources, and constraints,\nand transforms them into the format expected by the hybrid planner.\n\n## Parameters\n\n- `mcp_request` - Map containing:\n  - `:activities` - List of activity maps\n  - `:entities` - List of entity maps (optional)\n  - `:resources` - List of resource maps (optional)\n  - `:constraints` - Constraint map (optional)\n\n## Returns\n\n- `{:ok, planning_params}` - Success with planning parameters\n- `{:error, reason}` - Transformation failed\n"
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
      {:ok, domain} = transform_activities_to_domain(activities, entities, resources, constraints)
      initial_state = create_initial_state(entities, resources)
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

  @doc "Transform activities to domain format.\n\nConverts MCP activities into a domain structure with actions and methods\nthat the hybrid planner can use.\n"
  @spec transform_activities_to_domain(list(), list(), list(), map()) ::
          {:ok, map()} | {:error, String.t()}
  def transform_activities_to_domain(activities, entities, resources, constraints) do
    Logger.debug("🔧 PlanTransformer: Transforming #{length(activities)} activities to domain")
    actions = create_activity_actions(activities, entities, resources)
    methods = create_activity_methods(activities, entities, resources)
    resource_actions = create_resource_actions(resources)
    all_actions = Map.merge(actions, resource_actions)

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

  @doc "Create initial state with entities and resources.\n"
  @spec create_initial_state(list(), list()) :: map()
  def create_initial_state(entities, resources) do
    initial_state = AriaEngine.State.new()

    state_with_entities =
      entities
      |> Enum.reduce(initial_state, fn entity, state ->
        entity_id = Map.get(entity, :id) || Map.get(entity, "id")
        entity_type = Map.get(entity, :type) || Map.get(entity, "type", :agent)
        capabilities = Map.get(entity, :capabilities) || Map.get(entity, "capabilities", [])

        state
        |> AriaEngine.State.set_fact(entity_id, "type", entity_type)
        |> AriaEngine.State.set_fact(entity_id, "capabilities", capabilities)
        |> AriaEngine.State.set_fact(entity_id, "available", true)
        |> AriaEngine.State.set_fact(entity_id, "current_activity", nil)
      end)

    resources
    |> Enum.reduce(state_with_entities, fn resource, state ->
      resource_id = Map.get(resource, :id) || Map.get(resource, "id")
      resource_type = Map.get(resource, :type) || Map.get(resource, "type", :computational)
      capacity = Map.get(resource, :capacity) || Map.get(resource, "capacity", 1)
      current_usage = Map.get(resource, :current_usage) || Map.get(resource, "current_usage", 0)

      state
      |> AriaEngine.State.set_fact(resource_id, "type", resource_type)
      |> AriaEngine.State.set_fact(resource_id, "capacity", capacity)
      |> AriaEngine.State.set_fact(resource_id, "current_usage", current_usage)
      |> AriaEngine.State.set_fact(resource_id, "available", true)
    end)
  end

  @doc "Generate tasks and goals from activities.\n"
  @spec generate_tasks_and_goals(list()) :: {list(), list()}
  def generate_tasks_and_goals(activities) do
    tasks = [{"schedule_activities", []}]

    goals =
      activities
      |> Enum.map(fn activity ->
        activity_id = Map.get(activity, :id) || Map.get(activity, "id")
        {activity_id, "completed", true}
      end)

    {tasks, goals}
  end

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
      state
      |> AriaEngine.State.set_fact(activity_id, "completed", true)
      |> AriaEngine.State.set_fact(activity_id, "duration", duration)
      |> AriaEngine.State.set_fact(activity_id, "execution_time", DateTime.utc_now())
    end
  end

  defp create_activity_methods(activities, _entities, _resources) do
    schedule_method =
      {"sequential_scheduling",
       fn _args, _state ->
         activities
         |> Enum.map(fn activity ->
           activity_id = Map.get(activity, :id) || Map.get(activity, "id")
           {String.to_atom(activity_id), []}
         end)
       end}

    %{"schedule_activities" => [schedule_method]}
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
      current_usage = AriaEngine.State.get_fact(state, resource_id, "current_usage") || 0

      if current_usage < capacity do
        AriaEngine.State.set_fact(state, resource_id, "current_usage", current_usage + 1)
      else
        false
      end
    end
  end

  defp create_release_action(resource) do
    resource_id = Map.get(resource, :id) || Map.get(resource, "id")

    fn _args, state ->
      current_usage = AriaEngine.State.get_fact(state, resource_id, "current_usage") || 0

      if current_usage > 0 do
        AriaEngine.State.set_fact(state, resource_id, "current_usage", current_usage - 1)
      else
        state
      end
    end
  end
end
