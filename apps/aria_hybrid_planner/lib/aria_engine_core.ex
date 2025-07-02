# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngineCore do
  @moduledoc """
  Compatibility module for AriaEngineCore.

  This module has been merged into AriaHybridPlanner. All functions are now
  delegated to AriaHybridPlanner for backward compatibility.

  ## Migration Notice

  AriaEngineCore has been consolidated into AriaHybridPlanner. Please update
  your code to use AriaHybridPlanner directly:

      # Old (still works but deprecated)
      AriaEngineCore.plan(domain, state, goals)

      # New (recommended)
      AriaHybridPlanner.plan(domain, state, goals)

  ## Compatibility

  All existing AriaEngineCore functions continue to work through delegation
  to AriaHybridPlanner, ensuring no breaking changes.
  """

  # Type aliases for backward compatibility
  @type domain :: AriaHybridPlanner.domain()
  @type state :: AriaHybridPlanner.state()
  @type todo_item :: AriaHybridPlanner.todo_item()
  @type solution_tree :: AriaHybridPlanner.solution_tree()

  # Delegate all functions to AriaHybridPlanner for backward compatibility
  defdelegate plan(domain, state, goals), to: AriaHybridPlanner
  defdelegate run_lazy(domain, state, goals), to: AriaHybridPlanner
  defdelegate run_lazy_tree(domain, state, solution_tree), to: AriaHybridPlanner

  # State management functions
  defdelegate new_state(), to: AriaHybridPlanner
  defdelegate new_state(data), to: AriaHybridPlanner
  defdelegate get_fact(state, predicate, subject), to: AriaHybridPlanner
  defdelegate set_fact(state, predicate, subject, value), to: AriaHybridPlanner
  defdelegate has_subject?(state, predicate, subject), to: AriaHybridPlanner
  defdelegate remove_fact(state, predicate, subject), to: AriaHybridPlanner
  defdelegate get_subjects_with_fact(state, predicate, value), to: AriaHybridPlanner

  # Type helper functions
  defdelegate domain(), to: AriaHybridPlanner
  defdelegate state(), to: AriaHybridPlanner
  defdelegate todo_item(), to: AriaHybridPlanner
  defdelegate solution_tree(), to: AriaHybridPlanner

  # Version function
  defdelegate version(), to: AriaHybridPlanner

  @doc """
  Returns a deprecation warning for AriaEngineCore usage.
  """
  def deprecation_notice do
    """
    AriaEngineCore has been merged into AriaHybridPlanner.
    Please update your code to use AriaHybridPlanner directly.

    This compatibility module will be removed in a future version.
    """
  end
end
