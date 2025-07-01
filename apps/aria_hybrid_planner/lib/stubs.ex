# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

# Stub modules for aria_hybrid_planner to prevent compilation warnings

unless Code.ensure_loaded?(AriaCore) do
  defmodule AriaCore do
    @moduledoc "Stub module for AriaCore"

    def execute_action(_domain, _state, _action_name, _args), do: {:ok, %{}}
  end
end
