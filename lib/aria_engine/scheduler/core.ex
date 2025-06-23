defmodule AriaEngine.Scheduler.Core do
  @moduledoc "Private implementation core for AriaEngine.Scheduler.\n\nOrchestrates the scheduling process by coordinating between specialized modules\nfor domain conversion, state management, plan conversion, and analysis.\n\nThis module should not be used directly - use AriaEngine.Scheduler instead.\n"
  require Logger
  alias AriaEngine.Scheduler.{DomainConverter, StateManager, PlanConverter, ResourceManager}
  @doc "Main scheduling function with enhanced features.\n"
  def schedule_with_enhanced_features(
        schedule_name,
        activities,
        entities,
        resources,
        constraints,
        simulation_mode,
        activity_log,
        verbose,
        base_datetime
      ) do
    case validate_base_datetime(base_datetime) do
      {:error, reason} ->
        {:error,
         "Missing or invalid base_datetime parameter: #{reason}. base_datetime must be explicitly provided as a DateTime struct."}

      {:ok, _validated_datetime} ->
        if verbose > 1 do
          Logger.debug("AriaEngine.Scheduler: Initializing enhanced scheduling system")
        end

        do_schedule_with_enhanced_features(
          schedule_name,
          activities,
          entities,
          resources,
          constraints,
          simulation_mode,
          activity_log,
          verbose,
          base_datetime
        )
    end
  end

  defp validate_base_datetime(nil) do
    {:error, "base_datetime cannot be nil"}
  end

  defp validate_base_datetime(%DateTime{} = dt) do
    {:ok, dt}
  end

  defp validate_base_datetime(_) do
    {:error, "base_datetime must be a DateTime struct"}
  end

  defp do_schedule_with_enhanced_features(
         schedule_name,
         activities,
         entities,
         resources,
         constraints,
         simulation_mode,
         activity_log,
         verbose,
         base_datetime
       ) do
    if Enum.empty?(activities) do
      return_empty_schedule_result(
        schedule_name,
        entities,
        resources,
        simulation_mode,
        activity_log
      )
    else
      scheduling_params = %{
        schedule_name: schedule_name,
        activities: activities,
        entities: entities,
        resources: resources,
        constraints: constraints,
        simulation_mode: simulation_mode,
        activity_log: activity_log,
        verbose: verbose,
        base_datetime: base_datetime,
        opts: []
      }

      case attempt_enhanced_scheduling(scheduling_params) do
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
            reason:
              if simulation_mode do
                "Simulation completed successfully"
              else
                "Schedule successfully generated"
              end,
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

  @doc "Handle empty activities case.\n"
  def return_empty_schedule_result(
        schedule_name,
        entities,
        resources,
        simulation_mode,
        _activity_log
      ) do
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

  @doc "Enhanced scheduling with entity/resource management.\n"
  def attempt_enhanced_scheduling(scheduling_params) do
    %{
      schedule_name: _schedule_name,
      activities: activities,
      entities: entities,
      resources: resources,
      constraints: constraints,
      simulation_mode: simulation_mode,
      activity_log: activity_log,
      verbose: verbose,
      base_datetime: base_datetime,
      opts: _opts
    } = scheduling_params

    Logger.info(
      "🔧 Scheduler.Core.attempt_enhanced_scheduling() called with #{length(activities)} activities"
    )

    Logger.info("🔧 Entities: #{length(entities)}, Resources: #{length(resources)}")
    Logger.info("🔧 Verbose: #{verbose}, Simulation mode: #{simulation_mode}")

    if verbose > 1 do
      Logger.debug(
        "AriaEngine.Scheduler: Attempting enhanced scheduling with #{length(entities)} entities and #{length(resources)} resources"
      )
    end

    Logger.info("🔧 Calling convert_activities_to_enhanced_domain()...")

    case convert_activities_to_enhanced_domain(activities, entities, resources, constraints) do
      {:ok, domain} ->
        Logger.info("🔧 Domain conversion successful!")
        Logger.info("🔧 Creating enhanced initial state...")
        resources_list = convert_resources_map_to_list(resources)
        entities_list = convert_entities_to_list(entities)
        initial_state = create_enhanced_initial_state(entities_list, resources_list)
        Logger.info("🔧 Converting activities to tasks and goals...")
        {tasks, goals} = StateManager.convert_activities_to_tasks_and_goals(activities)
        Logger.info("🔧 Generated #{length(tasks)} tasks and #{length(goals)} goals")

        if verbose > 2 do
          Logger.debug(
            "AriaEngine.Scheduler: Created enhanced domain with #{map_size(domain.actions)} actions"
          )

          Logger.debug(
            "AriaEngine.Scheduler: Generated #{length(tasks)} tasks and #{length(goals)} goals"
          )
        end

        Logger.info("🔧 About to call AriaEngine.PlannerAdapter.plan_tasks()...")
        planner_opts = [verbose: verbose]

        case AriaEngine.PlannerAdapter.plan_tasks(domain, initial_state, tasks, planner_opts) do
          {:ok, solution_tree} ->
            encapsulated_plan =
              HybridPlanner.DataStructures.EncapsulatedPlan.new(solution_tree, %{
                source: "AriaEngine.PlannerAdapter.plan_tasks",
                scheduler_wrapped: true
              })

            if simulation_mode do
              simulate_plan_execution(
                domain,
                initial_state,
                encapsulated_plan,
                activities,
                entities,
                resources,
                activity_log,
                verbose
              )
            else
              schedule =
                convert_plan_to_enhanced_schedule(
                  encapsulated_plan,
                  activities,
                  entities,
                  resources,
                  base_datetime
                )

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

  @doc "Simulate plan execution using run_lazy_refineahead.\n"
  def simulate_plan_execution(
        domain,
        initial_state,
        encapsulated_plan,
        activities,
        entities,
        resources,
        _activity_log,
        verbose
      ) do
    if verbose > 1 do
      Logger.debug("AriaEngine.Scheduler: Running simulation with run_lazy_refineahead")
    end

    internal_plan =
      HybridPlanner.DataStructures.EncapsulatedPlan.get_internal_plan(encapsulated_plan)

    case Plan.run_lazy_refineahead(domain, initial_state, internal_plan, verbose: verbose) do
      {:ok, final_state} ->
        schedule =
          convert_simulation_to_schedule(
            encapsulated_plan,
            final_state,
            activities,
            entities,
            resources
          )

        {:ok, schedule}

      {:error, reason} ->
        {:error, "Simulation execution failed: #{reason}"}
    end
  end

  @doc "Convert activities to KHR domain with two-phase planning.\n"
  def convert_activities_to_enhanced_domain(activities, entities, resources, constraints) do
    resources_list = convert_resources_map_to_list(resources)
    entities_list = convert_entities_to_list(entities)

    DomainConverter.convert_activities_to_khr_domain(
      activities,
      entities_list,
      resources_list,
      constraints
    )
  end

  @doc "Create enhanced initial state with entities and resources.\n"
  def create_enhanced_initial_state(entities, resources) do
    StateManager.create_enhanced_initial_state(entities, resources)
  end

  @doc "Convert activities to goals format.\n"
  def convert_activities_to_goals(activities) do
    StateManager.convert_activities_to_goals(activities)
  end

  @doc "Create enhanced activity action with resource management.\n"
  def create_enhanced_activity_action(activity, entities, resources) do
    fn _args, state ->
      activity_id = activity.id
      duration_val = Map.get(activity, :duration)

      {duration, _fixed_start, _fixed_end} =
        cond do
          is_map(duration_val) and Map.has_key?(duration_val, :start) and
              Map.has_key?(duration_val, :end) ->
            {duration_val, duration_val[:start], duration_val[:end]}

          is_map(duration_val) ->
            {duration_val, nil, nil}

          is_binary(duration_val) ->
            case :iso8601.parse_duration(String.to_charlist(duration_val)) do
              parsed when is_list(parsed) ->
                map = Enum.into(parsed, %{})
                {map, nil, nil}

              _ ->
                {nil, nil, nil}
            end

          true ->
            {nil, nil, nil}
        end

      required_capabilities = Map.get(activity, :required_capabilities, [])
      required_resources = Map.get(activity, :required_resources, [])

      case allocate_resources_for_activity(
             state,
             activity_id,
             required_capabilities,
             required_resources,
             entities,
             resources
           ) do
        {:ok, updated_state} ->
          updated_state
          |> AriaEngine.State.set_fact(activity_id, "completed", true)
          |> AriaEngine.State.set_fact(activity_id, "duration", duration)
          |> AriaEngine.State.set_fact(activity_id, "execution_time", DateTime.utc_now())

        {:error, _reason} ->
          false
      end
    end
  end

  @doc "Create enhanced activity method with resource constraints.\n"
  def create_enhanced_activity_method(activity, entities, resources) do
    fn _args, state ->
      activity_id = activity.id
      dependencies = Map.get(activity, :dependencies, [])
      required_capabilities = Map.get(activity, :required_capabilities, [])
      required_resources = Map.get(activity, :required_resources, [])

      deps_satisfied =
        Enum.all?(dependencies, fn dep_id ->
          AriaEngine.State.matches_exactly?(state, dep_id, "completed", true)
        end)

      resources_available =
        check_resource_availability(
          state,
          required_capabilities,
          required_resources,
          entities,
          resources
        )

      if deps_satisfied and resources_available do
        [{String.to_atom(activity_id), []}]
      else
        incomplete_deps =
          Enum.filter(dependencies, fn dep_id ->
            not AriaEngine.State.matches_exactly?(state, dep_id, "completed", true)
          end)

        if not Enum.empty?(incomplete_deps) do
          dep_tasks = Enum.map(incomplete_deps, fn dep_id -> "complete_#{dep_id}" end)
          dep_tasks ++ [{String.to_atom(activity_id), []}]
        else
          false
        end
      end
    end
  end

  defp allocate_resources_for_activity(
         state,
         activity_id,
         required_capabilities,
         required_resources,
         entities,
         resources
       ) do
    ResourceManager.allocate_resources_for_activity(
      state,
      activity_id,
      required_capabilities,
      required_resources,
      entities,
      resources
    )
  end

  defp check_resource_availability(
         state,
         required_capabilities,
         required_resources,
         entities,
         resources
       ) do
    ResourceManager.check_resource_availability(
      state,
      required_capabilities,
      required_resources,
      entities,
      resources
    )
  end

  @doc "Create resource management actions.\n"
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
      current_usage = AriaEngine.State.get_fact(state, resource.id, "current_usage") || 0

      if current_usage < resource.capacity do
        AriaEngine.State.set_fact(state, resource.id, "current_usage", current_usage + 1)
      else
        false
      end
    end
  end

  defp create_release_resource_action(resource) do
    fn _args, state ->
      current_usage = AriaEngine.State.get_fact(state, resource.id, "current_usage") || 0

      if current_usage > 0 do
        AriaEngine.State.set_fact(state, resource.id, "current_usage", current_usage - 1)
      else
        state
      end
    end
  end

  @doc "Create enhanced scheduling methods.\n"
  def create_enhanced_scheduling_methods(activities, _entities, _resources) do
    %{
      "schedule_all" => [
        {"resource_aware_sequential",
         fn _args, _state ->
           activities |> Enum.map(fn activity -> "complete_#{activity.id}" end)
         end}
      ]
    }
  end

  @doc "Create action metadata for durative actions.\n"
  def create_action_metadata(activities, _entities, _resources) do
    activities
    |> Enum.map(fn activity ->
      action_name = String.to_atom(activity.id)
      duration_val = Map.get(activity, :duration)

      {duration, _fixed_start, _fixed_end} =
        cond do
          is_map(duration_val) and Map.has_key?(duration_val, :start) and
              Map.has_key?(duration_val, :end) ->
            {duration_val, duration_val[:start], duration_val[:end]}

          is_map(duration_val) ->
            {duration_val, nil, nil}

          is_binary(duration_val) ->
            case :iso8601.parse_duration(String.to_charlist(duration_val)) do
              parsed when is_list(parsed) ->
                map = Enum.into(parsed, %{})
                {map, nil, nil}

              _ ->
                {nil, nil, nil}
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

  @doc "Convert plan to enhanced schedule format.\n"
  def convert_plan_to_enhanced_schedule(
        encapsulated_plan,
        activities,
        entities,
        resources,
        base_datetime
      ) do
    PlanConverter.convert_plan_to_enhanced_schedule(
      encapsulated_plan,
      activities,
      entities,
      resources,
      base_datetime
    )
  end

  @doc "Convert simulation results to schedule format.\n"
  def convert_simulation_to_schedule(
        encapsulated_plan,
        final_state,
        activities,
        entities,
        resources
      ) do
    base_datetime = DateTime.utc_now()

    PlanConverter.convert_simulation_to_schedule(
      encapsulated_plan,
      final_state,
      activities,
      entities,
      resources,
      base_datetime
    )
  end

  defp convert_resources_map_to_list(resources) when is_map(resources) do
    Enum.map(resources, fn {resource_id, resource_data} ->
      %{
        id: resource_id,
        type: Map.get(resource_data, "type", "unknown"),
        capacity: Map.get(resource_data, "capacity", 1),
        current_usage: Map.get(resource_data, "current_usage", 0),
        constraints: Map.get(resource_data, "constraints", %{}),
        availability_schedule: Map.get(resource_data, "availability_schedule", []),
        metadata: Map.get(resource_data, "metadata", %{})
      }
    end)
  end

  defp convert_resources_map_to_list(resources) when is_list(resources) do
    resources
  end

  defp convert_entities_to_list(entities) when is_list(entities) do
    Enum.map(entities, fn entity ->
      if is_map(entity) and Map.has_key?(entity, "id") do
        %{
          id: Map.get(entity, "id"),
          type: Map.get(entity, "type", "unknown"),
          capabilities: Map.get(entity, "capabilities", []),
          availability: Map.get(entity, "availability", %{}),
          current_activity: Map.get(entity, "current_activity"),
          resources_held: Map.get(entity, "resources_held", []),
          metadata: Map.get(entity, "metadata", %{})
        }
      else
        entity
      end
    end)
  end

  defp convert_entities_to_list(entities) when is_map(entities) do
    Enum.map(entities, fn {entity_id, entity_data} ->
      %{
        id: entity_id,
        type: Map.get(entity_data, "type", "unknown"),
        capabilities: Map.get(entity_data, "capabilities", []),
        availability: Map.get(entity_data, "availability", %{}),
        current_activity: Map.get(entity_data, "current_activity"),
        resources_held: Map.get(entity_data, "resources_held", []),
        metadata: Map.get(entity_data, "metadata", %{})
      }
    end)
  end
end