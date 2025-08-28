# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaHybridPlannerTest do
  use ExUnit.Case
  doctest AriaHybridPlanner

  test "module version returns string" do
    version = AriaHybridPlanner.version()
    assert is_binary(version)
    assert version != ""
  end

  test "module loads successfully" do
    assert Code.ensure_loaded?(AriaHybridPlanner)
  end
end
