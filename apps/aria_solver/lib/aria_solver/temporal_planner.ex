# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaSolver.TemporalPlanner do
  @moduledoc """
  Temporal planning solver for AriaSolver.

  This module provides temporal planning capabilities with durative actions
  and temporal constraints, migrated from `aria_temporal_planner` as part of 
  ADR-193 layered architecture consolidation.

  ## Usage

      # Temporal planning
      {:ok, solution} = AriaSolver.TemporalPlanner.plan(domain, state, goals, opts)
  """

  require Logger

  @type domain :: term()
  @type state :: term()
  @type goal :: {String.t(), String.t(), term()}
  @type solution :: term()
  @type error_reason :: String.t()

  @doc """
  Plan using temporal planning approach.

  ## Parameters
  - `domain` - ADR-181 compliant domain specification with temporal actions
  - `state` - Current state
  - `goals` - List of goals in {predicate, subject, value} format
  - `opts` - Planning options

  ## Returns
  - `{:ok, solution}` - Successfully planned temporal solution
  - `{:error, reason}` - Failed to plan
  """
  @spec plan(domain(), state(), [goal()], keyword()) :: 
    {:ok, solution()} | {:error, error_reason()}
  def plan(domain, state, goals, opts \\ []) do
    # Placeholder implementation - will be migrated from aria_temporal_planner
    Logger.info("Temporal planner called with #{length(goals)} goals")
    
    # For now, delegate to STN solver for temporal constraints
    case extract_temporal_constraints(goals) do
      [] ->
        # No temporal constraints, use regular planning
        AriaSolver.Engine.plan(domain, state, goals)
      temporal_constraints ->
        # Build STN and solve
        stn = build_stn_from_constraints(temporal_constraints)
        case AriaSolver.STN.solve_stn(stn, opts) do
          {:ok, solved_stn} ->
            {:ok, %{
              status: :success,
              solver: :temporal_planner,
              stn: solved_stn,
              goals: goals,
              metadata: %{planning_time_ms: 0}
            }}
          {:error, reason} ->
            {:error, reason}
        end
    end
  end

  # Extract temporal constraints from goals
  defp extract_temporal_constraints(goals) do
    Enum.filter(goals, fn
      {predicate, _subject, _value} when predicate in ["before", "after", "during", "overlaps"] -> true
      _ -> false
    end)
  end

  # Build STN from temporal constraints
  defp build_stn_from_constraints(constraints) do
    # Simplified STN construction
    time_points = constraints
    |> Enum.flat_map(fn {_predicate, subject, value} -> [subject, value] end)
    |> Enum.uniq()
    |> MapSet.new()

    stn_constraints = constraints
    |> Enum.map(fn
      {"before", subject, value} -> {{subject, value}, {1, 1000}}
      {"after", subject, value} -> {{value, subject}, {1, 1000}}
      {"during", subject, value} -> {{subject, value}, {0, 0}}
      {"overlaps", subject, value} -> {{subject, value}, {-10, 10}}
      _ -> nil
    end)
    |> Enum.reject(&is_nil/1)
    |> Map.new()

    %{
      time_points: time_points,
      constraints: stn_constraints,
      consistent: nil,
      metadata: %{}
    }
  end
end
