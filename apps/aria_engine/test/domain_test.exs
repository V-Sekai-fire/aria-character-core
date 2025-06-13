# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngine.DomainTest do
  use ExUnit.Case
  doctest AriaEngine.Domain

  alias AriaEngine.{Domain, TestDomains}

  describe "Domain and action management" do
    test "creates domain and adds actions" do
      domain = TestDomains.build_test_domain()

      summary = AriaEngine.domain_summary(domain)
      assert summary.name == "test"
      assert :move in summary.actions
      assert :pickup in summary.actions
    end

    test "executes actions correctly" do
      domain = TestDomains.build_test_domain()

      initial_state = AriaEngine.create_state()
      |> AriaEngine.set_fact("location", "player", "room1")

      result_state = Domain.execute_action(domain, initial_state, :move, ["room1", "room2"])

      case result_state do
        {:ok, final_state} ->
          final_state = final_state
          assert AriaEngine.get_fact(final_state, "location", "player") == "room2"
        false ->
          flunk("Action execution failed")
      end
    end
  end
end
