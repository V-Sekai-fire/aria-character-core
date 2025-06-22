# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule HybridPlanner.HybridCoordinatorV2.PlanningOperations do
  @moduledoc """
  Core planning operations for HybridCoordinatorV2.

  Handles HTN planning, temporal constraint validation, and plan creation
  using injected strategy dependencies.
  """

  @type coordinator :: HybridPlanner.HybridCoordinatorV2.t()
  @type plan_result :: {:ok, map()} | {:error, String.t()}

  @doc """
  Plan goals using injected planning and temporal strategies.

  Pure Function as Object implementation - all dependencies are injected strategies.
  """
  @spec plan(coordinator(), Domain.Core.t(), AriaEngine.StateV2.t(), [term()], keyword()) ::
          plan_result()
  def plan(
        %coordinator_module{} = coordinator,
        domain,
        %AriaEngine.StateV2{} = state,
        goals,
        opts \\ []
      )
      when coordinator_module == HybridPlanner.HybridCoordinatorV2 do
    _verbose = Keyword.get(opts, :verbose, 0)

    # Log start using injected logging strategy
    coordinator.logging_strategy.log_progress(
      "planning",
      %{
        status: "started",
        goals: length(goals),
        domain: domain.name
      },
      opts
    )

    try do
      # Phase 1: HTN Planning using injected planning strategy
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

          # Phase 2: Temporal Validation using injected temporal strategy
          case add_temporal_constraints_to_plan(coordinator, solution_tree, domain, opts) do
            {:ok, temporal_constraints} ->
              # Phase 3: Validate temporal consistency
              case coordinator.temporal_strategy.validate_temporal_consistency(
                     temporal_constraints,
                     opts
                   ) do
                {:ok, true} ->
                  coordinator.logging_strategy.log_progress(
                    "planning",
                    %{
                      status: "completed_successfully"
                    },
                    opts
                  )

                  # Return composite plan with both HTN and temporal information
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

  @doc """
  Validate a plan using injected planning strategy.
  """
  @spec validate_plan(coordinator(), Domain.Core.t(), AriaEngine.StateV2.t(), map()) ::
          {:ok, AriaEngine.StateV2.t()} | {:error, String.t()}
  def validate_plan(
        %coordinator_module{} = coordinator,
        domain,
        %AriaEngine.StateV2{} = initial_state,
        plan
      )
      when coordinator_module == HybridPlanner.HybridCoordinatorV2 do
    try do
      solution_tree = Map.get(plan, :solution_tree)

      if is_nil(solution_tree) do
        {:error, "Invalid plan format for validation - missing solution tree"}
      else
        # Use injected planning strategy for validation
        coordinator.planning_strategy.validate_plan(domain, initial_state, solution_tree)
      end
    rescue
      e ->
        {:error, "Plan validation error: #{Exception.message(e)}"}
    end
  end

  @doc """
  Simple plan interface for backward compatibility.
  """
  @spec plan(coordinator(), map()) :: plan_result()
  def plan(
        %coordinator_module{} = coordinator,
        %{domain: domain, state: state, goals: goals} = request
      )
      when coordinator_module == HybridPlanner.HybridCoordinatorV2 do
    opts = Map.get(request, :opts, [])
    plan(coordinator, domain, state, goals, opts)
  end

  # ==================== PRIVATE HELPER FUNCTIONS ====================

  # Add temporal constraints to a plan using the temporal strategy
  defp add_temporal_constraints_to_plan(coordinator, solution_tree, _domain, opts) do
    # Extract primitive actions from solution tree
    primitive_actions = extract_primitive_actions(solution_tree)
    current_time = Keyword.get(opts, :current_time, 0)

    # Use temporal strategy to add constraints
    coordinator.temporal_strategy.add_temporal_constraints(
      %{},
      primitive_actions,
      Keyword.merge(opts, current_time: current_time)
    )
  end

  # Extract primitive actions from solution tree
  defp extract_primitive_actions(solution_tree) do
    # This is a simplified extraction - in reality this would traverse the tree
    # For now, assume the solution tree has a predictable structure
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

  # Count nodes in solution tree for metrics
  defp count_solution_tree_nodes(solution_tree) do
    case solution_tree do
      %{children: children} when is_list(children) ->
        1 + Enum.sum(Enum.map(children, &count_solution_tree_nodes/1))

      _ ->
        1
    end
  end
end
