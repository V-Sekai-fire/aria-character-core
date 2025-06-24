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

  alias AriaMiniZinc.{Executor, Solver, ProblemGenerator, ValidationSolver}

  @doc """
  Solve a constraint satisfaction problem.

  ## Parameters
  - `problem_data` - Problem data from ProblemGenerator or custom format
  - `options` - Solver options (timeout, solver type, etc.)

  ## Returns
  - `{:ok, solution}` - Successfully solved problem
  - `{:error, reason}` - Failed to solve problem
  """
  def solve(problem_data, options \\ %{}) do
    Solver.solve(problem_data, options)
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
  Check if MiniZinc solver is available on the system.

  ## Returns
  - `{:ok, version}` - Solver is available
  - `{:error, reason}` - Solver not available
  """
  def check_availability do
    Solver.check_availability()
  end

  @doc """
  Get list of available solvers.

  ## Returns
  List of available solver names
  """
  def available_solvers do
    Solver.available_solvers()
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
  Validate a MiniZinc model for syntax errors.

  ## Parameters
  - `model` - MiniZinc model string

  ## Returns
  - `:ok` - Model is valid
  - `{:error, reason}` - Model has syntax errors
  """
  def validate_model(model) do
    Solver.validate_model(model)
  end
end
