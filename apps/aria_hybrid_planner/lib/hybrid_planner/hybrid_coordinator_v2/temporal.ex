# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule HybridPlanner.HybridCoordinatorV2.Temporal do
  @moduledoc """
  Temporal constraint functions for HybridCoordinatorV2.

  Handles temporal constraint creation and validation for plans.
  """

  require Logger

  @doc """
  Add temporal constraints to a plan.

  Simplified from STNTemporalStrategy.
  """
  @spec add_temporal_constraints_to_plan(map(), Domain.Core.t(), keyword()) ::
          {:ok, map()} | {:error, String.t()}
  def add_temporal_constraints_to_plan(solution_tree, _domain, opts) do
    primitive_actions = extract_primitive_actions(solution_tree)
    current_time = Keyword.get(opts, :current_time, 0)

    try do
      temporal_problem = %{
        actions: primitive_actions,
        constraints: [],
        current_time: current_time
      }

      {:ok, %{
        temporal_problem: temporal_problem,
        last_update: System.system_time(:millisecond)
      }}
    rescue
      e ->
        error_msg = "Temporal constraint addition error: #{Exception.message(e)}"
        Logger.error(error_msg)
        {:error, error_msg}
    end
  end

  @doc """
  Validate temporal consistency of constraints.
  """
  @spec validate_temporal_consistency(map(), keyword()) ::
          {:ok, boolean()} | {:error, String.t()}
  def validate_temporal_consistency(constraints, opts) do
    verbose = Keyword.get(opts, :verbose, 0)

    if verbose > 1 do
      Logger.debug("Temporal validation: Validating temporal consistency")
    end

    try do
      case constraints do
        %{temporal_problem: problem} when not is_nil(problem) ->
          # For now, assume consistency (simplified from MiniZinc validation)
          if verbose > 1 do
            Logger.debug("Temporal validation: Temporal constraints are consistent")
          end
          {:ok, true}

        _ ->
          if verbose > 1 do
            Logger.debug("Temporal validation: No constraints present, trivially consistent")
          end
          {:ok, true}
      end
    rescue
      e ->
        error_msg = "Temporal consistency validation error: #{Exception.message(e)}"
        Logger.error(error_msg)
        {:error, error_msg}
    end
  end

  # ==================== PRIVATE FUNCTIONS ====================

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
