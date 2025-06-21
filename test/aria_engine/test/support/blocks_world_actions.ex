# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule BlocksWorldActions do
  @moduledoc """
  Actions for the classic blocks world planning domain.

  This module implements the four basic actions in blocks world:
  - pickup: pick up a block from the table
  - putdown: put down a held block on the table
  - stack: stack a held block on top of another block
  - unstack: unstack a block from on top of another block
  """

  alias State

  @doc """
  Pick up a block from the table.

  Preconditions:
  - Block must be clear (nothing on top of it)
  - Block must be on the table
  - Hand must be empty (not holding anything)

  Effects:
  - Block is no longer on the table
  - Block is no longer clear
  - Hand is holding the block
  """
  def pickup(%State{} = state, [block]) do
    # Check preconditions
    cond do
      not State.get_fact(state, "clear", block) ->
        # Block is not clear
        false

      not State.get_fact(state, "on_table", block) ->
        # Block is not on table
        false

      State.get_fact(state, "holding", "hand") != nil ->
        # Hand is not empty
        false

      true ->
        # Apply effects
        state
        |> State.set_fact("on_table", block, false)
        |> State.set_fact("clear", block, false)
        |> State.set_fact("holding", "hand", block)
    end
  end

  @doc """
  Put down a held block on the table.

  Preconditions:
  - Hand must be holding the specified block

  Effects:
  - Block is on the table
  - Block is clear
  - Hand is empty
  """
  def putdown(%State{} = state, [block]) do
    # Check preconditions
    if State.get_fact(state, "holding", "hand") == block do
      # Apply effects
      state
      |> State.set_fact("on_table", block, true)
      |> State.set_fact("clear", block, true)
      |> State.set_fact("holding", "hand", nil)
    else
      # Not holding the specified block
      false
    end
  end

  @doc """
  Stack a held block on top of another block.

  Preconditions:
  - Hand must be holding the block to be stacked
  - Target block must be clear

  Effects:
  - Block is on top of target block
  - Block is clear
  - Target block is no longer clear
  - Hand is empty
  """
  def stack(%State{} = state, [block, target]) do
    # Check preconditions
    cond do
      State.get_fact(state, "holding", "hand") != block ->
        # Not holding the block
        false

      not State.get_fact(state, "clear", target) ->
        # Target is not clear
        false

      block == target ->
        # Cannot stack block on itself
        false

      true ->
        # Apply effects
        state
        |> State.set_fact("on", block, target)
        |> State.set_fact("clear", block, true)
        |> State.set_fact("clear", target, false)
        |> State.set_fact("holding", "hand", nil)
    end
  end

  @doc """
  Unstack a block from on top of another block.

  Preconditions:
  - Block must be on top of target block
  - Block must be clear
  - Hand must be empty

  Effects:
  - Block is no longer on target block
  - Block is no longer clear
  - Target block is clear
  - Hand is holding the block
  """
  def unstack(%State{} = state, [block, target]) do
    # Check preconditions
    cond do
      State.get_fact(state, "on", block) != target ->
        # Block is not on target
        false

      not State.get_fact(state, "clear", block) ->
        # Block is not clear
        false

      State.get_fact(state, "holding", "hand") != nil ->
        # Hand is not empty
        false

      true ->
        # Apply effects
        state
        |> State.set_fact("on", block, nil)
        |> State.set_fact("clear", block, false)
        |> State.set_fact("clear", target, true)
        |> State.set_fact("holding", "hand", block)
    end
  end
end
