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
