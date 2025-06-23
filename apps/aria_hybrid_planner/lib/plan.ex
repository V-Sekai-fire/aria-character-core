# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule Plan do
  @moduledoc """
  Main Plan module that provides the public API for planning operations.
  """

  # Delegate core planning functions to Plan.Core
  defdelegate plan(domain, state, todos, opts \\ []), to: Plan.Core
  defdelegate ipyhop(domain, state, solution_tree, opts), to: Plan.Core

  # Delegate execution functions to Plan.Execution
  defdelegate run_lazy_refineahead(domain, state, plan, opts \\ []), to: Plan.Execution

  # Delegate replanning functions to Plan.Backtracking
  defdelegate replan(domain, state, solution_tree, fail_node_id, opts \\ []), to: Plan.Backtracking
end
