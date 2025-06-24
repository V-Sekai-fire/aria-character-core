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
  Generate and solve a MiniZinc problem from planning parameters.

  ## Parameters
  - `domain` - The planning domain
  - `state` - Current state
  - `goals` - List of goals in {subject, predicate, value} format
  - `options` - Planning options and constraints

  ## Returns
  - `{:ok, result}` - Successfully solved problem with solution
  - `{:error, reason}` - Failed to generate or solve problem
  """
  @spec solve_problem(domain(), state(), [goal()], options()) ::
          {:ok, map()} | {:error, String.t()}
  def solve_problem(domain, state, goals, options \\ %{}) do
    with {:ok, problem_data} <- generate_problem(domain, state, goals, options),
         {:ok, result} <- AriaMiniZinc.Solver.solve(problem_data, prepare_solver_options(options, problem_data)) do
      {:ok, result}
    else
      {:error, reason} -> {:error, reason}
    end
  end

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

  # Prepare solver options from planning options and problem data
  defp prepare_solver_options(options, problem_data) do
    # Extract variable count based on problem type
    variable_count = case Map.get(problem_data, :type) do
      :goal_solving -> Map.get(problem_data, :variable_count, 0)
      :stn -> Map.get(problem_data, :num_time_points, 0)
      _ -> 0
    end

    %{
      solver_type: Map.get(options, :solver_type, :production),
      timeout: Map.get(options, :timeout, 30_000),
      solver: Map.get(options, :solver, "org.minizinc.mip.coin-bc"),
      variable_count: variable_count,
      horizon: Map.get(options, :horizon, 1000)
    }
  end
end
