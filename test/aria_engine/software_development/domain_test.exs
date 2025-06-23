defmodule AriaEngine.SoftwareDevelopment.DomainTest do
  use ExUnit.Case, async: true

  alias State
  alias AriaEngine.Planning

  test "plan the development of a single module" do
    initial_state =
      State.new()
      # |> State.set_fact("type", "gltf_buffer", "module")  # GLTF work paused

    todos = [
      # {"develop_module", ["gltf_buffer"]}  # GLTF work paused
    ]

    # Run the planner
    domain = AriaEngine.Domain.from_module(AriaEngine.SoftwareDevelopment.Domain)
    {:ok, plan} = Planning.plan(domain, initial_state, todos, [])

    # For now, we'll just assert that a plan was found.
    # In a real scenario, we would inspect the plan to ensure it's optimal.
    assert is_list(plan)
    assert length(plan) > 0
  end
end
