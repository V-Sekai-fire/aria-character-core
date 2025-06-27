# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaHybridPlanner do
  @moduledoc """
  Hybrid planning coordination system providing strategy-based planning with temporal reasoning integration.
  """

  @spec version() :: String.t()
  @doc """
  Returns the version of the AriaHybridPlanner application.
  """
  def version do
    Application.spec(:aria_hybrid_planner, :vsn) |> to_string()
  end
end