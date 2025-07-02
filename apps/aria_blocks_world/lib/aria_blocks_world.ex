# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaBlocksWorld do
  @moduledoc """
  AriaBlocksWorld provides a blocks world planning domain implementation using AriaEngineCore.

  This module implements the classic blocks world planning domain based on the GTpyhop
  blocks_gtn example, which uses the near-optimal planning algorithm described in:

  N. Gupta and D. S. Nau. On the complexity of blocks-world planning.
  Artificial Intelligence 56(2-3):223–254, 1992.

  ## Usage

      # Create initial state
      state = AriaBlocksWorld.create_state(%{
        pos: %{"a" => "b", "b" => "table", "c" => "table"},
        clear: %{"a" => true, "b" => false, "c" => true},
        holding: %{"hand" => false}
      })

      # Define goal
      goal = AriaBlocksWorld.create_multigoal(%{
        pos: %{"c" => "b", "b" => "a", "a" => "table"}
      })

      # Solve the problem
      {:ok, {final_state, solution_tree}} = AriaBlocksWorld.solve_problem(state, [goal])

  ## Example Problems

      # Run the famous Sussman anomaly
      {:ok, result} = AriaBlocksWorld.run_example(:sussman_anomaly)

      # Run simple pickup/putdown tests
      {:ok, result} = AriaBlocksWorld.run_example(:simple_pickup)

  ## State Representation

  The blocks world uses three main predicates:
  - `{:pos, block}` - Position of block (table, hand, or another block)
  - `{:clear, block}` - Whether block is clear (true/false)
  - `{:holding, :hand}` - What the hand is holding (block name or false)
  """

  alias AriaBlocksWorld.{Domain, State, Examples}

  @type block :: String.t()
  @type position :: :table | :hand | block()
  @type state_data :: %{
    pos: %{block() => position()},
    clear: %{block() => boolean()},
    holding: %{:hand => block() | false}
  }

  @doc """
  Create a blocks world state from the given data.

  ## Parameters

  - `data` - Map containing pos, clear, and holding information

  ## Returns

  - `AriaEngineCore.State.t()` - Initialized state

  ## Example

      state = AriaBlocksWorld.create_state(%{
        pos: %{"a" => "table", "b" => "table"},
        clear: %{"a" => true, "b" => true},
        holding: %{"hand" => false}
      })
  """
  @spec create_state(state_data()) :: AriaEngineCore.State.t()
  def create_state(data) do
    State.create(data)
  end

  @doc """
  Create a multigoal from the given goal data.

  ## Parameters

  - `goal_data` - Map containing desired state conditions

  ## Returns

  - `AriaEngineCore.Multigoal.t()` - Goal specification

  ## Example

      goal = AriaBlocksWorld.create_multigoal(%{
        pos: %{"a" => "b", "b" => "table"}
      })
  """
  @spec create_multigoal(map()) :: term()
  def create_multigoal(goal_data) do
    State.create_multigoal(goal_data)
  end

  @doc """
  Solve a blocks world planning problem.

  ## Parameters

  - `initial_state` - Starting state
  - `goals` - List of goals to achieve

  ## Returns

  - `{:ok, {final_state, solution_tree}}` - Success with results
  - `{:error, reason}` - Failure with error description

  ## Example

      {:ok, {final_state, solution_tree}} = AriaBlocksWorld.solve_problem(state, [goal])
  """
  @spec solve_problem(AriaState.t(), [term()]) ::
    {:ok, {AriaState.t(), term()}} | {:error, atom()}
  def solve_problem(initial_state, goals) do
    domain = Domain.create()
    AriaEngineCore.run_lazy(domain, initial_state, goals)
  end

  @doc """
  Plan for a blocks world problem without execution.

  ## Parameters

  - `initial_state` - Starting state
  - `goals` - List of goals to achieve

  ## Returns

  - `{:ok, solution_tree}` - Success with plan
  - `{:error, reason}` - Failure with error description

  ## Example

      {:ok, solution_tree} = AriaBlocksWorld.plan_problem(state, [goal])
  """
  @spec plan_problem(AriaState.t(), [term()]) ::
    {:ok, term()} | {:error, atom()}
  def plan_problem(initial_state, goals) do
    domain = Domain.create()
    AriaEngineCore.plan(domain, initial_state, goals)
  end

  @doc """
  Run a predefined example problem.

  ## Parameters

  - `example_name` - Name of the example to run

  ## Available Examples

  - `:sussman_anomaly` - The famous Sussman anomaly problem
  - `:simple_pickup` - Basic pickup and putdown operations
  - `:simple_stack` - Basic stacking operations
  - `:complex_multiblock` - Complex multi-block rearrangement

  ## Returns

  - `{:ok, result}` - Success with example results
  - `{:error, reason}` - Failure with error description

  ## Example

      {:ok, result} = AriaBlocksWorld.run_example(:sussman_anomaly)
      IO.inspect(result.plan, label: "Generated plan")
  """
  @spec run_example(atom()) :: {:ok, map()} | {:error, atom()}
  def run_example(example_name) do
    Examples.run(example_name)
  end

  @doc """
  List all available example problems.

  ## Returns

  - List of available example names

  ## Example

      examples = AriaBlocksWorld.list_examples()
      # [:sussman_anomaly, :simple_pickup, :simple_stack, :complex_multiblock]
  """
  @spec list_examples() :: [atom()]
  def list_examples do
    Examples.list_all()
  end

  @doc """
  Validate that a plan solves the given problem.

  ## Parameters

  - `initial_state` - Starting state
  - `plan` - List of actions to validate
  - `goals` - Goals that should be achieved

  ## Returns

  - `{:ok, final_state}` - Plan is valid, returns final state
  - `{:error, reason}` - Plan is invalid with error description

  ## Example

      {:ok, final_state} = AriaBlocksWorld.validate_plan(state, plan, goals)
  """
  @spec validate_plan(AriaEngineCore.State.t(), [term()], [term()]) ::
    {:ok, AriaEngineCore.State.t()} | {:error, atom()}
  def validate_plan(initial_state, plan, goals) do
    State.validate_plan(initial_state, plan, goals)
  end

  @doc """
  Get information about the blocks world domain.

  ## Returns

  - Map containing domain information

  ## Example

      info = AriaBlocksWorld.domain_info()
      IO.inspect(info.actions, label: "Available actions")
  """
  @spec domain_info() :: map()
  def domain_info do
    Domain.info()
  end
end
