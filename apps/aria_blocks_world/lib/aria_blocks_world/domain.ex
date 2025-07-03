# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaBlocksWorld.Domain do
  @moduledoc """
  Blocks world domain implementation following R25W1398085 unified durative action specification.

  This module implements the classic blocks world planning domain using the AriaHybridPlanner
  framework with proper entity-capability model and standardized action specifications.

  Based on the GTpyhop blocks_gtn domain which implements the near-optimal planning
  algorithm described in:

  N. Gupta and D. S. Nau. On the complexity of blocks-world planning.
  Artificial Intelligence 56(2-3):223–254, 1992.
  """

  use AriaCore.ActionAttributes

  @type block :: String.t()

  # Entity setup action
  @action true
  @spec setup_blocks_scenario(AriaHybridPlanner.State.t(), []) :: {:ok, AriaHybridPlanner.State.t()} | {:error, atom()}
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
  @spec pickup(AriaHybridPlanner.State.t(), [block()]) :: {:ok, AriaHybridPlanner.State.t()} | {:error, atom()}
  def pickup(state, [block]) do
    # Check preconditions
    current_pos = AriaHybridPlanner.get_fact(state, "pos", block)
    is_clear = AriaHybridPlanner.get_fact(state, "clear", block)
    hand_holding = AriaHybridPlanner.get_fact(state, "holding", "hand")

    cond do
      current_pos != "table" -> {:error, :not_on_table}
      is_clear != true -> {:error, :block_not_clear}
      hand_holding != false -> {:error, :hand_not_empty}
      true ->
        # Execute action
        new_state = state
        |> AriaHybridPlanner.set_fact("pos", block, "hand")
        |> AriaHybridPlanner.set_fact("clear", block, false)
        |> AriaHybridPlanner.set_fact("holding", "hand", block)

        {:ok, new_state}
    end
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
  @spec unstack(AriaHybridPlanner.State.t(), [block()]) :: {:ok, AriaHybridPlanner.State.t()} | {:error, atom()}
  def unstack(state, [block1, block2]) do
    # Check preconditions
    current_pos = AriaHybridPlanner.get_fact(state, "pos", block1)
    is_clear = AriaHybridPlanner.get_fact(state, "clear", block1)
    hand_holding = AriaHybridPlanner.get_fact(state, "holding", "hand")

    cond do
      current_pos != block2 -> {:error, :not_on_target_block}
      block2 == "table" -> {:error, :cannot_unstack_from_table}
      is_clear != true -> {:error, :block_not_clear}
      hand_holding != false -> {:error, :hand_not_empty}
      true ->
        # Execute action
        new_state = state
        |> AriaHybridPlanner.set_fact("pos", block1, "hand")
        |> AriaHybridPlanner.set_fact("clear", block1, false)
        |> AriaHybridPlanner.set_fact("holding", "hand", block1)
        |> AriaHybridPlanner.set_fact("clear", block2, true)

        {:ok, new_state}
    end
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
  @spec putdown(AriaHybridPlanner.State.t(), [block()]) :: {:ok, AriaHybridPlanner.State.t()} | {:error, atom()}
  def putdown(state, [block]) do
    # Check preconditions
    hand_holding = AriaHybridPlanner.get_fact(state, "holding", "hand")

    cond do
      hand_holding != block -> {:error, :not_holding_block}
      true ->
        # Execute action
        new_state = state
        |> AriaHybridPlanner.set_fact("pos", block, "table")
        |> AriaHybridPlanner.set_fact("clear", block, true)
        |> AriaHybridPlanner.set_fact("holding", "hand", false)

        {:ok, new_state}
    end
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
  @spec stack(AriaHybridPlanner.State.t(), [block()]) :: {:ok, AriaHybridPlanner.State.t()} | {:error, atom()}
  def stack(state, [block1, block2]) do
    # Check preconditions
    hand_holding = AriaHybridPlanner.get_fact(state, "holding", "hand")
    block2_clear = AriaHybridPlanner.get_fact(state, "clear", block2)

    cond do
      hand_holding != block1 -> {:error, :not_holding_block}
      block2_clear != true -> {:error, :destination_not_clear}
      true ->
        # Execute action
        new_state = state
        |> AriaHybridPlanner.set_fact("pos", block1, block2)
        |> AriaHybridPlanner.set_fact("clear", block1, true)
        |> AriaHybridPlanner.set_fact("holding", "hand", false)
        |> AriaHybridPlanner.set_fact("clear", block2, false)

        {:ok, new_state}
    end
  end

  @doc """
  Take a block (generic action that can pickup from table or unstack from another block).

  This is an alias for the appropriate pickup/unstack action based on the block's current position.
  """
  @action true
  @spec take(AriaHybridPlanner.State.t(), [block()]) :: {:ok, AriaHybridPlanner.State.t()} | {:error, atom()}
  def take(state, [block]) do
    current_pos = AriaHybridPlanner.get_fact(state, "pos", block)

    case current_pos do
      "table" -> pickup(state, [block])
      other_block when is_binary(other_block) -> unstack(state, [block, other_block])
      _ -> {:error, :invalid_position}
    end
  end

  # Task methods for complex workflows following R25W1398085

  @doc """
  Move a block to a specific position (table or another block).

  This task method decomposes the goal of moving a block into the appropriate
  sequence of pickup/unstack and putdown/stack actions.
  """
  @task_method true
  @spec move_block(AriaHybridPlanner.State.t(), [any()]) :: {:ok, [AriaHybridPlanner.todo_item()]} | {:error, atom()}
  def move_block(state, [block, destination]) do
    current_pos = AriaHybridPlanner.get_fact(state, "pos", block)

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

  @doc """
  Validate preconditions for moving a block to a destination.

  This task method decomposes validation into separate goal checks for the planner to orchestrate.
  """
  @task_method true
  @spec validate_move_preconditions(AriaHybridPlanner.State.t(), [block() | String.t()]) :: {:ok, [AriaHybridPlanner.todo_item()]} | {:error, atom()}
  def validate_move_preconditions(_state, [block, destination]) do
    # Decompose validation into separate goal checks for planner to orchestrate
    {:ok, [
      {"accessible", block, true},
      {"destination_available", destination, true},
      {"no_cyclic_dependency", {block, destination}, true}
    ]}
  end

  @doc """
  Validate move preconditions for a block to a destination.

  This task method checks if a move is valid and safe to execute.
  """
  @task_method true
  @spec validate_move(AriaHybridPlanner.State.t(), [block() | String.t()]) :: {:ok, [AriaHybridPlanner.todo_item()]} | {:error, atom()}
  def validate_move(_state, [_block, _destination]) do
    # For now, assume all moves are valid
    # In a more sophisticated implementation, this would check:
    # - Block is accessible (clear)
    # - Destination is available
    # - No cyclic dependencies
    {:ok, []}
  end

  # Task methods following GTPyhop blocks_gtn pattern

  @doc """
  Task method for 'take' - generates pickup or unstack action.

  Following GTPyhop m_take pattern: if block is clear, generate appropriate primitive action.
  """
  @task_method true
  @spec take_method(AriaHybridPlanner.State.t(), [block()]) :: {:ok, [AriaHybridPlanner.todo_item()]} | {:error, atom()}
  def take_method(state, [block]) do
    is_clear = AriaHybridPlanner.get_fact(state, "clear", block)
    current_pos = AriaHybridPlanner.get_fact(state, "pos", block)

    if is_clear == true do
      case current_pos do
        "table" -> {:ok, [{:pickup, [block]}]}
        other_block when is_binary(other_block) -> {:ok, [{:unstack, [block, other_block]}]}
        _ -> {:error, :invalid_position}
      end
    else
      {:error, :block_not_clear}
    end
  end

  @doc """
  Task method for 'put' - generates putdown or stack action.

  Following GTPyhop m_put pattern: if holding block, generate appropriate primitive action.
  """
  @task_method true
  @spec put_method(AriaHybridPlanner.State.t(), [block() | String.t()]) :: {:ok, [AriaHybridPlanner.todo_item()]} | {:error, atom()}
  def put_method(state, [block, destination]) do
    holding = AriaHybridPlanner.get_fact(state, "holding", "hand")

    if holding == block do
      case destination do
        "table" -> {:ok, [{:putdown, [block]}]}
        target_block when is_binary(target_block) -> {:ok, [{:stack, [block, target_block]}]}
        _ -> {:error, :invalid_destination}
      end
    else
      {:error, :not_holding_block}
    end
  end

  # Unigoal methods for achieving specific predicates

  @doc """
  Achieve a position goal for a block.

  This unigoal method handles goals of the form {"pos", block, destination}.
  It decomposes the goal into validation and movement task methods.
  """
  @unigoal_method predicate: "pos"
  @spec achieve_position(AriaHybridPlanner.State.t(), {String.t(), String.t()}) :: {:ok, [AriaHybridPlanner.todo_item()]} | {:error, atom()}
  def achieve_position(state, {block, destination}) do
    current_pos = AriaHybridPlanner.get_fact(state, "pos", block)

    # If already at destination, no action needed
    if current_pos == destination do
      {:ok, []}
    else
      # Need to move block to destination
      # Use task methods for validation and movement
      {:ok, [
        {:validate_move, [block, destination]},
        {:move_block, [block, destination]}
      ]}
    end
  end

  @doc """
  Achieve a clear goal for a block.

  This unigoal method handles goals of the form {"clear", block, true}.
  It finds what's on top of the block and moves it away using task methods.
  """
  @unigoal_method predicate: "clear"
  @spec achieve_clear(AriaHybridPlanner.State.t(), {String.t(), boolean()}) :: {:ok, [AriaHybridPlanner.todo_item()]} | {:error, atom()}
  def achieve_clear(state, {block, true}) do
    is_clear = AriaHybridPlanner.get_fact(state, "clear", block)

    # If already clear, no action needed
    if is_clear == true do
      {:ok, []}
    else
      # Find what's on top of this block
      blocking_block = find_block_on_top(state, block)

      if blocking_block do
        # Move the blocking block to the table using task methods
        {:ok, [
          {:validate_move, [blocking_block, "table"]},
          {:move_block, [blocking_block, "table"]}
        ]}
      else
        {:error, :no_blocking_block_found}
      end
    end
  end

  def achieve_clear(_state, {_block, false}) do
    # Cannot directly make a block not clear - this would require putting something on it
    # This is typically handled by other goals that stack blocks
    {:ok, []}
  end

  # Domain creation and helper functions

  @doc """
  Create the blocks world domain using attribute-based registration.
  """
  @spec create() :: AriaCore.Domain.t()
  def create() do
    # Create a proper AriaCore.Domain struct
    domain = AriaCore.new_domain(:blocks_world)

    # Register all attribute-defined actions and methods
    domain = AriaCore.register_attribute_specs(domain, __MODULE__)

    # Add multigoal method for splitting multigoals (GTpyhop pattern)
    domain = AriaCore.add_multigoal_method_to_domain(domain, "split_multigoal", &split_multigoal/2)

    domain
  end

  @doc """
  Get domain information.
  """
  @spec info() :: map()
  def info do
    %{
      name: "Blocks World Domain",
      description: "Classic blocks world planning domain with pickup, unstack, putdown, stack actions",
      actions: [:pickup, :unstack, :putdown, :stack, :take],
      task_methods: ["move_block", "validate_move_preconditions", "take", "put"],
      multigoal_methods: ["split_multigoal"],
      predicates: ["pos", "clear", "holding"],
      entities: ["hand", "table"],
      capabilities: [:manipulation, :support]
    }
  end

  @doc """
  Split a multigoal into individual unigoals following GTpyhop pattern.

  This multigoal method implements the classic GTpyhop m_split_multigoal approach:
  1. Check which goals in the multigoal are not yet satisfied
  2. Return individual unigoals for unsatisfied goals
  3. Add the original multigoal back for re-verification

  This ensures all goals are achieved and simultaneously true.
  """
  @spec split_multigoal(AriaHybridPlanner.State.t(), AriaEngineCore.Multigoal.t()) ::
    {:ok, [AriaHybridPlanner.todo_item()]} | {:error, atom()}
  def split_multigoal(state, multigoal) do
    # Check if multigoal is already satisfied
    if AriaEngineCore.Multigoal.satisfied?(multigoal, state) do
      {:ok, []}  # All goals already achieved
    else
      # Get unsatisfied goals
      unsatisfied = AriaEngineCore.Multigoal.unsatisfied_goals(multigoal, state)

      # Convert unsatisfied goals to individual unigoals
      # unsatisfied_goals already returns {predicate, subject, value} format
      unigoals = unsatisfied

      # GTpyhop pattern: return individual goals + original multigoal for re-verification
      todo_list = unigoals ++ [multigoal]

      {:ok, todo_list}
    end
  end

  # Private helper functions

  defp register_entity(state, [entity_id, type, capabilities]) do
    state
    |> AriaHybridPlanner.set_fact("type", entity_id, type)
    |> AriaHybridPlanner.set_fact("capabilities", entity_id, capabilities)
    |> AriaHybridPlanner.set_fact("status", entity_id, "available")
  end

  defp find_block_on_top(state, target_block) do
    # Find all blocks and check which one is positioned on the target block
    all_blocks = get_all_blocks(state)

    Enum.find(all_blocks, fn block ->
      AriaHybridPlanner.get_fact(state, "pos", block) == target_block
    end)
  end

  defp get_all_blocks(state) do
    # Get all subjects that have a "clear" predicate
    clear_true = AriaHybridPlanner.get_subjects_with_fact(state, "clear", true)
    clear_false = AriaHybridPlanner.get_subjects_with_fact(state, "clear", false)
    (clear_true ++ clear_false) |> Enum.uniq()
  end
end
