defmodule HybridPlanner.HybridCoordinatorV2.PlanningOperations do
  @moduledoc "Core planning operations for HybridCoordinatorV2.\n\nHandles HTN planning, temporal constraint validation, and plan creation\nusing injected strategy dependencies.\n"
  @type coordinator :: HybridPlanner.HybridCoordinatorV2.t()
  @type plan_result :: {:ok, map()} | {:error, String.t()}
  @doc "Plan goals using injected planning and temporal strategies.\n\nPure Function as Object implementation - all dependencies are injected strategies.\n"
  @spec plan(coordinator(), Domain.Core.t(), AriaEngine.State.t(), [term()], keyword()) ::
          plan_result()
  def plan(
        %coordinator_module{} = coordinator,
        domain,
        %AriaEngine.State{} = state,
        goals,
        opts \\ []
      )
      when coordinator_module == HybridPlanner.HybridCoordinatorV2 do
    _verbose = Keyword.get(opts, :verbose, 0)

    coordinator.logging_strategy.log_progress(
      "planning",
      %{status: "started", goals: length(goals), domain: domain.name},
      opts
    )

    try do
      case coordinator.planning_strategy.plan(domain, state, goals, opts) do
        {:ok, solution_tree} ->
          coordinator.logging_strategy.log_progress(
            "planning",
            %{
              status: "htn_completed",
              solution_tree_size: count_solution_tree_nodes(solution_tree)
            },
            opts
          )

          case add_temporal_constraints_to_plan(coordinator, solution_tree, domain, opts) do
            {:ok, temporal_constraints} ->
              case coordinator.temporal_strategy.validate_temporal_consistency(
                     temporal_constraints,
                     opts
                   ) do
                {:ok, true} ->
                  coordinator.logging_strategy.log_progress(
                    "planning",
                    %{status: "completed_successfully"},
                    opts
                  )

                  {:ok,
                   %{
                     solution_tree: solution_tree,
                     temporal_constraints: temporal_constraints,
                     metadata: %{
                       goals: goals,
                       domain_name: domain.name,
                       planning_time: System.system_time(:millisecond),
                       strategy_coordinator: coordinator.metadata
                     }
                   }}

                {:ok, false} ->
                  error_msg = "Temporal constraints are inconsistent"

                  coordinator.logging_strategy.log_error(
                    error_msg,
                    %{phase: "temporal_validation"},
                    opts
                  )

                  {:error, error_msg}

                {:error, reason} ->
                  coordinator.logging_strategy.log_error(
                    reason,
                    %{phase: "temporal_validation"},
                    opts
                  )

                  {:error, "Temporal validation failed: #{reason}"}
              end

            {:error, reason} ->
              coordinator.logging_strategy.log_error(
                reason,
                %{phase: "temporal_constraint_creation"},
                opts
              )

              {:error, "Failed to create temporal constraints: #{reason}"}
          end

        {:error, reason} ->
          coordinator.logging_strategy.log_error(reason, %{phase: "htn_planning"}, opts)
          {:error, reason}
      end
    rescue
      e ->
        error_msg = "Planning error: #{Exception.message(e)}"
        coordinator.logging_strategy.log_error(error_msg, %{phase: "planning_coordinator"}, opts)
        {:error, error_msg}
    end
  end

  @doc "Validate a plan using injected planning strategy.\n"
  @spec validate_plan(coordinator(), Domain.Core.t(), AriaEngine.State.t(), map()) ::
          {:ok, AriaEngine.State.t()} | {:error, String.t()}
  def validate_plan(
        %coordinator_module{} = coordinator,
        domain,
        %AriaEngine.State{} = initial_state,
        plan
      )
      when coordinator_module == HybridPlanner.HybridCoordinatorV2 do
    try do
      solution_tree = Map.get(plan, :solution_tree)

      if is_nil(solution_tree) do
        {:error, "Invalid plan format for validation - missing solution tree"}
      else
        coordinator.planning_strategy.validate_plan(domain, initial_state, solution_tree)
      end
    rescue
      e -> {:error, "Plan validation error: #{Exception.message(e)}"}
    end
  end

  @doc "Simple plan interface for backward compatibility.\n"
  @spec plan(coordinator(), map()) :: plan_result()
  def plan(
        %coordinator_module{} = coordinator,
        %{domain: domain, state: state, goals: goals} = request
      )
      when coordinator_module == HybridPlanner.HybridCoordinatorV2 do
    opts = Map.get(request, :opts, [])
    plan(coordinator, domain, state, goals, opts)
  end

  defp add_temporal_constraints_to_plan(coordinator, solution_tree, _domain, opts) do
    primitive_actions = extract_primitive_actions(solution_tree)
    current_time = Keyword.get(opts, :current_time, 0)

    coordinator.temporal_strategy.add_temporal_constraints(
      %{},
      primitive_actions,
      Keyword.merge(opts, current_time: current_time)
    )
  end

  defp extract_primitive_actions(solution_tree) do
    case solution_tree do
      %{children: children} when is_list(children) ->
        Enum.flat_map(children, &extract_primitive_actions/1)

      %{task: {action_name, args}, status: :primitive} ->
        [{action_name, args}]

      %{task: task} when is_tuple(task) ->
        [task]

      _ ->
        []
    end
  end

  defp count_solution_tree_nodes(solution_tree) do
    case solution_tree do
      %{children: children} when is_list(children) ->
        1 + Enum.sum(Enum.map(children, &count_solution_tree_nodes/1))

      _ ->
        1
    end
  end
end