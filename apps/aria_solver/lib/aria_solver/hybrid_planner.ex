# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaSolver.HybridPlanner do
  @moduledoc """
  Hybrid planning solver for AriaSolver.

  This module provides hybrid planning capabilities combining multiple
  planning approaches, migrated from `aria_hybrid_planner` as part of 
  ADR-193 layered architecture consolidation.

  ## Usage

      # Hybrid planning
      {:ok, solution} = AriaSolver.HybridPlanner.plan(domain, state, goals, opts)
  """

  require Logger

  @type domain :: term()
  @type state :: term()
  @type goal :: {String.t(), String.t(), term()}
  @type solution :: term()
  @type error_reason :: String.t()

  @doc """
  Plan using hybrid planning approach.

  ## Parameters
  - `domain` - ADR-181 compliant domain specification
  - `state` - Current state
  - `goals` - List of goals in {predicate, subject, value} format
  - `opts` - Planning options

  ## Returns
  - `{:ok, solution}` - Successfully planned solution
  - `{:error, reason}` - Failed to plan
  """
  @spec plan(domain(), state(), [goal()], keyword()) :: 
    {:ok, solution()} | {:error, error_reason()}
  def plan(domain, state, goals, opts \\ []) do
    # Placeholder implementation - will be migrated from aria_hybrid_planner
    Logger.info("Hybrid planner called with #{length(goals)} goals")
    
    # For now, delegate to Engine planner
    AriaSolver.Engine.plan(domain, state, goals)
  end
end
