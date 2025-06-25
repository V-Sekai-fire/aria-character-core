# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaMiniZinc.ProblemGenerator do
  @moduledoc """
  Main coordinator for MiniZinc constraint satisfaction problem generation.

  This module serves as the primary entry point for generating MiniZinc problems
  and delegates to specialized generators based on problem type.
  """

  require Logger
  alias AriaMiniZinc.ProblemGenerator.{Common, GoalProblemGenerator, STNProblemGenerator}

  # Re-export common types for backward compatibility
  @type goal :: Common.goal()
  @type state :: Common.state()
  @type domain :: Common.domain()
  @type options :: Common.options()

  @doc """
  Generate a MiniZinc problem from planning parameters.

  ## Parameters
  - `domain` - The planning domain
  - `state` - Current state
  - `goals` - List of goals in {subject, predicate, value} format
  - `options` - Planning options and constraints

  ## Returns
  - `{:ok, problem_data}` - Successfully generated problem
  - `{:error, reason}` - Failed to generate problem
  """
  @spec generate_problem(domain(), state(), [goal()], options()) ::
          {:ok, map()} | {:error, String.t()}
  def generate_problem(domain, state, goals, options \\ %{}) do
    # Capture generation start time in local timezone ISO 8601 format
    generation_start = Timex.now() |> Timex.format!("{ISO:Extended}")

    try do
      Logger.debug("Generating MiniZinc problem for #{length(goals)} goals")

      # Branch early based on problem type
      problem_type = Map.get(options, :problem_type, :goal_solving)

      case problem_type do
        :stn ->
          # Extract timepoints and distance matrix from options for STN problems
          timepoints = Map.get(options, :timepoints, [])
          distance_matrix = Map.get(options, :distance_matrix, [])
          STNProblemGenerator.generate(timepoints, distance_matrix, options, generation_start)
        _ ->
          GoalProblemGenerator.generate(domain, state, goals, options, generation_start)
      end
    rescue
      error ->
        Logger.error("Failed to generate MiniZinc problem: #{inspect(error)}")
        {:error, "Problem generation failed: #{Exception.message(error)}"}
    end
  end
end
