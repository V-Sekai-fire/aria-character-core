# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaBlocksWorld.DomainRegistrationDebugTest do
  @moduledoc """
  Debug test to investigate domain registration and method lookup issues.

  This test specifically investigates why unigoal methods can't decompose
  task_methods returned in their todo_list output.
  """

  use ExUnit.Case
  require Logger

  describe "domain registration debugging" do
    test "verify domain creation and method registration" do
      Logger.debug("=== DOMAIN REGISTRATION DEBUG TEST ===")

      # Create domain with debug logging
      domain = AriaBlocksWorld.Domain.create()

      # Verify domain structure
      assert %AriaCore.Domain{} = domain
      assert domain.name == :blocks_world

      Logger.debug("Domain created successfully")
      Logger.debug("Domain actions: #{inspect(Map.keys(domain.actions))}")
      Logger.debug("Domain task_methods: #{inspect(Map.keys(domain.task_methods))}")
      Logger.debug("Domain unigoal_methods: #{inspect(Map.keys(domain.unigoal_methods))}")

      # Test specific method lookups that are failing
      Logger.debug("\n=== TESTING METHOD LOOKUPS ===")

      # Test validate_move lookup
      validate_move_methods = AriaCore.get_task_methods_from_domain(domain, :validate_move)
      Logger.debug("validate_move methods found: #{inspect(validate_move_methods)}")

      # Test move_block lookup
      move_block_methods = AriaCore.get_task_methods_from_domain(domain, :move_block)
      Logger.debug("move_block methods found: #{inspect(move_block_methods)}")

      # Test what's actually in the task_methods map
      Logger.debug("\n=== TASK METHODS MAP CONTENTS ===")
      Enum.each(domain.task_methods, fn {key, value} ->
        Logger.debug("Task method '#{key}': #{inspect(value)}")
      end)

      # Verify the methods we expect are registered
      assert Map.has_key?(domain.task_methods, :move_block), "move_block should be registered"
      assert Map.has_key?(domain.task_methods, :validate_move), "validate_move should be registered"
    end

    test "test unigoal method execution and task method decomposition" do
      Logger.debug("\n=== TESTING UNIGOAL METHOD EXECUTION ===")

      domain = AriaBlocksWorld.Domain.create()

      # Create test state with blocks
      state = AriaHybridPlanner.new_state()
      |> AriaHybridPlanner.set_fact("pos", "A", "B")
      |> AriaHybridPlanner.set_fact("pos", "B", "table")
      |> AriaHybridPlanner.set_fact("clear", "A", true)
      |> AriaHybridPlanner.set_fact("clear", "B", false)
      |> AriaHybridPlanner.set_fact("holding", "hand", false)

      Logger.debug("Test state created: A on B, B on table, A is clear, B is not clear")

      # Test achieve_clear unigoal method
      Logger.debug("Testing achieve_clear(B, true) - should return task methods")

      case AriaBlocksWorld.Domain.achieve_clear(state, {"B", true}) do
        {:ok, todo_list} ->
          Logger.debug("achieve_clear returned todo_list: #{inspect(todo_list)}")

          # Verify the todo_list contains task methods
          Enum.each(todo_list, fn todo_item ->
            case todo_item do
              {:validate_move, args} ->
                Logger.debug("Found validate_move task method with args: #{inspect(args)}")
              {:move_block, args} ->
                Logger.debug("Found move_block task method with args: #{inspect(args)}")
              other ->
                Logger.debug("Found other todo item: #{inspect(other)}")
            end
          end)

        {:error, reason} ->
          Logger.debug("achieve_clear failed: #{reason}")
          flunk("achieve_clear should succeed")
      end
    end

    test "test task method execution directly" do
      Logger.debug("\n=== TESTING TASK METHOD EXECUTION DIRECTLY ===")

      domain = AriaBlocksWorld.Domain.create()

      # Create test state
      state = AriaHybridPlanner.new_state()
      |> AriaHybridPlanner.set_fact("pos", "A", "table")
      |> AriaHybridPlanner.set_fact("clear", "A", true)
      |> AriaHybridPlanner.set_fact("holding", "hand", false)

      # Test move_block task method directly
      Logger.debug("Testing move_block(A, B) directly")

      case AriaBlocksWorld.Domain.move_block(state, ["A", "B"]) do
        {:ok, actions} ->
          Logger.debug("move_block returned actions: #{inspect(actions)}")
        {:error, reason} ->
          Logger.debug("move_block failed: #{reason}")
      end

      # Test validate_move task method directly
      Logger.debug("Testing validate_move(A, B) directly")

      case AriaBlocksWorld.Domain.validate_move(state, ["A", "B"]) do
        {:ok, actions} ->
          Logger.debug("validate_move returned actions: #{inspect(actions)}")
        {:error, reason} ->
          Logger.debug("validate_move failed: #{reason}")
      end
    end

    test "test AriaCore method lookup functions" do
      Logger.debug("\n=== TESTING ARIACORE METHOD LOOKUP FUNCTIONS ===")

      domain = AriaBlocksWorld.Domain.create()

      # Test the specific lookup functions used by the planner
      Logger.debug("Testing AriaCore.get_task_methods_from_domain")

      # Test various task name formats
      test_cases = [
        :validate_move,
        "validate_move",
        :move_block,
        "move_block",
        :take_method,
        "take_method"
      ]

      Enum.each(test_cases, fn task_name ->
        methods = AriaCore.get_task_methods_from_domain(domain, task_name)
        Logger.debug("get_task_methods_from_domain(#{inspect(task_name)}): #{inspect(methods)}")
      end)
    end
  end
end
