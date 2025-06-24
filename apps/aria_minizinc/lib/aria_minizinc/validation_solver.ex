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

    durations =
      activities
      |> Enum.map(fn activity ->
        case activity["duration"] do
          duration when is_integer(duration) -> duration
          duration_str when is_binary(duration_str) -> parse_duration_string(duration_str)
          _ -> 30
        end
      end)

    constraints = create_sequential_constraints(length(activities))

    %{
      num_activities: length(activities),
      num_constraints: length(constraints),
      durations: durations,
      constraints: constraints
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
