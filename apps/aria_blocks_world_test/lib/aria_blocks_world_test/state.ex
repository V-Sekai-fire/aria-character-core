# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaBlocksWorldTest.State do
  @moduledoc """
  State management for the blocks world domain following R25W1398085.

  This module provides functions for creating, manipulating, and validating
  blocks world states using the AriaState.RelationalState system as specified
  in the unified durative action specification.

  ## State Representation

  The blocks world state uses three main predicates:
  - `{"pos", block, position}` - Position of block (table, hand, or another block)
  - `{"clear", block, boolean}` - Whether block is clear (true/false)
  - `{"holding", "hand", block_or_false}` - What the hand is holding (block name or false)

  ## Example

      state = AriaBlocksWorldTest.State.create(%{
        pos: %{"a" => "b", "b" => "table", "c" => "table"},
        clear: %{"a" => true, "b" => false, "c" => true},
        holding: %{"hand" => false}
      })
  """

  @type block :: String.t()
  @type position :: String.t()  # "table", "hand", or another block name

  @doc """
  Create a blocks world state from the given data.

  ## Parameters

  - `data` - Map containing pos, clear, and holding information

  ## Returns

  - `AriaState.t()` - Initialized state

  ## Example

      state = AriaBlocksWorldTest.State.create(%{
        pos: %{"a" => "table", "b" => "table"},
        clear: %{"a" => true, "b" => true},
        holding: %{"hand" => false}
      })
  """
  @spec create(map()) :: AriaState.t()
  def create(data) do
    state = AriaState.RelationalState.new()

    # Set position facts using AriaState.RelationalState
    state = Enum.reduce(data.pos || %{}, state, fn {block, position}, acc ->
      AriaState.RelationalState.set_fact(acc, "pos", block, position)
    end)

    # Set clear facts
    state = Enum.reduce(data.clear || %{}, state, fn {block, is_clear}, acc ->
      AriaState.RelationalState.set_fact(acc, "clear", block, is_clear)
    end)

    # Set holding facts
    state = Enum.reduce(data.holding || %{}, state, fn {entity, held_item}, acc ->
      AriaState.RelationalState.set_fact(acc, "holding", entity, held_item)
    end)

    state
  end

  @doc """
  Create a multigoal from the given goal data.

  ## Parameters

  - `goal_data` - Map containing desired state conditions

  ## Returns

  - Multigoal structure for planning

  ## Example

      goal = AriaBlocksWorldTest.State.create_multigoal(%{
        pos: %{"a" => "b", "b" => "table"}
      })
  """
  @spec create_multigoal(map()) :: term()
  def create_multigoal(goal_data) do
    # For now, return the goal data as-is
    # This will be refined when we implement the planning methods
    {:multigoal, goal_data}
  end

  @doc """
  Get the position of a block.

  ## Parameters

  - `state` - Current state
  - `block` - Block to query

  ## Returns

  - Position of the block (:table, :hand, or another block)

  ## Example

      pos = AriaBlocksWorldTest.State.get_position(state, "a")
  """
  @spec get_position(AriaState.t(), block()) :: position()
  def get_position(state, block) do
    AriaState.RelationalState.get_fact(state, "pos", block)
  end

  @doc """
  Check if a block is clear.

  ## Parameters

  - `state` - Current state
  - `block` - Block to query

  ## Returns

  - Boolean indicating if the block is clear

  ## Example

      is_clear = AriaBlocksWorldTest.State.is_clear?(state, "a")
  """
  @spec is_clear?(AriaState.t(), block()) :: boolean()
  def is_clear?(state, block) do
    AriaState.RelationalState.get_fact(state, "clear", block) == true
  end

  @doc """
  Get what the hand is holding.

  ## Parameters

  - `state` - Current state

  ## Returns

  - Block name or false if hand is empty

  ## Example

      held = AriaBlocksWorldTest.State.get_holding(state)
  """
  @spec get_holding(AriaState.t()) :: block() | false
  def get_holding(state) do
    AriaState.RelationalState.get_fact(state, "holding", "hand")
  end

  @doc """
  Set the position of a block.

  ## Parameters

  - `state` - Current state
  - `block` - Block to move
  - `position` - New position

  ## Returns

  - Updated state

  ## Example

      new_state = AriaBlocksWorldTest.State.set_position(state, "a", "table")
  """
  @spec set_position(AriaState.t(), block(), position()) :: AriaState.t()
  def set_position(state, block, position) do
    AriaState.RelationalState.set_fact(state, "pos", block, position)
  end

  @doc """
  Set whether a block is clear.

  ## Parameters

  - `state` - Current state
  - `block` - Block to update
  - `is_clear` - Whether the block is clear

  ## Returns

  - Updated state

  ## Example

      new_state = AriaBlocksWorldTest.State.set_clear(state, "a", true)
  """
  @spec set_clear(AriaState.t(), block(), boolean()) :: AriaState.t()
  def set_clear(state, block, is_clear) do
    AriaState.RelationalState.set_fact(state, "clear", block, is_clear)
  end

  @doc """
  Set what the hand is holding.

  ## Parameters

  - `state` - Current state
  - `item` - Block name or false if hand should be empty

  ## Returns

  - Updated state

  ## Example

      new_state = AriaBlocksWorldTest.State.set_holding(state, "a")
  """
  @spec set_holding(AriaState.t(), block() | false) :: AriaState.t()
  def set_holding(state, item) do
    AriaState.RelationalState.set_fact(state, "holding", "hand", item)
  end

  @doc """
  Get all blocks in the state.

  ## Parameters

  - `state` - Current state

  ## Returns

  - List of all block names

  ## Example

      blocks = AriaBlocksWorldTest.State.all_blocks(state)
  """
  @spec all_blocks(AriaState.t()) :: [block()]
  def all_blocks(state) do
    # Get all subjects that have a "clear" predicate
    clear_true = AriaState.RelationalState.get_subjects_with_fact(state, "clear", true)
    clear_false = AriaState.RelationalState.get_subjects_with_fact(state, "clear", false)
    (clear_true ++ clear_false) |> Enum.uniq()
  end

  @doc """
  Get all clear blocks in the state.

  ## Parameters

  - `state` - Current state

  ## Returns

  - List of clear block names

  ## Example

      clear_blocks = AriaBlocksWorldTest.State.all_clear_blocks(state)
  """
  @spec all_clear_blocks(AriaState.t()) :: [block()]
  def all_clear_blocks(state) do
    AriaState.RelationalState.get_subjects_with_fact(state, "clear", true)
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
  """
  @spec validate_plan(AriaState.t(), [term()], [term()]) ::
    {:ok, AriaState.t()} | {:error, atom()}
  def validate_plan(_initial_state, _plan, _goals) do
    # TODO: Implement plan validation
    {:error, :not_implemented}
  end

  @doc """
  Display the current state in a human-readable format.

  ## Parameters

  - `state` - State to display
  - `label` - Optional label for the output

  ## Example

      AriaBlocksWorldTest.State.display(state, "Initial state")
  """
  @spec display(AriaState.t(), String.t()) :: :ok
  def display(state, label \\ "State") do
    IO.puts("\n#{label}:")

    blocks = all_blocks(state)

    IO.puts("  Positions:")
    Enum.each(blocks, fn block ->
      pos = get_position(state, block)
      IO.puts("    #{block} -> #{inspect(pos)}")
    end)

    IO.puts("  Clear:")
    Enum.each(blocks, fn block ->
      clear = is_clear?(state, block)
      IO.puts("    #{block} -> #{clear}")
    end)

    holding = get_holding(state)
    IO.puts("  Holding: hand -> #{inspect(holding)}")

    :ok
  end
end
