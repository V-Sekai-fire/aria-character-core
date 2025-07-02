# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaBlocksWorld.Domain do
  @moduledoc """
  Blocks world domain implementation following R25W1398085 unified durative action specification.

  This module implements the classic blocks world planning domain using the AriaEngine
  framework with proper entity-capability model and standardized action specifications.

  Based on the GTpyhop blocks_gtn domain which implements the near-optimal planning
  algorithm described in:

  N. Gupta and D. S. Nau. On the complexity of blocks-world planning.
  Artificial Intelligence 56(2-3):223–254, 1992.
  """

  use AriaCore.Domain

  @type block :: String.t()

  # Entity setup action
  @action true
  @spec setup_blocks_scenario(AriaState.t(), []) :: {:ok, AriaState.t()} | {:error, atom()}
  def setup_blocks_scenario(state, []) do
    state = state
    |> register_entity(["hand", "agent", [:manipulation]])
    |> register_entity(["table", "surface", [:support]])

    {:ok, state}
  end

  # Basic blocks world actions following R25W1398085 specification

  @doc """
  Pick up a block from the table.

  Preconditions:
  - Block must be on the table
  - Block must be clear
  - Hand must be empty

  Effects:
  - Block position becomes 'hand'
  - Block becomes not clear
  - Hand holds the block
  """
  @action true
  @spec pickup(AriaState.t(), [block()]) :: {:ok, AriaState.t()} | {:error, atom()}
  def pickup(state, [block]) do
    # Direct state transformation using AriaState.RelationalState
    new_state = state
    |> AriaState.RelationalState.set_fact("pos", block, "hand")
    |> AriaState.RelationalState.set_fact("clear", block, false)
    |> AriaState.RelationalState.set_fact("holding", "hand", block)

    {:ok, new_state}
  end

  @doc """
  Remove block1 from on top of block2.

  Preconditions:
  - Block1 must be on block2
  - Block2 must not be the table
  - Block1 must be clear
  - Hand must be empty

  Effects:
  - Block1 position becomes 'hand'
  - Block1 becomes not clear
  - Hand holds block1
  - Block2 becomes clear
  """
  @action true
  @spec unstack(AriaState.t(), [block()]) :: {:ok, AriaState.t()} | {:error, atom()}
  def unstack(state, [block1, block2]) do
    new_state = state
    |> AriaState.RelationalState.set_fact("pos", block1, "hand")
    |> AriaState.RelationalState.set_fact("clear", block1, false)
    |> AriaState.RelationalState.set_fact("holding", "hand", block1)
    |> AriaState.RelationalState.set_fact("clear", block2, true)

    {:ok, new_state}
  end

  @doc """
  Put down the held block on the table.

  Preconditions:
  - Block must be held in hand

  Effects:
  - Block position becomes 'table'
  - Block becomes clear
  - Hand becomes empty
  """
  @action true
  @spec putdown(AriaState.t(), [block()]) :: {:ok, AriaState.t()} | {:error, atom()}
  def putdown(state, [block]) do
    new_state = state
    |> AriaState.RelationalState.set_fact("pos", block, "table")
    |> AriaState.RelationalState.set_fact("clear", block, true)
    |> AriaState.RelationalState.set_fact("holding", "hand", false)

    {:ok, new_state}
  end

  @doc """
  Put block1 on top of block2.

  Preconditions:
  - Block1 must be held in hand
  - Block2 must be clear

  Effects:
  - Block1 position becomes block2
  - Block1 becomes clear
  - Hand becomes empty
  - Block2 becomes not clear
  """
  @action true
  @spec stack(AriaState.t(), [block()]) :: {:ok, AriaState.t()} | {:error, atom()}
  def stack(state, [block1, block2]) do
    new_state = state
    |> AriaState.RelationalState.set_fact("pos", block1, block2)
    |> AriaState.RelationalState.set_fact("clear", block1, true)
    |> AriaState.RelationalState.set_fact("holding", "hand", false)
    |> AriaState.RelationalState.set_fact("clear", block2, false)

    {:ok, new_state}
  end

  # Task methods for complex workflows following R25W1398085

  @doc """
  Move a block to a specific position (table or another block).

  This task method decomposes the goal of moving a block into the appropriate
  sequence of pickup/unstack and putdown/stack actions.
  """
  @task_method true
  @spec move_block(AriaState.t(), [any()]) :: {:ok, [AriaEngine.todo_item()]} | {:error, atom()}
  def move_block(state, [block, destination]) do
    current_pos = AriaState.RelationalState.get_fact(state, "pos", block)

    # Determine pickup/unstack action
    pickup_action = case current_pos do
      "table" -> {:pickup, [block]}
      other_block when is_binary(other_block) -> {:unstack, [block, other_block]}
      _ -> {:pickup, [block]}  # Default fallback
    end

    # Determine putdown/stack action
    putdown_action = case destination do
      "table" -> {:putdown, [block]}
      target_block -> {:stack, [block, target_block]}
    end

    {:ok, [pickup_action, putdown_action]}
  end

  # Unigoal methods for position goals following R25W1398085

  @doc """
  Handle position goals for blocks.

  This unigoal method handles goals of the form {"pos", block, destination}.
  """
  @unigoal_method predicate: "pos"
  @spec achieve_position(AriaState.t(), {block(), String.t()}) :: {:ok, [AriaEngine.todo_item()]} | {:error, atom()}
  def achieve_position(state, {block, destination}) do
    current_pos = AriaState.RelationalState.get_fact(state, "pos", block)

    if current_pos == destination do
      {:ok, []}  # Goal already achieved
    else
      {:ok, [{:move_block, [block, destination]}]}
    end
  end

  @doc """
  Handle clear goals for blocks.

  This unigoal method handles goals of the form {"clear", block, true}.
  """
  @unigoal_method predicate: "clear"
  @spec achieve_clear(AriaState.t(), {block(), boolean()}) :: {:ok, [AriaEngine.todo_item()]} | {:error, atom()}
  def achieve_clear(state, {block, true}) do
    current_clear = AriaState.RelationalState.get_fact(state, "clear", block)

    if current_clear == true do
      {:ok, []}  # Already clear
    else
      # Find what's on top of this block and move it
      blocks = get_all_blocks(state)
      blocking_block = Enum.find(blocks, fn b ->
        AriaState.RelationalState.get_fact(state, "pos", b) == block
      end)

      case blocking_block do
        nil -> {:ok, []}  # Nothing blocking
        blocker -> {:ok, [{:move_block, [blocker, "table"]}]}
      end
    end
  end
  def achieve_clear(_state, {_block, false}) do
    # Making a block not clear requires putting something on it
    # This is typically handled by other goals
    {:ok, []}
  end

  # Domain creation and helper functions

  @doc """
  Create the blocks world domain.
  """
  @spec create() :: AriaCore.Domain.t()
  def create(_opts \\ %{}) do
    AriaCore.Domain.new(:blocks_world)
  end

  @doc """
  Get domain information.
  """
  @spec info() :: map()
  def info do
    %{
      name: "Blocks World Domain",
      description: "Classic blocks world planning domain with pickup, unstack, putdown, stack actions",
      actions: [:pickup, :unstack, :putdown, :stack, :move_block],
      predicates: ["pos", "clear", "holding"],
      entities: ["hand", "table"],
      capabilities: [:manipulation, :support]
    }
  end

  # Private helper functions

  defp register_entity(state, [entity_id, type, capabilities]) do
    state
    |> AriaState.RelationalState.set_fact("type", entity_id, type)
    |> AriaState.RelationalState.set_fact("capabilities", entity_id, capabilities)
    |> AriaState.RelationalState.set_fact("status", entity_id, "available")
  end

  defp get_all_blocks(state) do
    # Get all subjects that have a "clear" predicate
    clear_true = AriaState.RelationalState.get_subjects_with_fact(state, "clear", true)
    clear_false = AriaState.RelationalState.get_subjects_with_fact(state, "clear", false)
    (clear_true ++ clear_false) |> Enum.uniq()
  end
end
