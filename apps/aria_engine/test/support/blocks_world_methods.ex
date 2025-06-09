# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngine.BlocksWorldMethods do
  @moduledoc """
  Methods for blocks world planning domain.
  
  This module implements task methods and goal methods for blocks world planning,
  including strategies for moving blocks and achieving complex block configurations.
  """

  alias AriaEngine.State

  @doc """
  Task method for moving a block to a target location.
  
  This method handles the decomposition of moving a block to either:
  - The table (using putdown)
  - On top of another block (using stack)
  """
  def move_block(%State{} = state, [block, target]) do
    cond do
      target == "table" ->
        # Move block to table
        if State.get_object(state, "holding", "hand") == block do
          # Already holding the block, just put it down
          [{:putdown, [block]}]
        else
          # Need to get the block first, then put it down
          [{"get_block", [block]}, {:putdown, [block]}]
        end
      
      true ->
        # Move block on top of another block
        if State.get_object(state, "holding", "hand") == block do
          # Already holding the block, just stack it
          [{:stack, [block, target]}]
        else
          # Need to get the block first, then stack it
          [{"get_block", [block]}, {:stack, [block, target]}]
        end
    end
  end

  @doc """
  Task method for getting a block (picking it up or unstacking it).
  
  This method determines whether to pickup a block from the table
  or unstack it from another block.
  """
  def get_block(%State{} = state, [block]) do
    cond do
      State.get_object(state, "on_table", block) ->
        # Block is on table, just pick it up
        [{:pickup, [block]}]
      
      true ->
        # Block is on another block, need to unstack it
        target = State.get_object(state, "on", block)
        if target do
          [{:unstack, [block, target]}]
        else
          []  # Invalid state
        end
    end
  end

  @doc """
  Task method for clearing a block (removing everything on top of it).
  
  This method recursively clears all blocks stacked on top of the target block.
  """
  def clear_block(%State{} = state, [block]) do
    # Find all blocks that are directly on top of this block
    blocks_on_top = find_blocks_on_top(state, block)
    
    case blocks_on_top do
      [] ->
        # Block is already clear
        []
      
      [top_block | _] ->
        # Clear the top block first, then move it away
        [{"clear_block", [top_block]}, {"move_block", [top_block, "table"]}]
    end
  end

  @doc """
  Unigoal method for achieving 'on(block, target)' goals.
  """
  def on_unigoal(%State{} = state, [block, target]) do
    current_location = State.get_object(state, "on", block)
    
    cond do
      current_location == target ->
        # Goal already satisfied
        []
      
      true ->
        # Need to move the block
        [{"move_block", [block, target]}]
    end
  end

  @doc """
  Unigoal method for achieving 'on_table(block)' goals.
  """
  def on_table_unigoal(%State{} = state, [block, true]) do
    if State.get_object(state, "on_table", block) do
      # Goal already satisfied
      []
    else
      # Need to move block to table
      [{"move_block", [block, "table"]}]
    end
  end

  @doc """
  Unigoal method for achieving 'clear(block)' goals.
  """
  def clear_unigoal(%State{} = state, [block, true]) do
    if State.get_object(state, "clear", block) do
      # Goal already satisfied
      []
    else
      # Need to clear the block
      [{"clear_block", [block]}]
    end
  end

  @doc """
  Multigoal method for achieving tower configurations.
  
  This method handles building towers of blocks in a specific order.
  """
  def build_tower(%State{} = _state, [blocks]) do
    case blocks do
      [] ->
        []
      
      [single_block] ->
        # Single block tower - just ensure it's on the table
        [{"move_block", [single_block, "table"]}]
      
      [bottom | rest] ->
        # Multi-block tower - build from bottom up
        tower_goals = build_tower_goals(bottom, rest)
        # First ensure bottom block is on table
        [{"move_block", [bottom, "table"]} | tower_goals]
    end
  end

  # Helper function to find blocks on top of a given block
  defp find_blocks_on_top(%State{} = state, target_block) do
    # Get all block names from state and find which ones are on target_block
    all_blocks = get_all_blocks(state)
    
    Enum.filter(all_blocks, fn block ->
      State.get_object(state, "on", block) == target_block
    end)
  end

  # Helper function to get all block names from state
  defp get_all_blocks(%State{} = state) do
    # This would need to be implemented based on how blocks are tracked in state
    # For now, assume blocks are tracked in a "blocks" list
    State.get_object(state, "blocks", "list") || []
  end

  # Helper function to build tower goals recursively
  defp build_tower_goals(_bottom, []) do
    []
  end

  defp build_tower_goals(bottom, [next | rest]) do
    [{"move_block", [next, bottom]} | build_tower_goals(next, rest)]
  end
end
