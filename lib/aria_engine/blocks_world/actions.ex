# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngine.BlocksWorld.Actions do
  def pickup(state, _args), do: {:ok, state}
  def putdown(state, _args), do: {:ok, state}
  def stack(state, _args), do: {:ok, state}
  def unstack(state, _args), do: {:ok, state}
end