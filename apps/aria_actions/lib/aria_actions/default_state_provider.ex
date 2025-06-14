# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaActions.DefaultStateProvider do
  @moduledoc """
  Default state provider that uses AriaEngine.State.

  This is the default implementation that bridges AriaActions to AriaEngine.State
  while maintaining the decoupled interface.
  """

  @behaviour AriaActions.StateProvider

  alias AriaEngine.State

  @impl true
  def get_object(state, key, object) do
    State.get_object(state, key, object)
  end

  @impl true
  def set_object(state, key, object, value) do
    State.set_object(state, key, object, value)
  end

  @impl true
  def new do
    State.new()
  end
end
