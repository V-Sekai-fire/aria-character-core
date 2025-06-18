# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngine do
  @moduledoc """
  Main AriaEngine module providing utility functions.
  
  This module contains utility functions that are used across the AriaEngine system.
  """

  # Simple aliases for core modules
  alias StateV2
  alias TimelineGraph

  @doc """
  Basic planning function that delegates to the Planner module.
  """
  defdelegate plan(domain, state, todos, opts \\ []), to: Planner

  @doc """
  Basic plan execution function that delegates to the Planner module.
  """
  defdelegate execute_plan(domain, state, plan), to: Planner, as: :execute

  @doc """
  Creates a new empty multigoal structure.
  """
  def create_multigoal do
    Multigoal.new()
  end

  @doc """
  Creates a new empty state using StateV2.
  """
  def create_state do
    StateV2.new()
  end
end
