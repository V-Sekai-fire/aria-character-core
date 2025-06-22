# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngine do
  @moduledoc """
  Main AriaEngine module providing utility functions.

  This module contains utility functions that are used across the AriaEngine system.
  """

  # Simple aliases for core modules
  alias AriaEngine.StateV2
  alias AriaEngine.Multigoal
  alias TimelineGraph

  @type domain :: map()
  @type state :: StateV2.t()
  @type todos :: list()
  @type plan :: term()
  @type opts :: keyword()

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
