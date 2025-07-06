# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaBlocksWorld.PlanValidationTest do
  @moduledoc """
  Test suite to validate specific plan sequences for legality.
  """

  use ExUnit.Case, async: true
  require Logger

  describe "plan sequence validation" do
    test "validate left sequence: optimal plan" do
      # Initial state: a on b, b on table, c on table
      initial_state = AriaState.new(%{
        pos: %{"a" => "b", "b" => "table", "c" => "table"},
        clear: %{"a" => true, "b" => false, "c" => true},
        holding: %{"hand" => false}
      })

      # Left sequence (optimal)
      left_sequence = [
        {:unstack, ["a", "b"]},
        {:putdown, ["a"]},
        {:pickup, ["b"]},
        {:stack, ["b", "a"]},
        {:pickup, ["c"]},
        {:stack, ["c", "b"]}
      ]

      result = execute_sequence(initial_state, left_sequence)

      case result do
        {:ok, final_state} ->
          # Check if final state matches goal: c on b, b on a, a on table
          assert AriaState.get_fact(final_state, "pos", "c") == "b"
          assert AriaState.get_fact(final_state, "pos", "b") == "a"
          assert AriaState.get_fact(final_state, "pos", "a") == "table"
          Logger.info("Left sequence is LEGAL and achieves the goal")
        {:error, {action, reason}} ->
          Logger.error("Left sequence is ILLEGAL: Action #{inspect(action)} failed with reason: #{reason}")
          flunk("Left sequence failed at action #{inspect(action)}: #{reason}")
      end
    end

    test "validate right sequence: longer plan with repeated actions" do
      # Initial state: a on b, b on table, c on table
      initial_state = AriaState.new(%{
        pos: %{"a" => "b", "b" => "table", "c" => "table"},
        clear: %{"a" => true, "b" => false, "c" => true},
        holding: %{"hand" => false}
      })

      # Right sequence (longer with repeated actions)
      right_sequence = [
        {:unstack, ["a", "b"]},
        {:putdown, ["a"]},
        {:pickup, ["c"]},
        {:stack, ["c", "b"]},
        {:unstack, ["a", "b"]},  # This should fail - a is not on b anymore
        {:putdown, ["a"]},
        {:pickup, ["b"]},
        {:stack, ["b", "a"]},
        {:unstack, ["a", "b"]},
        {:putdown, ["a"]}
      ]

      result = execute_sequence(initial_state, right_sequence)

      case result do
        {:ok, final_state} ->
          Logger.info("Right sequence is LEGAL")
          # Check final state
          pos_facts = %{
            "a" => AriaState.get_fact(final_state, "pos", "a"),
            "b" => AriaState.get_fact(final_state, "pos", "b"),
            "c" => AriaState.get_fact(final_state, "pos", "c")
          }
          Logger.info("Final state: pos=#{inspect(pos_facts)}")
        {:error, {action, reason}} ->
          Logger.info("Right sequence is ILLEGAL: Action #{inspect(action)} failed with reason: #{reason}")
          # This is expected - the sequence should fail
      end
    end
  end

  # Helper function to execute a sequence of actions
  defp execute_sequence(initial_state, actions) do
    Enum.reduce_while(actions, {:ok, initial_state}, fn action, {:ok, current_state} ->
      case execute_action(current_state, action) do
        {:ok, new_state} ->
          Logger.debug("Action #{inspect(action)} succeeded")
          {:cont, {:ok, new_state}}
        {:error, reason} ->
          Logger.debug("Action #{inspect(action)} failed: #{reason}")
          {:halt, {:error, {action, reason}}}
      end
    end)
  end

  # Helper function to execute a single action directly
  defp execute_action(state, {action_name, args}) do
    case action_name do
      :unstack -> AriaBlocksWorld.Domain.unstack(state, args)
      :putdown -> AriaBlocksWorld.Domain.putdown(state, args)
      :pickup -> AriaBlocksWorld.Domain.pickup(state, args)
      :stack -> AriaBlocksWorld.Domain.stack(state, args)
      _ -> {:error, :unknown_action}
    end
  end
end
