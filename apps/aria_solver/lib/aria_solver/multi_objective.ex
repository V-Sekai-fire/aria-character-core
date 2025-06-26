# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaSolver.MultiObjective do
  @moduledoc """
  Multi-objective optimization solver for AriaSolver.

  This module provides multi-objective constraint solving capabilities,
  migrated from `aria_minizinc_multiply` as part of ADR-193 layered 
  architecture consolidation.

  ## Usage

      # Multi-objective solving
      {:ok, solution} = AriaSolver.MultiObjective.solve(domain, state, goals, opts)
  """

  require Logger

  @type domain :: term()
  @type state :: term()
  @type goal :: {String.t(), String.t(), term()}
  @type solution :: term()
  @type error_reason :: String.t()

  @doc """
  Solve multi-objective optimization problems.

  ## Parameters
  - `domain` - Planning domain specification
  - `state` - Current state
  - `goals` - List of goals in ADR-181 format
  - `opts` - Solver options

  ## Returns
  - `{:ok, solution}` - Successfully solved with Pareto-optimal solutions
  - `{:error, reason}` - Failed to solve
  """
  @spec solve(domain(), state(), [goal()], keyword()) :: 
    {:ok, solution()} | {:error, error_reason()}
  def solve(domain, state, goals, opts \\ []) do
    # Placeholder implementation - will be migrated from aria_minizinc_multiply
    Logger.info("MultiObjective solver called with #{length(goals)} goals")
    
    # For now, delegate to Goal solver for single objective
    case goals do
      [single_goal] ->
        AriaSolver.Goal.solve_goals(domain, state, [single_goal], %{}, opts)
      multiple_goals ->
        # Simplified multi-objective: solve each goal independently
        results = Enum.map(multiple_goals, fn goal ->
          AriaSolver.Goal.solve_goals(domain, state, [goal], %{}, opts)
        end)
        
        case Enum.find(results, fn {status, _} -> status == :error end) do
          nil ->
            solutions = Enum.map(results, fn {:ok, solution} -> solution end)
            {:ok, %{status: :success, solutions: solutions, solver: :multi_objective}}
          {:error, reason} ->
            {:error, reason}
        end
    end
  end
end
