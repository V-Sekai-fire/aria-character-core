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

  # Unigoal methods for position goals following R25W1398085

  @doc """
  Handle position goals for blocks.

  This unigoal method handles goals of the form {"pos", block, destination}.
  """
  @unigoal_method predicate: "pos"
  @spec achieve_position(AriaHybridPlanner.State.t(), {block(), String.t()}) :: {:ok, [AriaHybridPlanner.todo_item()]} | {:error, atom()}
  def achieve_position(state, {block, destination}) do
    current_pos = AriaHybridPlanner.get_fact(state, "pos", block)

    if current_pos == destination do
      {:ok, []}  # Goal already achieved
    else
      # Decompose into validation and move actions for planner to orchestrate
      {:ok, [
        {:validate_move, [block, destination]},
        {:move_block, [block, destination]}
      ]}
    end
  end

  @doc """
  Handle clear goals for blocks.

  This unigoal method handles goals of the form {"clear", block, true}.
  """
  @unigoal_method predicate: "clear"
  @spec achieve_clear(AriaHybridPlanner.State.t(), {block(), boolean()}) :: {:ok, [AriaHybridPlanner.todo_item()]} | {:error, atom()}
  def achieve_clear(state, {block, true}) do
    current_clear = AriaHybridPlanner.get_fact(state, "clear", block)

    if current_clear == true do
      {:ok, []}  # Already clear
    else
      # Find what's on top of this block and move it
      blocks = get_all_blocks(state)
      blocking_block = Enum.find(blocks, fn b ->
        AriaHybridPlanner.get_fact(state, "pos", b) == block
      end)

      case blocking_block do
        nil -> {:ok, []}  # Nothing blocking
        blocker ->
          # Decompose into validation and move actions for planner to orchestrate
          {:ok, [
            {:validate_move, [blocker, "table"]},
            {:move_block, [blocker, "table"]}
          ]}
      end
    end
  end
  def achieve_clear(_state, {_block, false}) do
    # Making a block not clear requires putting something on it
    # This is typically handled by other goals
    {:ok, []}
  end

  @doc """
  Check if a block is accessible (clear or can be made clear).

  This unigoal method handles goals of the form {"accessible", block, true}.
  """
  @unigoal_method predicate: "accessible"
  @spec check_block_accessible(AriaHybridPlanner.State.t(), {block(), boolean()}) :: {:ok, [AriaHybridPlanner.todo_item()]} | {:error, atom()}
  def check_block_accessible(state, {block, true}) do
    current_pos = AriaHybridPlanner.get_fact(state, "pos", block)

    case current_pos do
      "hand" -> {:ok, []}  # Already in hand
      "table" ->
        # Check if block is clear
        case AriaHybridPlanner.get_fact(state, "clear", block) do
          true ->
            # Check if hand is empty
            case AriaHybridPlanner.get_fact(state, "holding", "hand") do
              false -> {:ok, []}
              _ -> {:error, :hand_not_empty}
            end
          false -> {:error, :block_not_clear}
        end
      other_block when is_binary(other_block) ->
        # Block is on another block, check if it's clear and hand is empty
        case AriaHybridPlanner.get_fact(state, "clear", block) do
          true ->
            case AriaHybridPlanner.get_fact(state, "holding", "hand") do
              false -> {:ok, []}
              _ -> {:error, :hand_not_empty}
            end
          false -> {:error, :block_not_clear}
        end
      _ -> {:error, :invalid_position}
    end
  end

  @doc """
  Check if a destination is available for placing a block.

  This unigoal method handles goals of the form {"destination_available", destination, true}.
  """
  @unigoal_method predicate: "destination_available"
  @spec check_destination_available(AriaHybridPlanner.State.t(), {String.t(), boolean()}) :: {:ok, [AriaHybridPlanner.todo_item()]} | {:error, atom()}
  def check_destination_available(_state, {"table", true}) do
    {:ok, []}  # Table is always available
  end
  def check_destination_available(state, {target_block, true}) when is_binary(target_block) do
    case AriaHybridPlanner.get_fact(state, "clear", target_block) do
      true -> {:ok, []}
      false -> {:error, :destination_blocked}
      nil -> {:error, :invalid_destination}
    end
  end

  @doc """
  Check for cyclic dependencies in block movements.

  This unigoal method handles goals of the form {"no_cyclic_dependency", {block, destination}, true}.
  """
  @unigoal_method predicate: "no_cyclic_dependency"
  @spec check_no_cyclic_dependency(AriaHybridPlanner.State.t(), {{block(), String.t()}, boolean()}) :: {:ok, [AriaHybridPlanner.todo_item()]} | {:error, atom()}
  def check_no_cyclic_dependency(state, {{block, destination}, true}) when is_binary(destination) do
    # Check if destination is currently on top of block (direct cycle)
    dest_pos = AriaHybridPlanner.get_fact(state, "pos", destination)
    if dest_pos == block do
      {:error, :cyclic_dependency}
    else
      # Could add more sophisticated cycle detection here
      {:ok, []}
    end
  end
  def check_no_cyclic_dependency(_state, {{_block, "table"}, true}) do
    {:ok, []}  # No cycles with table
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
    AriaCore.add_multigoal_method_to_domain(domain, "split_multigoal", &split_multigoal/2)
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
      task_methods: ["move_block", "validate_move_preconditions"],
      unigoal_methods: ["pos", "clear", "accessible", "destination_available", "no_cyclic_dependency"],
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
      unigoals = Enum.map(unsatisfied, fn {subject, predicate, value} ->
        {predicate, subject, value}
      end)

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

  defp get_all_blocks(state) do
    # Get all subjects that have a "clear" predicate
    clear_true = AriaHybridPlanner.get_subjects_with_fact(state, "clear", true)
    clear_false = AriaHybridPlanner.get_subjects_with_fact(state, "clear", false)
    (clear_true ++ clear_false) |> Enum.uniq()
  end
end
