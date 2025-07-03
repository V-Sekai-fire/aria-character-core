# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaBlocksWorld.RegistrationDebugTest do
  @moduledoc """
  Debug test to investigate why validate_move and move_block task methods aren't being found.
  """

  use ExUnit.Case
  require Logger

  alias AriaBlocksWorld.Domain

  test "debug domain registration - check what task methods are registered" do
    # Create the domain
    domain = Domain.create()

    # Check what's actually registered
    Logger.debug("Domain task methods: #{inspect(domain.task_methods)}")
    Logger.debug("Domain actions: #{inspect(domain.actions)}")
    Logger.debug("Domain unigoal methods: #{inspect(domain.unigoal_methods)}")

    # Check if our specific methods are registered
    validate_move_registered = Map.has_key?(domain.task_methods, :validate_move)
    move_block_registered = Map.has_key?(domain.task_methods, :move_block)

    Logger.debug("validate_move registered: #{validate_move_registered}")
    Logger.debug("move_block registered: #{move_block_registered}")

    # List all registered task method names
    task_method_names = Map.keys(domain.task_methods)
    Logger.debug("All registered task method names: #{inspect(task_method_names)}")

    # Test if the functions exist and are callable
    try do
      # Test with dummy state
      state = AriaHybridPlanner.new_state()

      # Try calling the functions directly
      validate_result = Domain.validate_move(state, ["b", "c"])
      move_result = Domain.move_block(state, ["b", "c"])

      Logger.debug("Direct validate_move call result: #{inspect(validate_result)}")
      Logger.debug("Direct move_block call result: #{inspect(move_result)}")

    rescue
      error ->
        Logger.debug("Error calling functions directly: #{inspect(error)}")
    end

    # The test should fail if our methods aren't registered
    assert validate_move_registered, "validate_move should be registered as a task method"
    assert move_block_registered, "move_block should be registered as a task method"
  end

  test "debug attribute detection - check if attributes are being found" do
    # Check what attributes AriaCore finds on the Domain module
    try do
      # This might not be a public function, but let's see what we can discover
      module_attributes = Domain.__info__(:attributes)
      Logger.debug("Domain module attributes: #{inspect(module_attributes)}")

      # Check if the functions have the right attributes
      functions = Domain.__info__(:functions)
      Logger.debug("Domain functions: #{inspect(functions)}")

    rescue
      error ->
        Logger.debug("Error checking module info: #{inspect(error)}")
    end
  end
end
