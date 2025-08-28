# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaStateTest do
  use ExUnit.Case
  doctest AriaState

  alias AriaState.ObjectState

  test "main module delegates to ObjectState" do
    state = AriaState.new()
    |> AriaState.set_fact("chef_1", "status", "cooking")

    assert AriaState.get_fact(state, "chef_1", "status") == "cooking"
  end

  test "converts between state formats" do
    object_state = AriaState.ObjectState.new()
    |> AriaState.ObjectState.set_fact("chef_1", "status", "cooking")

    relational_state = AriaState.convert(object_state)
    assert %AriaState.RelationalState{} = relational_state

    converted_back = AriaState.convert(relational_state)
    assert %AriaState.ObjectState{} = converted_back
    assert AriaState.ObjectState.get_fact(converted_back, "chef_1", "status") == "cooking"
  end
end
