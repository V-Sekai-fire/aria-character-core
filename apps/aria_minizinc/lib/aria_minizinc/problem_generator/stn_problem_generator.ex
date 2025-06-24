# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaMiniZinc.ProblemGenerator.STNProblemGenerator do
  @moduledoc """
  Generates MiniZinc Simple Temporal Network (STN) problems from planning requests.

  This module handles the generation of STN constraint satisfaction problems
  for temporal planning scenarios.
  """

  require Logger
  alias AriaMiniZinc.ProblemGenerator.Common

  @simple_temporal_network_template "stn_temporal.mzn.eex"

  # STN-specific type definitions
  @type stn_time_point :: non_neg_integer()  # Time point index

  @type stn_distance_constraint :: %{
    from_point: non_neg_integer(),
    to_point: non_neg_integer(),
    distance: integer()  # Maximum distance: to_point - from_point ≤ distance
  }

  @type stn_problem_data :: %{
    num_time_points: non_neg_integer(),
    time_point_names: [String.t()],  # Human-readable names for time points
    distance_matrix: [[integer()]],  # Full distance constraint matrix
    horizon: non_neg_integer()       # Maximum time value
  }

  @doc """
  Generate an STN MiniZinc problem.

  ## Parameters
  - `domain` - The planning domain
  - `state` - Current state
  - `goals` - List of goals in {subject, predicate, value} format
  - `options` - Planning options and constraints
  - `generation_start` - ISO8601 timestamp when generation started

  ## Returns
  - `{:ok, problem_data}` - Successfully generated problem
  - `{:error, reason}` - Failed to generate problem
  """
  @spec generate(Common.domain(), Common.state(), [Common.goal()], Common.options(), Common.iso8601_datetime()) ::
          {:ok, map()} | {:error, String.t()}
  def generate(domain, state, goals, options, generation_start) do
    try do
      Logger.debug("Generating STN MiniZinc problem for #{length(goals)} goals")

      # Extract variables and transform to STN format
      variables = Common.extract_variables(goals, state)
      constraints = Common.generate_constraints(domain, state, goals, options)

      # Transform to STN time points and distance matrix
      time_points = extract_stn_time_points(variables, options)
      distance_matrix = generate_stn_distance_matrix(time_points, constraints, options)
      horizon = Map.get(options, :horizon, 1000)

      # Prepare template variables
      template_vars = %{
        num_time_points: length(time_points),
        time_point_names: time_points,
        distance_matrix: distance_matrix,
        horizon: horizon,
        generation_start: generation_start
      }

      # Render the MiniZinc model using template
      model = Common.render_template(@simple_temporal_network_template, template_vars)

      # Calculate generation end time and duration
      generation_end = Timex.now() |> Timex.format!("{ISO:Extended}")
      generation_duration = Common.calculate_duration(generation_start, generation_end)

      # Calculate variable count to match goal-solving format (3 variables per entity)
      original_variable_count = Common.count_total_variables(variables)

      # Create metadata
      metadata = %{
        goal_count: length(goals),
        variable_count: original_variable_count,  # Use original count for consistency
        constraint_count: length(constraints),
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
        num_time_points: length(time_points),
        time_point_names: time_points,
        distance_matrix: distance_matrix,
        horizon: horizon,
        generation_start: generation_start,
        metadata: metadata
      }}
    rescue
      error ->
        Logger.error("Failed to generate STN MiniZinc problem: #{inspect(error)}")
        {:error, "STN problem generation failed: #{Exception.message(error)}"}
    end
  end

  # Extract STN time points from structured variables
  @spec extract_stn_time_points(Common.structured_variables(), Common.options()) :: [String.t()]
  defp extract_stn_time_points(variables, _options) do
    # Convert each entity to time point pairs (start_point, end_point)
    variables.time_vars
    |> Enum.flat_map(fn var ->
      # Extract entity name from variable name (remove "_time" suffix)
      entity_name = String.replace(var.name, "_time", "")

      # Create start and end time points for each entity/activity
      ["#{entity_name}_start", "#{entity_name}_end"]
    end)
  end

  # Generate STN distance constraint matrix
  @spec generate_stn_distance_matrix([String.t()], [Common.constraint()], Common.options()) :: [[integer()]]
  defp generate_stn_distance_matrix(time_points, constraints, options) do
    num_points = length(time_points)
    default_duration = Map.get(options, :default_duration, 30)

    # Handle empty case - return empty matrix
    if num_points == 0 do
      []
    else
      # Initialize distance matrix with infinity (represented as large number)
      infinity = 999999
      base_matrix = for _i <- 1..num_points, do: (for _j <- 1..num_points, do: infinity)

      # Set diagonal to 0 (distance from point to itself)
      diagonal_matrix = base_matrix
      |> Enum.with_index()
      |> Enum.map(fn {row, i} ->
        row
        |> Enum.with_index()
        |> Enum.map(fn {val, j} ->
          if i == j, do: 0, else: val
        end)
      end)

      # Add duration constraints (end_point - start_point ≤ duration)
      duration_matrix = add_duration_constraints(diagonal_matrix, time_points, default_duration)

      # Add precedence constraints from temporal ordering
      precedence_matrix = add_precedence_constraints(duration_matrix, time_points, constraints)

      precedence_matrix
    end
  end

  # Add duration constraints to distance matrix
  defp add_duration_constraints(matrix, time_points, default_duration) do
    # Find start/end point pairs and add duration constraints
    time_points
    |> Enum.with_index()
    |> Enum.reduce(matrix, fn {point_name, point_index}, acc_matrix ->
      if String.ends_with?(point_name, "_start") do
        # Find corresponding end point
        entity_name = String.replace(point_name, "_start", "")
        end_point_name = "#{entity_name}_end"

        case Enum.find_index(time_points, &(&1 == end_point_name)) do
          nil -> acc_matrix  # No corresponding end point found
          end_index ->
            # Add constraint: end_point - start_point ≤ duration
            # Also add: start_point - end_point ≤ -duration (for consistency)
            acc_matrix
            |> update_matrix_cell(point_index, end_index, default_duration)
            |> update_matrix_cell(end_index, point_index, -default_duration)
        end
      else
        acc_matrix
      end
    end)
  end

  # Add precedence constraints to distance matrix
  defp add_precedence_constraints(matrix, time_points, constraints) do
    # Check for temporal ordering constraints
    temporal_constraints = Enum.filter(constraints, fn constraint ->
      Map.get(constraint, :type) == :temporal_ordering
    end)

    if length(temporal_constraints) > 0 do
      # Add sequential precedence constraints between activities
      add_sequential_precedence(matrix, time_points)
    else
      matrix
    end
  end

  # Add sequential precedence constraints (activity A must finish before activity B starts)
  defp add_sequential_precedence(matrix, time_points) do
    # Group time points by entity
    entities = time_points
    |> Enum.map(fn point ->
      cond do
        String.ends_with?(point, "_start") -> String.replace(point, "_start", "")
        String.ends_with?(point, "_end") -> String.replace(point, "_end", "")
        true -> point
      end
    end)
    |> Enum.uniq()

    # Add precedence constraints between consecutive entities
    entities
    |> Enum.with_index()
    |> Enum.reduce(matrix, fn {_entity, entity_index}, acc_matrix ->
      if entity_index < length(entities) - 1 do
        # Current entity end point
        current_entity = Enum.at(entities, entity_index)
        next_entity = Enum.at(entities, entity_index + 1)

        current_end_name = "#{current_entity}_end"
        next_start_name = "#{next_entity}_start"

        current_end_index = Enum.find_index(time_points, &(&1 == current_end_name))
        next_start_index = Enum.find_index(time_points, &(&1 == next_start_name))

        if current_end_index && next_start_index do
          # Add constraint: next_start - current_end ≤ 0 (next can start immediately after current ends)
          update_matrix_cell(acc_matrix, current_end_index, next_start_index, 0)
        else
          acc_matrix
        end
      else
        acc_matrix
      end
    end)
  end

  # Helper function to update a cell in the distance matrix
  defp update_matrix_cell(matrix, from_index, to_index, distance) do
    matrix
    |> Enum.with_index()
    |> Enum.map(fn {row, row_index} ->
      if row_index == from_index do
        row
        |> Enum.with_index()
        |> Enum.map(fn {cell, col_index} ->
          if col_index == to_index do
            min(cell, distance)  # Take minimum of existing and new constraint
          else
            cell
          end
        end)
      else
        row
      end
    end)
  end
end
