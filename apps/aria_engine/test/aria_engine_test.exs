# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngineTest do
  use ExUnit.Case
  doctest AriaEngine

  # This test module now serves as a documentation test entry point.
  # Specific functionality tests have been reorganized into focused modules:
  # - state_test.exs: State management functionality
  # - domain_test.exs: Domain and action management
  # - goal_test.exs: Goal management and multigoals
  # - planning_test.exs: Basic planning and task decomposition
  # - logistics_test.exs: Logistics domain tests
  # - test_blocks_world.exs: Blocks world domain tests
  # - test_gtpyhop.exs: GTPyhop algorithm tests

  test "module loads correctly" do
    assert AriaEngine.create_state() != nil
  end
end
