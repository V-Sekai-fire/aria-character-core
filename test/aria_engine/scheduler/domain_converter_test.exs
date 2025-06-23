# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngine.Scheduler.DomainConverterTest do
  use ExUnit.Case, async: true

  alias AriaEngine.Domain
  alias State

  describe "domain action creation for activities" do
    test "creates action function that works with StateV2" do
      domain = Domain.new("test_domain")

      action_fn = fn state, _args ->
        State.set_fact(state, "test_activity", "completed", "true")
      end

      domain_with_action = Domain.add_action(domain, :test_activity, action_fn)

      retrieved_action = Domain.get_action(domain_with_action, :test_activity)

      assert is_function(retrieved_action, 2)

      initial_state = State.new()
      result_state = retrieved_action.(initial_state, [])

      assert %StateV2{} = result_state

      assert State.get_fact(result_state, "test_activity", "completed") == "true"
    end
  end
end
