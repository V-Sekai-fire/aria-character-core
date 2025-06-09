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

  # Methods for GTN (Goal-Task-Network) domain



  # Methods for HGN (Hierarchical Goal Network) and goal splitting domains

  @doc """
  Unigoal method for positioning a block on the table.

  This method achieves the goal of having a block on the table.
  """
  def pos_on_table(%State{} = state, [["pos", block, "table"]]) do
    cond do
      State.get_object(state, "on_table", block) ->
        # Already on table
        []

      State.get_object(state, "holding", "hand") == block ->
        # Holding the block, just put it down
        [{"putdown", [block]}]

      true ->
        # Need to get the block first, then put it down
        [{"take", [block]}, {"put", [block, "table"]}]
    end
  end

  @doc """
  Unigoal method for positioning a block on top of another block.

  This method achieves the goal of having one block on top of another.
  """
  def pos_on_block(%State{} = state, [["pos", block, target]]) when target != "table" do
    cond do
      State.get_object(state, "on", block) == target ->
        # Already on target
        []

      State.get_object(state, "holding", "hand") == block ->
        # Holding the block, ensure target is clear and stack
        if State.get_object(state, "clear", target) do
          [{"stack", [block, target]}]
        else
          # Need to clear the target first
          [["pos", find_block_on_top(state, target), "table"], {"stack", [block, target]}]
        end

      true ->
        # Need to get the block first, ensure target is clear, then stack
        clear_target_goals = if State.get_object(state, "clear", target) do
          []
        else
          [["pos", find_block_on_top(state, target), "table"]]
        end

        [{"take", [block]} | clear_target_goals] ++ [{"put", [block, target]}]
    end
  end

  @doc """
  Unigoal method for positioning a block in hand.

  This method achieves the goal of holding a specific block.
  """
  def pos_in_hand(%State{} = state, [["pos", block, "hand"]]) do
    cond do
      State.get_object(state, "holding", "hand") == block ->
        # Already holding the block
        []

      State.get_object(state, "holding", "hand") != nil ->
        # Holding something else, put it down first
        held_block = State.get_object(state, "holding", "hand")
        [{"putdown", [held_block]}, {"take", [block]}]

      true ->
        # Hand is empty, just take the block
        [{"take", [block]}]
    end
  end

  @doc """
  Multigoal method for achieving complex block configurations.

  This method handles multiple positioning goals efficiently.
  """
  def achieve_blocks_multigoal(%State{} = state, goals) do
    # Filter out goals that are already satisfied
    unsatisfied_goals = Enum.filter(goals, fn goal ->
      not goal_satisfied?(state, goal)
    end)

    case unsatisfied_goals do
      [] ->
        # All goals satisfied
        []

      _ ->
        # Use a simple strategy: achieve goals in order
        # More sophisticated strategies could optimize the order
        unsatisfied_goals
    end
  end

  @doc """
  Unigoal method for achieving a holding state.

  This method achieves the goal of holding a specific block or having an empty hand.
  """
  def holding_state(%State{} = state, [["holding", "hand", value]]) do
    current_held = State.get_object(state, "holding", "hand")

    cond do
      current_held == value ->
        # Already in desired state
        []

      value == nil and current_held != nil ->
        # Want empty hand but holding something
        [{"putdown", [current_held]}]

      value != nil and current_held == nil ->
        # Want to hold something but hand is empty
        [{"take", [value]}]

      value != nil and current_held != nil ->
        # Want to hold something different
        [{"putdown", [current_held]}, {"take", [value]}]

      true ->
        false
    end
  end

  # Helper functions

  defp find_block_under(%State{} = state, block) do
    all_blocks = get_all_blocks(state)

    Enum.find(all_blocks, fn other_block ->
      State.get_object(state, "on", block) == other_block
    end)
  end

  defp find_block_on_top(%State{} = state, target_block) do
    all_blocks = get_all_blocks(state)

    Enum.find(all_blocks, fn block ->
      State.get_object(state, "on", block) == target_block
    end)
  end

  defp goal_satisfied?(%State{} = state, ["pos", block, "table"]) do
    State.get_object(state, "on_table", block)
  end

  defp goal_satisfied?(%State{} = state, ["pos", block, target]) when target != "table" do
    State.get_object(state, "on", block) == target
  end

  defp goal_satisfied?(%State{} = state, ["holding", "hand", value]) do
    State.get_object(state, "holding", "hand") == value
  end

  defp goal_satisfied?(%State{} = state, ["clear", block, true]) do
    State.get_object(state, "clear", block)
  end

  defp goal_satisfied?(_, _), do: false

  # GTN/HGN specific methods for Goal-Task-Network and Hierarchical Goal Network domains

  @doc """
  Task method: take a block from the table.
  """
  def take_from_table(%State{} = state, ["take", block]) do
    cond do
      State.get_object(state, "on_table", block) and State.get_object(state, "clear", block) ->
        [{:pickup, [block]}]
      true ->
        false
    end
  end

  @doc """
  Task method: take a block from on top of another block.
  """
  def take_from_block(%State{} = state, ["take", block]) do
    under_block = find_block_under(state, block)
    cond do
      under_block and State.get_object(state, "clear", block) ->
        [{:unstack, [block, under_block]}]
      true ->
        false
    end
  end

  @doc """
  Task method: put a block on the table.
  """
  def put_on_table(%State{} = state, ["put", block, "table"]) do
    cond do
      State.get_object(state, "holding", "hand") == block ->
        [{:putdown, [block]}]
      true ->
        false
    end
  end

  @doc """
  Task method: put a block on another block.
  """
  def put_on_block(%State{} = state, ["put", block, target]) when target != "table" do
    cond do
      State.get_object(state, "holding", "hand") == block and
      State.get_object(state, "clear", target) ->
        [{:stack, [block, target]}]
      true ->
        false
    end
  end


end
