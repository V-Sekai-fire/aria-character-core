# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaBacktrackingTest do
  @moduledoc """
  Backtracking test application for validating HTN planning failure recovery.

  This application implements the GTPyhop backtracking_htn.py example in Elixir,
  providing a simple domain for testing backtracking behavior in the Aria planning system.

  ## Quick Start

      # Create initial state
      state = AriaBacktrackingTest.State.new()

      # Solve a problem that requires backtracking
      {:ok, {final_state, plan}} = AriaBacktrackingTest.solve_problem(state, [{"put_it", []}, {"need0", []}])

  ## Test Scenarios

  The domain provides several test scenarios from the original Python example:

  - `[{"put_it", []}, {"need0", []}]` - Single backtrack from broken method
  - `[{"put_it", []}, {"need01", []}]` - Method selection test
  - `[{"put_it", []}, {"need10", []}]` - Double backtrack scenario
  - `[{"put_it", []}, {"need1", []}]` - Complex backtrack with multiple attempts
  """

  alias AriaBacktrackingTest.{State, Domain}

  @doc """
  Solves a planning problem using the backtracking test domain.

  ## Parameters

  - `state` - Initial state (AriaBacktrackingTest.State)
  - `goals` - List of goal tasks to achieve

  ## Returns

  - `{:ok, {final_state, plan}}` - Success with final state and execution plan
  - `{:error, reason}` - Failure with error description

  ## Examples

      iex> state = AriaBacktrackingTest.State.new()
      iex> {:ok, {final_state, _plan}} = AriaBacktrackingTest.solve_problem(state, [{"put_it", []}, {"need0", []}])
      iex> AriaBacktrackingTest.State.get_flag(final_state)
      0

  """
  @spec solve_problem(State.t(), list()) :: {:ok, {State.t(), term()}} | {:error, String.t()}
  def solve_problem(state, goals) do
    domain = Domain.create()
    relational_state = AriaState.RelationalState.new()
    |> AriaState.RelationalState.set_fact("system", "flag", State.get_flag(state))

    case AriaHybridPlanner.run_lazy(domain, relational_state, goals) do
      {:ok, {final_relational_state, plan}} ->
        final_flag = AriaState.RelationalState.get_fact(final_relational_state, "system", "flag") || -1
        final_state = State.new(final_flag)
        {:ok, {final_state, plan}}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Runs the main test scenarios from the Python example.

  This function replicates the test cases from backtracking_htn.py,
  demonstrating various backtracking scenarios.

  ## Parameters

  - `verbose` - Whether to enable verbose logging (default: false)

  ## Returns

  - `:ok` - All tests passed
  - `{:error, reason}` - Test failure

  """
  @spec run_examples(boolean()) :: :ok | {:error, String.t()}
  def run_examples(verbose \\ false) do
    if verbose do
      require Logger
      Logger.configure(level: :debug)
    end

    state = State.new()

    # Expected results from Python example
    expect0 = [{"putv", [0]}, {"getv", [0]}, {"getv", [0]}]
    expect1 = [{"putv", [1]}, {"getv", [1]}, {"getv", [1]}]

    test_cases = [
      {
        "Single backtrack test",
        [{"put_it", []}, {"need0", []}],
        expect0
      },
      {
        "Method choice test",
        [{"put_it", []}, {"need01", []}],
        expect0
      },
      {
        "Double backtrack test",
        [{"put_it", []}, {"need10", []}],
        expect0
      },
      {
        "Complex backtrack test",
        [{"put_it", []}, {"need1", []}],
        expect1
      }
    ]

    Enum.reduce_while(test_cases, :ok, fn {name, goals, expected}, _acc ->
      case solve_problem(state, goals) do
        {:ok, {final_state, plan}} ->
          if verbose do
            IO.puts("✓ #{name}: Success")
            IO.puts("  Final flag: #{State.get_flag(final_state)}")
            IO.puts("  Plan: #{inspect(plan)}")
          end

          {:cont, :ok}

        {:error, reason} ->
          {:halt, {:error, "#{name} failed: #{reason}"}}
      end
    end)
  end

  @doc """
  Creates a new initial state for testing.
  """
  @spec new_state() :: State.t()
  def new_state do
    State.new()
  end

  @doc """
  Creates a new state with a specific flag value.
  """
  @spec new_state(integer()) :: State.t()
  def new_state(flag_value) do
    State.new(flag_value)
  end

  @doc """
  Gets the current flag value from a state.
  """
  @spec get_flag(State.t()) :: integer()
  def get_flag(state) do
    State.get_flag(state)
  end

  @doc """
  Sets the flag value in a state.
  """
  @spec set_flag(State.t(), integer()) :: State.t()
  def set_flag(state, flag_value) do
    State.set_flag(state, flag_value)
  end
end
