# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngine do
  @moduledoc """
  Main AriaEngine module providing utility functions.
  
  This module contains utility functions that are used across the AriaEngine system.
  """

  # Simple aliases for core modules
  alias AriaEngine.StateV2
  alias TimelineGraph

  @type domain :: map()
  @type state :: StateV2.t()
  @type todos :: list()
  @type plan :: term()
  @type opts :: keyword()

  @doc """
  Basic planning function that delegates to the Planner module.
  """
  @spec plan(domain(), state(), todos(), opts()) :: {:ok, plan()} | {:error, String.t()}
  defdelegate plan(domain, state, todos, opts \\ []), to: Planner

  @doc """
  Basic plan execution function that delegates to the Planner module.
  """
  @spec execute_plan(domain(), state(), plan()) :: {:ok, state()} | {:error, String.t()}
  defdelegate execute_plan(domain, state, plan), to: Planner, as: :execute

  @doc """
  Creates a new empty multigoal structure.
  """
  @spec create_multigoal() :: Multigoal.t()
  def create_multigoal do
    Multigoal.new()
  end

  @doc """
  Creates a new empty state using StateV2.
  """
  @spec create_state() :: StateV2.t()
  def create_state do
    StateV2.new()
  end
end
