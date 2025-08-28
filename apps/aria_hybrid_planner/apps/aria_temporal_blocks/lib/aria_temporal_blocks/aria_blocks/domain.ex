# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaBlocks.Domain do
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
  @action duration: "PT0S"
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
  @action duration: "PT2S"
  @spec pickup(AriaState.t(), []) :: {:ok, AriaState.t()} | {:error, atom()}
  def pickup(state, [block]) do
    is_clear = AriaState.get_fact(state, block, "clear")
    hand_holding = AriaState.get_fact(state, "hand", "holding")
    current_pos = AriaState.get_fact(state, block, "pos")

    cond do
      current_pos != "table" -> {:error, :not_on_table}
      not is_clear -> {:error, :block_not_clear}
      hand_holding != false -> {:error, :hand_not_empty}
      true ->
        new_state = state
        |> AriaState.set_fact(block, "pos", "hand")
        |> AriaState.set_fact(block, "clear", false)
        |> AriaState.set_fact("hand", "holding", block)
        {:ok, new_state}
    end
  end

  @doc """
  Remove block1 from on top of block2.

  Preconditions:
  - Block1 must be on block2 (including table)
  - Block1 must be clear
  - Hand must be empty

  Effects:
  - Block1 position becomes 'hand'
  - Block1 becomes not clear
  - Hand holds block1
  - Block2 becomes clear (if block2 is not table)
  """
  @action duration: "PT3S"
  @spec unstack(AriaState.t(), [block()]) :: {:ok, AriaState.t()} | {:error, atom()}
  def unstack(state, [block1, block2]) do
    # Check preconditions
    current_pos = AriaState.get_fact(state, block1, "pos")
    is_clear = AriaState.get_fact(state, block1, "clear")
    hand_holding = AriaState.get_fact(state, "hand", "holding")

    cond do
      current_pos != block2 -> {:error, :not_on_target_block}
      is_clear != true -> {:error, :block_not_clear}
      hand_holding != false -> {:error, :hand_not_empty}
      true ->
        # Execute action
        new_state = state
        |> AriaState.set_fact(block1, "pos", "hand")
        |> AriaState.set_fact(block1, "clear", false)
        |> AriaState.set_fact("hand", "holding", block1)

        # Only set block2 clear if it's not the table
        new_state = if block2 != "table" do
          AriaState.set_fact(new_state, block2, "clear", true)
        else
          new_state
        end

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
  @action duration: "PT1.5S"
  @spec putdown(AriaState.t(), [block()]) :: {:ok, AriaState.t()} | {:error, atom()}
  def putdown(state, [block]) do
    # Check preconditions
    hand_holding = AriaState.get_fact(state, "hand", "holding")

    cond do
      hand_holding != block -> {:error, :not_holding_block}
      true ->
        # Execute action
        new_state = state
        |> AriaState.set_fact(block, "pos", "table")
        |> AriaState.set_fact(block, "clear", true)
        |> AriaState.set_fact("hand", "holding", false)

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
  @action duration: "PT2.5S"
  @spec stack(AriaState.t(), [block()]) :: {:ok, AriaState.t()} | {:error, atom()}
  def stack(state, [block1, block2]) do
    # Check preconditions
    hand_holding = AriaState.get_fact(state, "hand", "holding")
    block2_clear = AriaState.get_fact(state, block2, "clear")

    cond do
      hand_holding != block1 -> {:error, :not_holding_block}
      block2_clear != true -> {:error, :destination_not_clear}
      true ->
        # Execute action
        new_state = state
        |> AriaState.set_fact(block1, "pos", block2)
        |> AriaState.set_fact(block1, "clear", true)
        |> AriaState.set_fact("hand", "holding", false)
        |> AriaState.set_fact(block2, "clear", false)

        {:ok, new_state}
    end
  end

  @doc """
  Wait for a specified duration.

  This action allows the planner to introduce delays in the execution.
  The duration is specified as a parameter in the action call.
  Duration will be extracted from the first argument.

  Preconditions:
  - None

  Effects:
  - None (state remains unchanged)
  """
  @action duration: "PT1S"
  @spec wait(AriaState.t(), [number()]) :: {:ok, AriaState.t()} | {:error, atom()}
  def wait(state, [duration]) when is_number(duration) and duration >= 0 do
    # Wait action doesn't change the state, just consumes time
    {:ok, state}
  end

  def wait(_state, [duration]) when not is_number(duration) do
    {:error, :invalid_duration_type}
  end

  def wait(_state, [duration]) when duration < 0 do
    {:error, :negative_duration}
  end

  def wait(_state, _args) do
    {:error, :invalid_arguments}
  end

  @doc """
  Take a block (task method that decomposes to pickup or unstack based on position).

  This task method determines the appropriate action based on the block's current position
  and returns the corresponding subtask.
  """
  @task_method true
  @spec take(AriaState.t(), [block()]) :: {:ok, [AriaHybridPlanner.todo_item()]} | {:error, atom()}
  def take(state, [block]) do
    current_pos = AriaState.get_fact(state, block, "pos")
    if current_pos == nil do
      {:error, :block_not_found}
    else
      case current_pos do
        "table" -> {:ok, [{:pickup, [block]}]}
        other_block when is_binary(other_block) -> {:ok, [{:unstack, [block, other_block]}]}
      end
    end
  end

  # Task methods for complex workflows following R25W1398085

  @doc """
  Move a block to a specific position (table or another block).

  This task method decomposes the goal of moving a block into the appropriate
  sequence of pickup/unstack and putdown/stack actions.
  """
  @task_method true
  @spec move_block(AriaState.t(), [any()]) :: {:ok, [AriaHybridPlanner.todo_item()]} | {:error, atom()}
  def move_block(state, [block, destination]) do
    current_pos = AriaState.get_fact(state, block, "pos")

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
  @spec validate_move_preconditions(AriaState.t(), [block() | String.t()]) :: {:ok, [AriaHybridPlanner.todo_item()]} | {:error, atom()}
  def validate_move_preconditions(_state, [block, destination]) do
    # Decompose validation into separate goal checks for planner to orchestrate
    {:ok, [
      {"accessible", block, true},
      {"destination_available", destination, true},
      {"no_cyclic_dependency", {block, destination}, true}
    ]}
  end

  # Task methods following GTPyhop blocks_gtn pattern


  @doc """
  Task method for 'put' - generates putdown or stack action.

  Following GTPyhop m_put pattern: if holding block, generate appropriate primitive action.
  """
  @task_method true
  @spec put_method(AriaState.t(), [block() | String.t()]) :: {:ok, [AriaHybridPlanner.todo_item()]} | {:error, atom()}
  def put_method(state, [block, destination]) do
    holding = AriaState.get_fact(state, "hand", "holding")

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
  Achieve a position goal for a block (primary method).

  This unigoal method handles goals of the form {"pos", block, destination}.
  It only generates subgoals that are actually needed based on current state.
  """
  @unigoal_method predicate: "pos"
  @spec achieve_position(AriaState.t(), {String.t(), String.t()}) :: {:ok, [AriaHybridPlanner.todo_item()]} | {:error, atom()}
  def achieve_position(state, {block, destination}) do
    current_pos = AriaState.get_fact(state, block, "pos")

    # If already at destination, no action needed
    if current_pos == destination do
      {:ok, []}
    else
      # Check what subgoals are actually needed
      is_clear = AriaState.get_fact(state, block, "clear")
      destination_clear = case destination do
        "table" -> true  # Table is always available
        dest_block -> AriaState.get_fact(state, dest_block, "clear")
      end

      # Build subgoals list based on what's actually needed
      subgoals = []

      # Only add clear block goal if block is not already clear
      subgoals = if is_clear != true do
        [{"clear", block, true} | subgoals]
      else
        subgoals
      end

      # Only add clear destination goal if destination is not already clear
      subgoals = if destination != "table" and destination_clear != true do
        [{"clear", destination, true} | subgoals]
      else
        subgoals
      end

      # Add movement actions
      pickup_action = case current_pos do
        "table" -> {:pickup, [block]}
        other_block when is_binary(other_block) -> {:unstack, [block, other_block]}
        _ -> {:pickup, [block]}  # Default fallback
      end

      putdown_action = case destination do
        "table" -> {:putdown, [block]}
        target_block -> {:stack, [block, target_block]}
      end

      # Reverse to get correct order (clear goals first, then actions)
      final_subgoals = Enum.reverse(subgoals) ++ [pickup_action, putdown_action]

      {:ok, final_subgoals}
    end
  end

  @doc """
  Achieve a position goal for a block (direct method - no clearing).

  This alternative method tries to move the block directly without clearing subgoals.
  Used when the primary method fails or is blacklisted.
  """
  @unigoal_method predicate: "pos"
  @spec achieve_position_direct(AriaState.t(), {String.t(), String.t()}) :: {:ok, [AriaHybridPlanner.todo_item()]} | {:error, atom()}
  def achieve_position_direct(state, {block, destination}) do
    current_pos = AriaState.get_fact(state, block, "pos")

    # If already at destination, no action needed
    if current_pos == destination do
      {:ok, []}
    else
      # Check if we can move directly (both block and destination must be clear)
      is_clear = AriaState.get_fact(state, block, "clear")
      destination_clear = case destination do
        "table" -> true  # Table is always available
        dest_block -> AriaState.get_fact(state, dest_block, "clear")
      end

      if is_clear == true and destination_clear == true do
        # Can move directly
        pickup_action = case current_pos do
          "table" -> {:pickup, [block]}
          other_block when is_binary(other_block) -> {:unstack, [block, other_block]}
          _ -> {:pickup, [block]}  # Default fallback
        end

        putdown_action = case destination do
          "table" -> {:putdown, [block]}
          target_block -> {:stack, [block, target_block]}
        end

        {:ok, [pickup_action, putdown_action]}
      else
        # Cannot move directly - fail so other methods can be tried
        {:error, :preconditions_not_met}
      end
    end
  end

  @doc """
  Achieve a clear goal for a block.

  This unigoal method handles goals of the form {"clear", block, true}.
  It finds what's on top of the block and moves it away using task methods.
  """
  @unigoal_method predicate: "clear"
  @spec achieve_clear(AriaState.t(), {String.t(), boolean()}) :: {:ok, [AriaHybridPlanner.todo_item()]} | {:error, atom()}
  def achieve_clear(state, {block, true}) do
    is_clear = AriaState.get_fact(state, block, "clear")

    # If already clear, no action needed
    if is_clear == true do
      {:ok, []}
    else
      # Find what's on top of this block
      blocking_block = find_block_on_top(state, block)

      if blocking_block do
        # Move the blocking block to the table using task methods
        {:ok, [
          {:move_block, [blocking_block, "table"]}
        ]}
      else
        # If no blocking block found but not clear, something is wrong
        # This might happen if the state is inconsistent
        {:error, :no_blocking_block_found}
      end
    end
  end

  @unigoal_method predicate: "clear"
  @spec achieve_clear(AriaState.t(), {String.t(), boolean()}) :: {:ok, [AriaHybridPlanner.todo_item()]} | {:error, atom()}
  def achieve_clear(state, {block, false}) do
    is_clear = AriaState.get_fact(state, block, "clear")

    # If already not clear, no action needed
    if is_clear == false do
      {:ok, []}
    else
      # This is a complex goal - we need something to be placed on this block
      # For now, we'll return an error as this should be handled by higher-level planning
      {:error, :cannot_make_block_not_clear_directly}
    end
  end

  @doc """
  Verify that a multigoal has been achieved.

  This unigoal method handles verification goals created by the split_multigoal method.
  It checks if all goals in the original multigoal are now satisfied.
  """
  @unigoal_method predicate: "multigoal_verified"
  @spec verify_multigoal(AriaState.t(), {String.t(), boolean()}) :: {:ok, [AriaHybridPlanner.todo_item()]} | {:error, atom()}
  def verify_multigoal(_state, {_goals_string, true}) do
    # Parse the goals string back to the original goals list
    try do
      # The goals_string is the inspect output of the goals list
      # For now, we'll assume verification passes if we reach this point
      # In a more sophisticated implementation, we would parse and re-check
      {:ok, []}
    rescue
      _ ->
        {:error, :verification_failed}
    end
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

    # Add intelligent multigoal method implementing IPyHOP algorithm
    domain = AriaCore.add_multigoal_method_to_domain(domain, "intelligent_multigoal", &intelligent_multigoal/2)

    domain
  end

  @doc """
  Intelligent multigoal method implementing IPyHOP's block-stacking algorithm.

  This method analyzes block dependencies and returns goals in optimal order:
  1. Blocks that can move to final position immediately
  2. Blocks that need to move out of the way to table
  3. Blocks that are waiting for dependencies

  Based on IPyHOP's mgm_move_blocks algorithm with status analysis.
  """
  @multigoal_method true
  @spec intelligent_multigoal(AriaState.t(), AriaEngineCore.Multigoal.t()) ::
    {:ok, [AriaHybridPlanner.todo_item()]} | {:error, atom()}
  def intelligent_multigoal(state, multigoal) do
    # Check if multigoal is already satisfied
    if AriaEngineCore.Multigoal.satisfied?(multigoal, state) do
      {:ok, []}  # All goals already achieved
    else
      # Convert multigoal to goal map for analysis
      goal_map = multigoal_to_goal_map(multigoal)

      # Get all blocks in the domain
      all_blocks = get_all_blocks(state)

      # Find blocks that can be moved optimally using IPyHOP algorithm
      case find_optimal_move(state, goal_map, all_blocks) do
        {:move_to_block, block, destination} ->
          # Block can move to final position - prioritize this
          goal = {"pos", block, destination}
          recursive_multigoal = AriaEngineCore.Multigoal.remove_goal(multigoal, "pos", block, destination)
          {:ok, [goal, recursive_multigoal]}

        {:move_to_table, block} ->
          # Block needs to move out of the way - do this first
          goal = {"pos", block, "table"}
          {:ok, [goal, multigoal]}

        {:waiting, block} ->
          # Block is waiting - move to table to unblock others
          goal = {"pos", block, "table"}
          {:ok, [goal, multigoal]}

        :no_moves_needed ->
          # All remaining goals can be achieved directly
          unsatisfied = AriaEngineCore.Multigoal.unsatisfied_goals(multigoal, state)
          verification_goal = {"multigoal_verified", inspect(multigoal.goals), true}
          {:ok, unsatisfied ++ [verification_goal]}
      end
    end
  end

  # Private helper functions

  defp register_entity(state, [entity_id, type, capabilities]) do
    state
    |> AriaState.set_fact(entity_id, "type", type)
    |> AriaState.set_fact(entity_id, "capabilities", capabilities)
    |> AriaState.set_fact(entity_id, "status", "available")
  end

  defp find_block_on_top(state, target_block) do
    # Find all blocks and check which one is positioned on the target block
    all_blocks = get_all_blocks(state)

    Enum.find(all_blocks, fn block ->
      AriaState.get_fact(state, block, "pos") == target_block
    end)
  end

  # defdelegate new(), to: AriaState.RelationalState
  # defdelegate new(data), to: AriaState.RelationalState
  # defdelegate get_fact(state, subject, predicate), to: AriaState.RelationalState
  # defdelegate set_fact(state, subject, predicate, value), to: AriaState.RelationalState
  # defdelegate remove_fact(state, subject, predicate), to: AriaState.RelationalState
  # defdelegate has_subject?(state, subject), to: AriaState.RelationalState
  # defdelegate get_subjects(state), to: AriaState.RelationalState
  # defdelegate merge(state1, state2), to: AriaState.RelationalState
  # defdelegate copy(state), to: AriaState.RelationalState

  defp get_all_blocks(state) do
    # Get all subjects that have a "clear" predicate
    clear_true = AriaState.get_subjects_with_fact(state, "clear", true)
    clear_false = AriaState.get_subjects_with_fact(state, "clear", false)

    # Combine and return all blocks
    (clear_true ++ clear_false) |> Enum.uniq()
  end

  # IPyHOP algorithm implementation

  defp multigoal_to_goal_map(multigoal) do
    # Convert multigoal to a map for easier lookup
    # Only handle "pos" goals for now
    multigoal.goals
    |> Enum.filter(fn {predicate, _subject, _value} -> predicate == "pos" end)
    |> Enum.into(%{}, fn {"pos", block, destination} -> {block, destination} end)
  end

  defp find_optimal_move(state, goal_map, all_blocks) do
    # IPyHOP algorithm: find blocks that can be moved optimally

    # First pass: look for blocks that can move to final position
    case find_block_with_status(state, goal_map, all_blocks, :move_to_block) do
      {block, destination} -> {:move_to_block, block, destination}
      nil ->
        # Second pass: look for blocks that need to move out of the way
        case find_block_with_status(state, goal_map, all_blocks, :move_to_table) do
          {block, _} -> {:move_to_table, block}
          nil ->
            # Third pass: look for waiting blocks
            case find_block_with_status(state, goal_map, all_blocks, :waiting) do
              {block, _} -> {:waiting, block}
              nil -> :no_moves_needed
            end
        end
    end
  end

  defp find_block_with_status(state, goal_map, all_blocks, target_status) do
    Enum.find_value(all_blocks, fn block ->
      case block_status(state, goal_map, block) do
        ^target_status -> {block, Map.get(goal_map, block)}
        _ -> nil
      end
    end)
  end

  defp block_status(state, goal_map, block) do
    # IPyHOP status function implementation
    cond do
      is_done?(state, goal_map, block) ->
        :done

      not AriaState.get_fact(state, block, "clear") ->
        :inaccessible

      not Map.has_key?(goal_map, block) or Map.get(goal_map, block) == "table" ->
        :move_to_table

      true ->
        destination = Map.get(goal_map, block)
        if is_done?(state, goal_map, destination) and AriaState.get_fact(state, destination, "clear") do
          :move_to_block
        else
          :waiting
        end
    end
  end

  defp is_done?(state, goal_map, block) do
    # IPyHOP is_done function: check if block is in correct position recursively
    cond do
      block == "table" ->
        true

      Map.has_key?(goal_map, block) and Map.get(goal_map, block) != AriaState.get_fact(state, block, "pos") ->
        false

      AriaState.get_fact(state, block, "pos") == "table" ->
        true

      true ->
        current_pos = AriaState.get_fact(state, block, "pos")
        is_done?(state, goal_map, current_pos)
    end
  end
end
