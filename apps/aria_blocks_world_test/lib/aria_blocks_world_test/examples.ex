# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaBlocksWorldTest.Examples do
  @moduledoc """
  Example problems for the blocks world domain.

  This module provides predefined test cases based on the GTpyhop blocks_gtn
  domain examples, including the famous Sussman anomaly and other classic
  blocks world problems.
  """

  alias AriaBlocksWorldTest.{Domain, State}

  @doc """
  Run a predefined example problem.

  ## Parameters

  - `example_name` - Name of the example to run

  ## Returns

  - `{:ok, result}` - Success with example results
  - `{:error, reason}` - Failure with error description
  """
  @spec run(atom()) :: {:ok, map()} | {:error, atom()}
  def run(example_name) do
    case example_name do
      :sussman_anomaly -> run_sussman_anomaly()
      :simple_pickup -> run_simple_pickup()
      :simple_stack -> run_simple_stack()
      :complex_multiblock -> run_complex_multiblock()
      _ -> {:error, :unknown_example}
    end
  end

  @doc """
  List all available example problems.

  ## Returns

  - List of available example names
  """
  @spec list_all() :: [atom()]
  def list_all do
    [:sussman_anomaly, :simple_pickup, :simple_stack, :complex_multiblock]
  end

  # Example implementations

  @doc """
  Run the famous Sussman anomaly problem.

  Initial state: A on C, B on table, C on table, A and B clear
  Goal: A on B, B on C

  This is a classic planning problem that demonstrates the need for
  subgoal interaction and non-linear planning.
  """
  @spec run_sussman_anomaly() :: {:ok, map()} | {:error, atom()}
  def run_sussman_anomaly do
    # Create initial state
    initial_state = create_sussman_initial_state()

    # Define goals using R25W1398085 format
    goals = [
      {"pos", "a", "b"},
      {"pos", "b", "c"}
    ]

    # Setup domain and solve
    domain = Domain.create()

    case AriaEngineCore.run_lazy(domain, initial_state, goals) do
      {:ok, {final_state, solution_tree}} ->
        {:ok, %{
          name: "Sussman Anomaly",
          initial_state: initial_state,
          goals: goals,
          final_state: final_state,
          solution_tree: solution_tree,
          description: "Classic subgoal interaction problem: A on B, B on C"
        }}
      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Run a simple pickup and putdown test.

  Initial state: A on table, clear
  Goal: A in hand
  """
  @spec run_simple_pickup() :: {:ok, map()} | {:error, atom()}
  def run_simple_pickup do
    # Create initial state
    initial_state = State.create(%{
      pos: %{"a" => "table"},
      clear: %{"a" => true},
      holding: %{"hand" => false}
    })
    |> setup_entities()

    # Define goal
    goals = [{"pos", "a", "hand"}]

    # Setup domain and solve
    domain = Domain.create()

    case AriaEngineCore.run_lazy(domain, initial_state, goals) do
      {:ok, {final_state, solution_tree}} ->
        {:ok, %{
          name: "Simple Pickup",
          initial_state: initial_state,
          goals: goals,
          final_state: final_state,
          solution_tree: solution_tree,
          description: "Basic pickup operation test"
        }}
      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Run a simple stacking test.

  Initial state: A and B on table, both clear
  Goal: A on B
  """
  @spec run_simple_stack() :: {:ok, map()} | {:error, atom()}
  def run_simple_stack do
    # Create initial state
    initial_state = State.create(%{
      pos: %{"a" => "table", "b" => "table"},
      clear: %{"a" => true, "b" => true},
      holding: %{"hand" => false}
    })
    |> setup_entities()

    # Define goal
    goals = [{"pos", "a", "b"}]

    # Setup domain and solve
    domain = Domain.create()

    case AriaEngineCore.run_lazy(domain, initial_state, goals) do
      {:ok, {final_state, solution_tree}} ->
        {:ok, %{
          name: "Simple Stack",
          initial_state: initial_state,
          goals: goals,
          final_state: final_state,
          solution_tree: solution_tree,
          description: "Basic stacking operation: A on B"
        }}
      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Run a complex multi-block rearrangement.

  Initial state: A on B on C on table
  Goal: C on B on A on table (reverse the stack)
  """
  @spec run_complex_multiblock() :: {:ok, map()} | {:error, atom()}
  def run_complex_multiblock do
    # Create initial state: A on B on C on table
    initial_state = State.create(%{
      pos: %{"a" => "b", "b" => "c", "c" => "table"},
      clear: %{"a" => true, "b" => false, "c" => false},
      holding: %{"hand" => false}
    })
    |> setup_entities()

    # Define goals: reverse the stack
    goals = [
      {"pos", "c", "b"},
      {"pos", "b", "a"},
      {"pos", "a", "table"}
    ]

    # Setup domain and solve
    domain = Domain.create()

    case AriaEngineCore.run_lazy(domain, initial_state, goals) do
      {:ok, {final_state, solution_tree}} ->
        {:ok, %{
          name: "Complex Multiblock",
          initial_state: initial_state,
          goals: goals,
          final_state: final_state,
          solution_tree: solution_tree,
          description: "Complex rearrangement: reverse a 3-block stack"
        }}
      {:error, reason} ->
        {:error, reason}
    end
  end

  # Helper functions

  defp create_sussman_initial_state do
    State.create(%{
      pos: %{"a" => "c", "b" => "table", "c" => "table"},
      clear: %{"a" => true, "b" => true, "c" => false},
      holding: %{"hand" => false}
    })
    |> setup_entities()
  end

  defp setup_entities(state) do
    # Setup basic entities required by the domain
    state
    |> AriaState.RelationalState.set_fact("type", "hand", "agent")
    |> AriaState.RelationalState.set_fact("capabilities", "hand", [:manipulation])
    |> AriaState.RelationalState.set_fact("status", "hand", "available")
    |> AriaState.RelationalState.set_fact("type", "table", "surface")
    |> AriaState.RelationalState.set_fact("capabilities", "table", [:support])
    |> AriaState.RelationalState.set_fact("status", "table", "available")
  end
end
