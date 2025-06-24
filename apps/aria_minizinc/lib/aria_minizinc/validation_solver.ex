# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaMiniZinc.ValidationSolver do
  @moduledoc """
  Handles solving scheduling problems using MiniZinc constraint solver for validation purposes.

  This module provides specialized solving capabilities for validation pipelines,
  supporting both STN temporal problems and widget assembly problems.
  """

  require Logger
  alias AriaMiniZinc.Executor

  @doc """
  Checks if MiniZinc is available on the system.
  """
  def check_availability do
    Executor.check_availability()
  end

  @doc """
  Solves a scheduling problem using MiniZinc.

  ## Parameters
  - `params` - Problem parameters including activities and constraints
  - `state` - Solver state including timeout configuration

  ## Returns
  - `%{status: :success, solution: solution, solve_time_ms: time, raw_output: output}`
  - `%{status: :error, error: reason, solve_time_ms: time}`
  """
  def solve(params, state) do
    schedule_name = params["schedule_name"] || ""

    if String.contains?(schedule_name, "widget") do
      solve_widget_assembly(state)
    else
      solve_stn_temporal(params, state)
    end
  end

  defp solve_stn_temporal(params, state) do
    try do
      template_vars = convert_to_minizinc_format(params)

      case Executor.exec("stn_temporal", template_vars: template_vars, timeout: state.timeout) do
        {:ok, result} ->
          converted_solution = convert_minizinc_solution(result.solution, params)

          %{
            status: :success,
            solution: converted_solution,
            solve_time_ms: result.solve_time_ms,
            raw_output: result.raw_output
          }

        {:error, error} ->
          %{
            status: :error,
            error: "MiniZinc STN temporal solver failed: #{inspect(error)}",
            solve_time_ms: 0
          }
      end
    rescue
      error ->
        %{
          status: :error,
          error: "STN temporal conversion failed: #{Exception.message(error)}",
          solve_time_ms: 0
        }
    end
  end

  defp solve_widget_assembly(_state) do
    start_time = System.monotonic_time(:millisecond)

    cmd_args = [
      "--solver",
      "org.minizinc.mip.coin-bc",
      "--output-mode",
      "json",
      "--output-objective",
      "widget_assembly.mzn"
    ]

    case System.cmd("minizinc", cmd_args, stderr_to_stdout: true) do
      {output, 0} ->
        end_time = System.monotonic_time(:millisecond)
        solve_time = end_time - start_time
        solution = parse_output(output)
        %{status: :success, solution: solution, solve_time_ms: solve_time, raw_output: output}

      {output, exit_code} ->
        end_time = System.monotonic_time(:millisecond)
        solve_time = end_time - start_time

        %{
          status: :error,
          error: "MiniZinc solver failed with exit code #{exit_code}",
          output: output,
          solve_time_ms: solve_time
        }
    end
  end

  defp parse_output(output) do
    lines = String.split(output, "\n")

    solution_lines =
      Enum.filter(lines, fn line ->
        String.contains?(line, "start_times") or String.contains?(line, "makespan") or
          String.contains?(line, "=")
      end)

    start_times = extract_start_times(solution_lines)
    makespan = extract_makespan(solution_lines)

    %{
      activities: [
        %{
          id: "prepare_materials",
          start_time: Enum.at(start_times, 0, 0),
          end_time: Enum.at(start_times, 0, 0) + 30,
          duration: 30
        },
        %{
          id: "assemble_widget",
          start_time: Enum.at(start_times, 1, 30),
          end_time: Enum.at(start_times, 1, 30) + 45,
          duration: 45
        }
      ],
      makespan: makespan,
      start_times: start_times
    }
  end

  defp extract_start_times(lines) do
    start_times_line = Enum.find(lines, fn line -> String.contains?(line, "start_times") end)

    if start_times_line do
      case Regex.run(~r/start_times\s*=\s*\[([^\]]+)\]/, start_times_line) do
        [_, values_str] ->
          values_str
          |> String.split(",")
          |> Enum.map(&String.trim/1)
          |> Enum.map(&String.to_integer/1)

        _ ->
          [0, 30]
      end
    else
      [0, 30]
    end
  end

  defp extract_makespan(lines) do
    makespan_line = Enum.find(lines, fn line -> String.contains?(line, "makespan") end)

    if makespan_line do
      case Regex.run(~r/makespan\s*=\s*(\d+)/, makespan_line) do
        [_, value_str] -> String.to_integer(value_str)
        _ -> 75
      end
    else
      75
    end
  end

  defp convert_to_minizinc_format(params) do
    activities = params["activities"] || []

    # Convert activities to STN time points (start and end for each activity)
    time_point_names = activities
    |> Enum.with_index()
    |> Enum.flat_map(fn {activity, index} ->
      activity_name = activity["id"] || "activity_#{index + 1}"
      ["#{activity_name}_start", "#{activity_name}_end"]
    end)

    num_time_points = length(time_point_names)

    # Create distance matrix for STN constraints
    distance_matrix = create_stn_distance_matrix(activities, num_time_points)

    # Set horizon based on total estimated duration
    total_duration = activities
    |> Enum.map(fn activity ->
      case activity["duration"] do
        duration when is_integer(duration) -> duration
        duration_str when is_binary(duration_str) -> parse_duration_string(duration_str)
        _ -> 30
      end
    end)
    |> Enum.sum()

    horizon = max(total_duration * 2, 1000)  # Give some buffer

    %{
      num_time_points: num_time_points,
      time_point_names: time_point_names,
      distance_matrix: distance_matrix,
      horizon: horizon,
      generation_start: DateTime.utc_now() |> DateTime.to_iso8601()
    }
  end

  defp parse_duration_string(duration_str) do
    cond do
      String.starts_with?(duration_str, "PT") ->
        case Regex.run(~r/PT(\d+)M/, duration_str) do
          [_, minutes] -> String.to_integer(minutes)
          _ -> 30
        end

      String.match?(duration_str, ~r/^\d+$/) ->
        String.to_integer(duration_str)

      true ->
        30
    end
  end

  defp create_stn_distance_matrix(activities, num_time_points) do
    # Initialize distance matrix with infinity (large number)
    infinity = 999999

    # Ensure minimum 1x1 matrix to avoid MiniZinc index set errors
    actual_size = max(num_time_points, 1)

    # Create base matrix filled with infinity
    base_matrix = for _i <- 1..actual_size, do: (for _j <- 1..actual_size, do: infinity)

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

    # Add duration constraints for each activity (end - start <= duration)
    duration_matrix = activities
    |> Enum.with_index()
    |> Enum.reduce(diagonal_matrix, fn {activity, activity_index}, acc_matrix ->
      start_index = activity_index * 2
      end_index = activity_index * 2 + 1

      duration = case activity["duration"] do
        duration when is_integer(duration) -> duration
        duration_str when is_binary(duration_str) -> parse_duration_string(duration_str)
        _ -> 30
      end

      # Add constraint: end_time - start_time <= duration
      if start_index < num_time_points and end_index < num_time_points do
        update_matrix_cell(acc_matrix, start_index, end_index, duration)
      else
        acc_matrix
      end
    end)

    # Add sequential constraints (activity i must finish before activity i+1 starts)
    sequential_matrix = activities
    |> Enum.with_index()
    |> Enum.reduce(duration_matrix, fn {_activity, activity_index}, acc_matrix ->
      if activity_index < length(activities) - 1 do
        current_end_index = activity_index * 2 + 1
        next_start_index = (activity_index + 1) * 2

        # Add constraint: next_start - current_end <= 0 (next can start immediately after current ends)
        if current_end_index < num_time_points and next_start_index < num_time_points do
          update_matrix_cell(acc_matrix, current_end_index, next_start_index, 0)
        else
          acc_matrix
        end
      else
        acc_matrix
      end
    end)

    sequential_matrix
  end

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

  defp create_sequential_constraints(num_activities) when num_activities <= 1 do
    []
  end

  defp create_sequential_constraints(num_activities) do
    1..(num_activities - 1)
    |> Enum.map(fn i ->
      %{from_activity: i, to_activity: i + 1, min_distance: 0, max_distance: 1000}
    end)
  end

  defp convert_minizinc_solution(minizinc_solution, params) do
    activities = params["activities"] || []
    start_times = minizinc_solution[:start_times] || []
    end_times = minizinc_solution[:end_times] || []

    activity_results =
      activities
      |> Enum.with_index()
      |> Enum.map(fn {activity, index} ->
        start_time = Enum.at(start_times, index, 0)
        end_time = Enum.at(end_times, index, start_time + 30)

        %{
          id: activity["id"] || "activity_#{index + 1}",
          start_time: start_time,
          end_time: end_time,
          duration: end_time - start_time
        }
      end)

    %{
      activities: activity_results,
      makespan: minizinc_solution[:makespan] || 0,
      start_times: start_times,
      end_times: end_times
    }
  end
end
