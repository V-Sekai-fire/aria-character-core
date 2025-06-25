# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaMiniZinc do
  @moduledoc """
  MiniZinc constraint solver integration for Aria Character Core.

  This application provides a clean interface for solving constraint satisfaction
  problems using MiniZinc, with automatic fallback to pure Elixir solutions
  when MiniZinc is not available.

  ## Main Components

  - `AriaMiniZinc.Executor` - Core MiniZinc execution with Porcelain
  - `AriaMiniZinc.Solver` - High-level solver interface with fallback
  - `AriaMiniZinc.ProblemGenerator` - Convert planning problems to MiniZinc
  - `AriaMiniZinc.STNSolver` - Specialized STN constraint solver

  ## Usage

      # Solve a constraint problem
      {:ok, solution} = AriaMiniZinc.solve(problem_data)

      # Check MiniZinc availability
      {:ok, _version} = AriaMiniZinc.check_availability()

      # Execute MiniZinc template directly
      {:ok, result} = AriaMiniZinc.exec("stn_temporal",
        template_vars: %{num_activities: 3, durations: [10, 20, 15]})
  """

  alias AriaMiniZinc.{Executor, ProblemGenerator, ValidationSolver}

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
  def generate_problem(domain, state, goals, options \\ %{}) do
    ProblemGenerator.generate_problem(domain, state, goals, options)
  end

  @doc """
  Execute a MiniZinc model directly.

  ## Parameters
  - `model_name` - Template name or .mzn file path
  - `options` - Execution options including template_vars

  ## Returns
  - `{:ok, result}` - Successfully executed model
  - `{:error, reason}` - Failed to execute model
  """
  def exec(model_name, options \\ []) do
    Executor.exec(model_name, options)
  end

  @doc """
  Solve a validation problem using MiniZinc for pipeline validation.

  ## Parameters
  - `params` - Problem parameters including activities and constraints
  - `state` - Solver state including timeout configuration

  ## Returns
  - `%{status: :success, solution: solution, solve_time_ms: time, raw_output: output}`
  - `%{status: :error, error: reason, solve_time_ms: time}`
  """
  def solve_validation(params, state \\ %{timeout: 30_000}) do
    ValidationSolver.solve(params, state)
  end

  @doc """
  Multiply an integer by a multiplier using MiniZinc constraint solving.

  ## Parameters
  - `input_value` - Integer to multiply (must be non-zero)
  - `multiplier` - Integer multiplier (must be non-zero, defaults to 3)
  - `options` - Optional execution options including executor override

  ## Returns
  - `{:ok, result}` - Successfully computed multiplication with timing
  - `{:error, reason}` - Failed to compute multiplication

  ## Examples

      # Basic multiplication
      {:ok, result} = AriaMiniZinc.multiply(5, 3)
      result.result  # => 15

      # With default multiplier
      {:ok, result} = AriaMiniZinc.multiply(7)
      result.result  # => 21

      # With mock executor for testing
      {:ok, result} = AriaMiniZinc.multiply(4, 2, executor: MockExecutor)
  """
  def multiply(input_value, multiplier_or_options \\ 3, options \\ [])

  def multiply(input_value, multiplier_or_options, options) when is_integer(multiplier_or_options) do
    # Called with explicit multiplier
    multiplier = multiplier_or_options
    with :ok <- validate_multiply_inputs(input_value, multiplier),
         {:ok, result} <- execute_multiply(input_value, multiplier, options) do
      {:ok, result}
    else
      {:error, reason} -> {:error, reason}
    end
  end

  def multiply(input_value, multiplier_or_options, _options) when is_list(multiplier_or_options) do
    # Called with options as second parameter, use default multiplier
    multiplier = 3
    options = multiplier_or_options
    with :ok <- validate_multiply_inputs(input_value, multiplier),
         {:ok, result} <- execute_multiply(input_value, multiplier, options) do
      {:ok, result}
    else
      {:error, reason} -> {:error, reason}
    end
  end

  def multiply(input_value, multiplier_or_options, _options) do
    # Catch-all for invalid types - validate inputs to get proper error message
    case validate_multiply_inputs(input_value, multiplier_or_options) do
      :ok -> {:error, "Unexpected input type"}
      {:error, reason} -> {:error, reason}
    end
  end

  # Validate multiplication inputs
  defp validate_multiply_inputs(input_value, multiplier) do
    cond do
      not is_integer(input_value) ->
        {:error, "input_value must be an integer"}
      input_value == 0 ->
        {:error, "input_value must be non-zero"}
      not is_integer(multiplier) ->
        {:error, "multiplier must be an integer"}
      multiplier == 0 ->
        {:error, "multiplier must be non-zero"}
      true ->
        :ok
    end
  end

  # Execute multiplication via MiniZinc
  defp execute_multiply(input_value, multiplier, options) do
    executor = Keyword.get(options, :executor, Executor)

    template_vars = %{
      input_value: input_value,
      multiplier: multiplier
    }

    exec_options = [
      template_vars: template_vars,
      timeout: Keyword.get(options, :timeout, 30_000)
    ]

    case executor.exec("multiply", exec_options) do
      {:ok, %{status: :success, solution: solution} = result} ->
        {:ok, %{
          result: extract_result_value(solution),
          solving_start: result[:solving_start] || generate_timestamp(),
          solving_end: result[:solving_end] || generate_timestamp(),
          duration: result[:duration] || "PT0.001S"
        }}
      {:ok, %{status: :error} = result} ->
        {:error, "MiniZinc execution failed: #{inspect(result)}"}
      {:error, reason} ->
        {:error, "Executor failed: #{inspect(reason)}"}
    end
  end

  # Extract result value from MiniZinc solution
  defp extract_result_value(solution) when is_map(solution) do
    Map.get(solution, :result) || Map.get(solution, "result")
  end
  defp extract_result_value(solution) when is_integer(solution) do
    solution
  end
  defp extract_result_value(_), do: nil

  # Generate ISO8601 timestamp
  defp generate_timestamp do
    DateTime.utc_now() |> DateTime.to_iso8601()
  end
end
