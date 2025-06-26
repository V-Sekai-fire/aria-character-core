# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaSolver.Timeline do
  @moduledoc """
  Timeline-based planning solver for AriaSolver.

  This module provides timeline-based planning capabilities with temporal
  reasoning, migrated from `aria_timeline` as part of ADR-193 layered 
  architecture consolidation.

  ## Usage

      # Timeline planning
      {:ok, solution} = AriaSolver.Timeline.plan(domain, state, goals, opts)
  """

  require Logger

  @type domain :: term()
  @type state :: term()
  @type goal :: {String.t(), String.t(), term()}
  @type solution :: term()
  @type error_reason :: String.t()

  @doc """
  Plan using timeline-based approach.

  ## Parameters
  - `domain` - ADR-181 compliant domain specification
  - `state` - Current state
  - `goals` - List of goals in {predicate, subject, value} format
  - `opts` - Planning options

  ## Returns
  - `{:ok, solution}` - Successfully planned timeline solution
  - `{:error, reason}` - Failed to plan
  """
  @spec plan(domain(), state(), [goal()], keyword()) :: 
    {:ok, solution()} | {:error, error_reason()}
  def plan(domain, state, goals, opts \\ []) do
    # Placeholder implementation - will be migrated from aria_timeline
    Logger.info("Timeline planner called with #{length(goals)} goals")
    
    # For now, delegate to temporal planner
    AriaSolver.TemporalPlanner.plan(domain, state, goals, opts)
  end
end
