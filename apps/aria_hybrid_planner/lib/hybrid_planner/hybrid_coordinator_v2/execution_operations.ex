# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule HybridPlanner.HybridCoordinatorV2.ExecutionOperations do
  alias AriaEngine.State

  @moduledoc "Execution operations for HybridCoordinatorV2.\n\nHandles plan execution using injected execution strategy dependencies.\n"
  @type coordinator :: HybridPlanner.HybridCoordinatorV2.t()
  @type execution_result :: {:ok, AriaEngine.State.t()} | {:error, String.t()}
  @doc "Execute a plan using injected execution strategy.\n"
  @spec execute(coordinator(), Domain.Core.t(), AriaEngine.State.t(), map(), keyword()) ::
          execution_result()
  def execute(
        %coordinator_module{} = coordinator,
        domain,
        %AriaEngine.State{} = initial_state,
        plan,
        opts \\ []
      )
      when coordinator_module == HybridPlanner.HybridCoordinatorV2 do
    coordinator.logging_strategy.log_progress(
      "execution",
      %{status: "started"},
      opts
    )

    try do
      solution_tree = Map.get(plan, :solution_tree)
      _temporal_constraints = Map.get(plan, :temporal_constraints)

      if is_nil(solution_tree) do
        {:error, "Invalid plan format - missing solution tree"}
      else
        strategies = extract_strategies_map(coordinator)
        enhanced_opts = Keyword.put(opts, :domain, domain)

        case coordinator.execution_strategy.execute_plan(
               solution_tree,
               initial_state,
               strategies,
               enhanced_opts
             ) do
          {:ok, final_state} ->
            coordinator.logging_strategy.log_progress(
              "execution",
              %{status: "completed_successfully"},
              opts
            )

            {:ok, final_state}

          {:error, reason} ->
            coordinator.logging_strategy.log_error(reason, %{phase: "execution"}, opts)
            {:error, reason}
        end
      end
    rescue
      e ->
        error_msg = "Execution error: #{Exception.message(e)}"
        coordinator.logging_strategy.log_error(error_msg, %{phase: "execution_coordinator"}, opts)
        {:error, error_msg}
    end
  end

  defp extract_strategies_map(coordinator) do
    %{
      planning_strategy: coordinator.planning_strategy,
      temporal_strategy: coordinator.temporal_strategy,
      state_strategy: coordinator.state_strategy,
      domain_strategy: coordinator.domain_strategy,
      logging_strategy: coordinator.logging_strategy,
      execution_strategy: coordinator.execution_strategy
    }
  end
end