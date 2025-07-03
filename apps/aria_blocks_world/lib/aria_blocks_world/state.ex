# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaBlocksWorld.State do
  require Logger

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

      state = AriaBlocksWorld.State.create(%{
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

      state = AriaBlocksWorld.State.create(%{
        pos: %{"a" => "table", "b" => "table"},
        clear: %{"a" => true, "b" => true},
        holding: %{"hand" => false}
      })
  """
  @spec create(map()) :: AriaHybridPlanner.State.t()
  def create(data) do
    state = AriaHybridPlanner.new_state()

    # Set position facts using AriaHybridPlanner
    state = Enum.reduce(data.pos || %{}, state, fn {block, position}, acc ->
      AriaHybridPlanner.set_fact(acc, "pos", block, position)
    end)

    # Set clear facts
    state = Enum.reduce(data.clear || %{}, state, fn {block, is_clear}, acc ->
      AriaHybridPlanner.set_fact(acc, "clear", block, is_clear)
    end)

    # Set holding facts
    state = Enum.reduce(data.holding || %{}, state, fn {entity, held_item}, acc ->
      AriaHybridPlanner.set_fact(acc, "holding", entity, held_item)
    end)

    state
  end

  @doc """
  Create a multigoal from the given goal data.

  ## Parameters

  - `goal_data` - Map containing desired state conditions

  ## Returns

  - AriaEngineCore.Multigoal.t() - Proper multigoal structure for planning

  ## Example

      goal = AriaBlocksWorld.State.create_multigoal(%{
        pos: %{"a" => "b", "b" => "table"}
      })
  """
  @spec create_multigoal(map()) :: AriaEngineCore.Multigoal.t()
  def create_multigoal(goal_data) do
    # Convert blocks world goal format to predicate-subject-value triples
    goals = []

    # Convert position goals
    goals = if Map.has_key?(goal_data, :pos) do
      pos_goals = Enum.map(goal_data.pos, fn {block, position} ->
        {"pos", block, position}
      end)
      goals ++ pos_goals
    else
      goals
    end

    # Convert clear goals
    goals = if Map.has_key?(goal_data, :clear) do
      clear_goals = Enum.map(goal_data.clear, fn {block, is_clear} ->
        {"clear", block, is_clear}
      end)
      goals ++ clear_goals
    else
      goals
    end

    # Convert holding goals
    goals = if Map.has_key?(goal_data, :holding) do
      holding_goals = Enum.map(goal_data.holding, fn {entity, held_item} ->
        {"holding", entity, held_item}
      end)
      goals ++ holding_goals
    else
      goals
    end

    AriaEngineCore.Multigoal.new(goals)
  end

  @doc """
  Get the position of a block.

  ## Parameters

  - `state` - Current state
  - `block` - Block to query

  ## Returns

  - Position of the block (:table, :hand, or another block)

  ## Example

      pos = AriaBlocksWorld.State.get_position(state, "a")
  """
  @spec get_position(AriaHybridPlanner.State.t(), block()) :: position()
  def get_position(state, block) do
    AriaHybridPlanner.get_fact(state, "pos", block)
  end

  @doc """
  Check if a block is clear.

  ## Parameters

  - `state` - Current state
  - `block` - Block to query

  ## Returns

  - Boolean indicating if the block is clear

  ## Example

      is_clear = AriaBlocksWorld.State.is_clear?(state, "a")
  """
  @spec is_clear?(AriaHybridPlanner.State.t(), block()) :: boolean()
  def is_clear?(state, block) do
    AriaHybridPlanner.get_fact(state, "clear", block) == true
  end

  @doc """
  Get what the hand is holding.

  ## Parameters

  - `state` - Current state

  ## Returns

  - Block name or false if hand is empty

  ## Example

      held = AriaBlocksWorld.State.get_holding(state)
  """
  @spec get_holding(AriaHybridPlanner.State.t()) :: block() | false
  def get_holding(state) do
    AriaHybridPlanner.get_fact(state, "holding", "hand")
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

      new_state = AriaBlocksWorld.State.set_position(state, "a", "table")
  """
  @spec set_position(AriaHybridPlanner.State.t(), block(), position()) :: AriaHybridPlanner.State.t()
  def set_position(state, block, position) do
    AriaHybridPlanner.set_fact(state, "pos", block, position)
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

      new_state = AriaBlocksWorld.State.set_clear(state, "a", true)
  """
  @spec set_clear(AriaHybridPlanner.State.t(), block(), boolean()) :: AriaHybridPlanner.State.t()
  def set_clear(state, block, is_clear) do
    AriaHybridPlanner.set_fact(state, "clear", block, is_clear)
  end

  @doc """
  Set what the hand is holding.

  ## Parameters

  - `state` - Current state
  - `item` - Block name or false if hand should be empty

  ## Returns

  - Updated state

  ## Example

      new_state = AriaBlocksWorld.State.set_holding(state, "a")
  """
  @spec set_holding(AriaHybridPlanner.State.t(), block() | false) :: AriaHybridPlanner.State.t()
  def set_holding(state, item) do
    AriaHybridPlanner.set_fact(state, "holding", "hand", item)
  end

  @doc """
  Get all blocks in the state.

  ## Parameters

  - `state` - Current state

  ## Returns

  - List of all block names

  ## Example

      blocks = AriaBlocksWorld.State.all_blocks(state)
  """
  @spec all_blocks(AriaHybridPlanner.State.t()) :: [block()]
  def all_blocks(state) do
    # Get all subjects that have a "clear" predicate
    AriaHybridPlanner.get_subjects_with_fact(state, "clear", true) ++
    AriaHybridPlanner.get_subjects_with_fact(state, "clear", false)
    |> Enum.uniq()
  end

  @doc """
  Get all clear blocks in the state.

  ## Parameters

  - `state` - Current state

  ## Returns

  - List of clear block names

  ## Example

      clear_blocks = AriaBlocksWorld.State.all_clear_blocks(state)
  """
  @spec all_clear_blocks(AriaHybridPlanner.State.t()) :: [block()]
  def all_clear_blocks(state) do
    AriaHybridPlanner.get_subjects_with_fact(state, "clear", true)
  end

  @doc """
  Display the current state in a human-readable format.

  ## Parameters

  - `state` - State to display
  - `label` - Optional label for the output

  ## Example

      AriaBlocksWorld.State.display(state, "Initial state")
  """
  @spec display(AriaHybridPlanner.State.t(), String.t()) :: :ok
  def display(state, label \\ "State") do
    Logger.debug("\n#{label}:")

    blocks = all_blocks(state)

    Logger.debug("  Positions:")
    Enum.each(blocks, fn block ->
      pos = get_position(state, block)
      Logger.debug("    #{block} -> #{inspect(pos)}")
    end)

    Logger.debug("  Clear:")
    Enum.each(blocks, fn block ->
      clear = is_clear?(state, block)
      Logger.debug("    #{block} -> #{clear}")
    end)

    holding = get_holding(state)
    Logger.debug("  Holding: hand -> #{inspect(holding)}")

    :ok
  end
end
