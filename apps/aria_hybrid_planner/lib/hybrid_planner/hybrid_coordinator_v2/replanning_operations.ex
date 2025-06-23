# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule HybridPlanner.HybridCoordinatorV2.ReplanningOperations do
  @moduledoc "Replanning operations for HybridCoordinatorV2.\n\nHandles replanning from failure points using injected planning and temporal strategies.\n"
  @type coordinator :: HybridPlanner.HybridCoordinatorV2.t()
  @type replan_result :: {:ok, map()} | {:error, String.t()} | :failure
  @doc "Replan from a failure point using injected planning and temporal strategies.\n"
  @spec replan(
          coordinator(),
          Domain.Core.t(),
          AriaEngine.State.t(),
          map(),
          String.t(),
          keyword()
        ) :: replan_result()
  def replan(
        %coordinator_module{} = coordinator,
        domain,
        %AriaEngine.State{} = state,
        plan,
        fail_node_id,
        opts \\ []
      )
      when coordinator_module == HybridPlanner.HybridCoordinatorV2 do
    coordinator.logging_strategy.log_progress(
      "replanning",
      %{status: "started", fail_node_id: fail_node_id},
      opts
    )

    try do
      solution_tree = Map.get(plan, :solution_tree)

      if is_nil(solution_tree) do
        {:error, "Invalid plan format for replanning - missing solution tree"}
      else
        case coordinator.planning_strategy.replan(
               domain,
               state,
               solution_tree,
               fail_node_id,
               opts
             ) do
          {:ok, new_solution_tree} ->
            coordinator.logging_strategy.log_progress(
              "replanning",
              %{status: "htn_replanning_completed"},
              opts
            )

            case add_temporal_constraints_to_plan(coordinator, new_solution_tree, domain, opts) do
              {:ok, new_temporal_constraints} ->
                case coordinator.temporal_strategy.validate_temporal_consistency(
                       new_temporal_constraints,
                       opts
                     ) do
                  {:ok, true} ->
                    coordinator.logging_strategy.log_progress(
                      "replanning",
                      %{status: "completed_successfully"},
                      opts
                    )

                    original_metadata = Map.get(plan, :metadata, %{})

                    replan_metadata =
                      Map.merge(original_metadata, %{
                        replanned_at: System.system_time(:millisecond),
                        original_fail_node: fail_node_id,
                        strategy_coordinator: coordinator.metadata
                      })

                    {:ok,
                     %{
                       solution_tree: new_solution_tree,
                       temporal_constraints: new_temporal_constraints,
                       metadata: replan_metadata
                     }}

                  {:ok, false} ->
                    error_msg = "Replanned temporal constraints are inconsistent"

                    coordinator.logging_strategy.log_error(
                      error_msg,
                      %{phase: "replanning_temporal_validation"},
                      opts
                    )

                    {:error, error_msg}

                  {:error, reason} ->
                    coordinator.logging_strategy.log_error(
                      reason,
                      %{phase: "replanning_temporal_validation"},
                      opts
                    )

                    {:error, "Replanning temporal validation failed: #{reason}"}
                end

              {:error, reason} ->
                coordinator.logging_strategy.log_error(
                  reason,
                  %{phase: "replanning_temporal_constraints"},
                  opts
                )

                {:error, "Failed to create temporal constraints during replanning: #{reason}"}
            end

          {:error, reason} ->
            coordinator.logging_strategy.log_error(reason, %{phase: "htn_replanning"}, opts)
            {:error, reason}

          :failure ->
            coordinator.logging_strategy.log_progress(
              "replanning",
              %{status: "no_alternatives_found"},
              opts
            )

            :failure
        end
      end
    rescue
      e ->
        error_msg = "Replanning error: #{Exception.message(e)}"

        coordinator.logging_strategy.log_error(
          error_msg,
          %{phase: "replanning_coordinator"},
          opts
        )

        {:error, error_msg}
    end
  end

  @doc "Simple replan interface for backward compatibility.\n"
  @spec replan(coordinator(), map()) :: replan_result()
  def replan(
        %coordinator_module{} = coordinator,
        %{domain: domain, state: state, plan: plan, fail_node_id: fail_node_id} = request
      )
      when coordinator_module == HybridPlanner.HybridCoordinatorV2 do
    opts = Map.get(request, :opts, [])
    replan(coordinator, domain, state, plan, fail_node_id, opts)
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
end