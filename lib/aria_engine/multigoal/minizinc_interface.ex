# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngine.Multigoal.MiniZincInterface do
  @moduledoc """
  MiniZinc constraint solver interface for multigoal optimization.

  This module provides the interface to MiniZinc constraint programming
  system for solving multigoal optimization problems. It handles solver
  execution, result parsing, and graceful error handling.

  ## Solver Preference

  Uses or-tools as the preferred solver (MiniZinc 2024 contest winner),
  with fallback to gecode and chuffed if or-tools is unavailable.

  ## Usage

      iex> state = State.new()
      iex> goals = [{"location", "robot", "station_1"}]
      iex> AriaEngine.Multigoal.MiniZincInterface.solve_spatial(state, goals)
      {:ok, %{goals: [...], total_actions: 12, ...}}

  Related: ADR-126 - MiniZinc Multigoal Optimization with Fallback
  """

  require Logger
  alias State

  @type goal :: {State.subject(), State.predicate(), State.fact_value()}
  @type solution :: %{
    goals: [goal()],
    total_actions: non_neg_integer(),
    total_distance: number(),
    completion_time: number(),
    parallel_opportunities: non_neg_integer()
  }

  # Default configuration
  @default_timeout 5_000
  @default_solvers ["or-tools", "gecode", "chuffed"]

  @doc """
  Solve general multigoal optimization problem using MiniZinc.

  Generates and solves a general-purpose constraint model for optimizing
  goal achievement sequences. Uses multi-objective optimization to balance
  completion time, resource conflicts, and parallel opportunities.
  """
  @spec solve_general(State.t(), [goal()], keyword()) ::
    {:ok, solution()} | {:error, term()}
  def solve_general(state, goals, opts \\ []) do
    try do
      with {:ok, model} <- AriaEngine.Multigoal.ConstraintBuilder.build_general_model(state, goals),
           {:ok, solution} <- execute_minizinc(model, opts) do
        {:ok, parse_solution(solution, goals)}
      else
        {:error, reason} -> {:error, reason}
      end
    rescue
      error ->
        Logger.warning("MiniZinc general solving failed: #{inspect(error)}")
        {:error, {:minizinc_execution_failed, error}}
    end
  end

  # Execute MiniZinc solver with the given model
  defp execute_minizinc(model, opts) do
    timeout = Keyword.get(opts, :timeout, @default_timeout)
    solvers = Keyword.get(opts, :solvers, @default_solvers)

    case check_minizinc_availability() do
      :ok ->
        run_minizinc_with_solvers(model, solvers, timeout)

      {:error, reason} ->
        Logger.info("MiniZinc not available: #{inspect(reason)}")
        {:error, :minizinc_unavailable}
    end
  end

  # Check if MiniZinc is available on the system
  defp check_minizinc_availability do
    case System.cmd("minizinc", ["--version"], stderr_to_stdout: true) do
      {output, 0} ->
        Logger.debug("MiniZinc available: #{String.trim(output)}")
        :ok

      {_output, _exit_code} ->
        {:error, :minizinc_not_found}
    end
  rescue
    error ->
      {:error, {:minizinc_check_failed, error}}
  end

  # Try MiniZinc execution with preferred solver order
  defp run_minizinc_with_solvers(model, solvers, timeout) do
    Enum.reduce_while(solvers, {:error, :no_solvers_available}, fn solver, _acc ->
      case run_minizinc_with_solver(model, solver, timeout) do
        {:ok, solution} ->
          Logger.debug("MiniZinc solved successfully with #{solver}")
          {:halt, {:ok, solution}}

        {:error, reason} ->
          Logger.debug("MiniZinc solver #{solver} failed: #{inspect(reason)}")
          {:cont, {:error, {:all_solvers_failed, reason}}}
      end
    end)
  end

  # Execute MiniZinc with a specific solver
  defp run_minizinc_with_solver(model, solver, timeout) do
    # Write model to temporary file
    with {:ok, model_file} <- write_temp_model(model),
         {:ok, output} <- execute_minizinc_command(model_file, solver, timeout) do
      File.rm(model_file)
      parse_minizinc_output(output)
    else
      {:error, reason} -> {:error, reason}
    end
  end

  # Write MiniZinc model to temporary file
  defp write_temp_model(model) do
    temp_file = Path.join(System.tmp_dir!(), "multigoal_#{:rand.uniform(1000000)}.mzn")

    case File.write(temp_file, model) do
      :ok -> {:ok, temp_file}
      {:error, reason} -> {:error, {:temp_file_write_failed, reason}}
    end
  end

  # Execute MiniZinc command with timeout
  defp execute_minizinc_command(model_file, solver, timeout) do
    args = ["--solver", solver, "--output-mode", "json", model_file]

    case System.cmd("minizinc", args, stderr_to_stdout: true, timeout: timeout) do
      {output, 0} ->
        {:ok, output}

      {output, exit_code} ->
        {:error, {:minizinc_execution_failed, exit_code, output}}
    end
  rescue
    error ->
      {:error, {:minizinc_command_failed, error}}
  end

  # Parse MiniZinc JSON output
  defp parse_minizinc_output(output) do
    try do
      case Jason.decode(output) do
        {:ok, json} ->
          extract_solution_from_json(json)

        {:error, reason} ->
          Logger.debug("JSON parsing failed: #{inspect(reason)}, trying text parsing")
          # Try parsing as plain text output
          parse_text_output(output)
      end
    rescue
      error ->
        {:error, {:output_parsing_failed, error}}
    end
  end

  # Extract solution from JSON output
  defp extract_solution_from_json(json) when is_map(json) do
    case json do
      %{"status" => "SATISFIED"} ->
        solution = %{
          goal_order: Map.get(json, "goal_order", []),
          total_actions: Map.get(json, "total_actions", 0),
          total_distance: Map.get(json, "total_distance", 0.0),
          completion_time: Map.get(json, "completion_time", 0.0),
          parallel_opportunities: Map.get(json, "parallel_opportunities", 0)
        }
        {:ok, solution}

      %{"status" => "UNSATISFIABLE"} ->
        {:error, :constraint_unsatisfiable}

      %{"status" => "UNKNOWN"} ->
        {:error, :solver_timeout}

      _ ->
        {:error, {:unknown_status, json}}
    end
  end

  defp extract_solution_from_json(_), do: {:error, :invalid_json_format}

  # Parse plain text output (fallback)
  defp parse_text_output(output) do
    lines = String.split(output, "\n", trim: true)

    case Enum.find(lines, &String.contains?(&1, "=====")) do
      nil ->
        # No solution found
        if String.contains?(output, "UNSATISFIABLE") do
          {:error, :constraint_unsatisfiable}
        else
          {:error, :no_solution_found}
        end

      _solution_line ->
        # Extract basic solution (simplified parsing)
        {:ok, %{
          goal_order: [],
          total_actions: 0,
          total_distance: 0.0,
          completion_time: 0.0,
          parallel_opportunities: 0
        }}
    end
  end

  # Parse solution and map back to goals
  defp parse_solution(solution, original_goals) do
    goal_order = Map.get(solution, :goal_order, [])

    # Map goal indices back to actual goals
    ordered_goals = if length(goal_order) > 0 do
      goal_order
      |> Enum.map(fn index -> Enum.at(original_goals, index - 1) end)
      |> Enum.filter(& &1)
    else
      original_goals
    end

    %{
      goals: ordered_goals,
      total_actions: Map.get(solution, :total_actions, length(original_goals) * 4),
      total_distance: Map.get(solution, :total_distance, length(original_goals) * 3.0),
      completion_time: Map.get(solution, :completion_time, length(original_goals) * 10.0),
      parallel_opportunities: Map.get(solution, :parallel_opportunities, 0)
    }
  end

  @doc """
  Check if MiniZinc is available and working.

  Returns `:ok` if MiniZinc is available, `{:error, reason}` otherwise.
  Useful for health checks and system validation.
  """
  @spec health_check() :: :ok | {:error, term()}
  def health_check do
    case check_minizinc_availability() do
      :ok ->
        # Test with a simple model
        test_model = """
        var 1..10: x;
        solve satisfy;
        output ["x = \\(x)"];
        """

        case execute_minizinc(test_model, timeout: 1000) do
          {:ok, _} -> :ok
          {:error, reason} -> {:error, {:health_check_failed, reason}}
        end

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Get available MiniZinc solvers on the system.

  Returns a list of available solver names.
  """
  @spec get_available_solvers() :: [String.t()]
  def get_available_solvers do
    case System.cmd("minizinc", ["--solvers"], stderr_to_stdout: true) do
      {output, 0} ->
        output
        |> String.split("\n", trim: true)
        |> Enum.filter(&String.contains?(&1, ":"))
        |> Enum.map(fn line ->
          line
          |> String.split(":")
          |> List.first()
          |> String.trim()
        end)
        |> Enum.filter(& &1 != "")

      {_output, _exit_code} ->
        []
    end
  rescue
    _error -> []
  end
end
