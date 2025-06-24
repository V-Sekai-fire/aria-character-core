# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaMiniZinc.ProblemGenerator.STNProblemGenerator do
  @moduledoc """
  Generates MiniZinc Simple Temporal Network (STN) problems from timepoints and distance constraints.

  This module handles the generation of STN constraint satisfaction problems
  for temporal planning scenarios using direct timepoint and distance matrix input.
  """

  require Logger
  alias AriaMiniZinc.ProblemGenerator.Common

  @simple_temporal_network_template "stn_temporal.mzn.eex"

  # STN-specific type definitions
  @type stn_time_point :: String.t()  # Time point name

  @type stn_problem_data :: %{
    num_time_points: non_neg_integer(),
    time_point_names: [String.t()],  # Human-readable names for time points
    distance_matrix: [[integer()]],  # Full distance constraint matrix
    horizon: non_neg_integer()       # Maximum time value
  }

  @doc """
  Generate an STN MiniZinc problem from timepoints and distance matrix.

  ## Parameters
  - `timepoints` - List of timepoint names (e.g., ["task_A_start", "task_A_end"])
  - `distance_matrix` - 2D matrix of distance constraints between timepoints
  - `options` - Planning options and constraints
  - `generation_start` - ISO8601 timestamp when generation started

  ## Returns
  - `{:ok, problem_data}` - Successfully generated problem
  - `{:error, reason}` - Failed to generate problem
  """
  @spec generate([String.t()], [[integer()]], Common.options(), Common.iso8601_datetime()) ::
          {:ok, map()} | {:error, String.t()}
  def generate(timepoints, distance_matrix, options, generation_start) do
    try do
      Logger.debug("Generating STN MiniZinc problem for #{length(timepoints)} timepoints")

      # Handle empty timepoints case - return minimal valid STN without MiniZinc call
      if length(timepoints) == 0 do
        return_minimal_stn(options, generation_start)
      else
        # Validate inputs
        with :ok <- validate_inputs(timepoints, distance_matrix) do
          generate_stn_problem(timepoints, distance_matrix, options, generation_start)
        else
          {:error, reason} -> {:error, reason}
        end
      end
    rescue
      error ->
        Logger.error("Failed to generate STN MiniZinc problem: #{inspect(error)}")
        {:error, "STN problem generation failed: #{Exception.message(error)}"}
    end
  end

  # Return minimal valid STN for empty timepoints case
  defp return_minimal_stn(options, generation_start) do
    generation_end = Timex.now() |> Timex.format!("{ISO:Extended}")
    generation_duration = Common.calculate_duration(generation_start, generation_end)

    metadata = %{
      goal_count: 0,
      variable_count: 0,
      constraint_count: 0,
      optimization: :none,
      generation_start: generation_start,
      generation_end: generation_end,
      generation_duration: generation_duration,
      domain: "stn"
    }

    {:ok, %{
      model: "% Empty STN - no timepoints",
      type: :stn,
      num_time_points: 0,
      time_point_names: [],
      distance_matrix: [],
      horizon: Map.get(options, :horizon, 1000),
      generation_start: generation_start,
      metadata: metadata
    }}
  end

  # Validate timepoints and distance matrix inputs
  defp validate_inputs(timepoints, distance_matrix) do
    cond do
      length(timepoints) == 0 ->
        {:error, "Empty timepoints list"}

      length(distance_matrix) != length(timepoints) ->
        {:error, "Distance matrix row count (#{length(distance_matrix)}) doesn't match timepoint count (#{length(timepoints)})"}

      not Enum.all?(distance_matrix, fn row -> length(row) == length(timepoints) end) ->
        {:error, "Distance matrix is not square - all rows must have #{length(timepoints)} columns"}

      true ->
        :ok
    end
  end

  # Generate the actual STN problem
  defp generate_stn_problem(timepoints, distance_matrix, options, generation_start) do
    horizon = Map.get(options, :horizon, 1000)

    # Prepare template variables
    template_vars = %{
      num_time_points: length(timepoints),
      time_point_names: timepoints,
      distance_matrix: distance_matrix,
      horizon: horizon,
      generation_start: generation_start
    }

    # Render the MiniZinc model using template
    model = Common.render_template(@simple_temporal_network_template, template_vars)

    # Calculate generation end time and duration
    generation_end = Timex.now() |> Timex.format!("{ISO:Extended}")
    generation_duration = Common.calculate_duration(generation_start, generation_end)

    # Create metadata
    metadata = %{
      goal_count: 0,  # STNs don't have goals
      variable_count: length(timepoints),  # One variable per timepoint
      constraint_count: count_active_constraints(distance_matrix),
      optimization: Common.determine_optimization_type(options),
      generation_start: generation_start,
      generation_end: generation_end,
      generation_duration: generation_duration,
      domain: "stn"
    }

    # Return data structure with both :model and :type for compatibility
    {:ok, %{
      model: model,
      type: :stn,
      num_time_points: length(timepoints),
      time_point_names: timepoints,
      distance_matrix: distance_matrix,
      horizon: horizon,
      generation_start: generation_start,
      metadata: metadata
    }}
  end

  # Count active constraints in distance matrix (non-infinity values)
  defp count_active_constraints(distance_matrix) do
    infinity = 999999

    distance_matrix
    |> Enum.with_index()
    |> Enum.reduce(0, fn {row, i}, acc ->
      row
      |> Enum.with_index()
      |> Enum.reduce(acc, fn {val, j}, row_acc ->
        cond do
          i == j -> row_acc  # Diagonal elements don't count as constraints
          val == infinity -> row_acc  # Infinity values are not active constraints
          true -> row_acc + 1  # Active constraint
        end
      end)
    end)
  end
end
