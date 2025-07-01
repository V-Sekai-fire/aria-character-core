# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

# Stub modules for aria_engine_core to prevent compilation warnings
# Note: AriaCore and AriaHybridPlanner.Core stubs removed as real modules now exist

unless Code.ensure_loaded?(AriaState.RelationalState) do
  defmodule AriaState.RelationalState do
    @moduledoc "Stub module for AriaState.RelationalState"

    def has_subject?(_state, _predicate, _subject), do: false
    def remove_fact(state, _predicate, _subject), do: state
  end
end
