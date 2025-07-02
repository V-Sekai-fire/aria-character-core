# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule HybridPlanner.HybridCoordinatorV2.Planning do
  @moduledoc """
  HTN planning functions for HybridCoordinatorV2.

  Handles HTN planning, replanning, and plan validation for todo lists only.
  This module does not support goal-to-todo conversion - only todo lists are accepted.
  """

  require Logger
  alias Plan.Utils

  @doc """
  Validate a plan using HTN planning validation.
  """
  @spec htn_validate_plan(Domain.Core.t(), State.t(), map()) ::
          {:ok, State.t()} | {:error, String.t()}
  def htn_validate_plan(domain, initial_state, solution_tree) do
    try do
      primitive_actions = Utils.get_primitive_actions_dfs(solution_tree)

      case Utils.validate_plan(domain, initial_state, primitive_actions) do
        {:ok, final_state} -> {:ok, final_state}
        {:error, reason} -> {:error, reason}
      end
    rescue
      e ->
        error_msg = "HTN validation error: #{Exception.message(e)}"
        Logger.error(error_msg)
        {:error, error_msg}
    end
  end

  # ==================== PRIVATE FUNCTIONS ====================
end
