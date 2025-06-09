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

      assert AriaEngine.get_fact(result_state, "location", "player") == "room2"
    end
  end
end
