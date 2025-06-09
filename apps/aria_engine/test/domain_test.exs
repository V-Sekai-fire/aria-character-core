# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngine.DomainTest do
  use ExUnit.Case
  doctest AriaEngine.Domain

  alias AriaEngine.Domain

  describe "Domain and action management" do
    test "creates domain and adds actions" do
      domain = AriaEngine.create_domain("test")
      |> AriaEngine.add_action(:move, fn state, [_from, to] ->
        AriaEngine.set_fact(state, "location", "player", to)
      end)
      |> AriaEngine.add_action(:pickup, fn state, [item] ->
        AriaEngine.set_fact(state, "has", "player", item)
      end)

      summary = AriaEngine.domain_summary(domain)
      assert summary.name == "test"
      assert :move in summary.actions
      assert :pickup in summary.actions
    end

    test "executes actions correctly" do
      move_action = fn state, [_from, to] ->
        state
        |> AriaEngine.set_fact("location", "player", to)
      end

      domain = AriaEngine.create_domain("test")
      |> AriaEngine.add_action(:move, move_action)

      initial_state = AriaEngine.create_state()
      |> AriaEngine.set_fact("location", "player", "room1")

      result_state = Domain.execute_action(domain, initial_state, :move, ["room1", "room2"])

      assert AriaEngine.get_fact(result_state, "location", "player") == "room2"
    end
  end
end
