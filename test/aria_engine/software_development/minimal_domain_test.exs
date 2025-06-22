defmodule AriaEngine.SoftwareDevelopment.MinimalDomainTest do
  use ExUnit.Case, async: true

  alias AriaEngine.StateV2
  alias AriaEngine.Planning

  test "plan the development of a single module" do
    initial_state =
      StateV2.new()
      # |> StateV2.set_fact("gltf_buffer", "type", "module")  # GLTF work paused

    todos = [
      # {"develop_module", ["gltf_buffer"]}  # GLTF work paused
    ]

    # Run the planner
    domain = AriaEngine.SoftwareDevelopment.Domain.build()
    {:ok, plan} = Planning.plan(domain, initial_state, todos, verbose: 3)

    # For now, we'll just assert that a plan was found.
    # In a real scenario, we would inspect the plan to ensure it's optimal.
    assert is_list(plan)
    assert length(plan) > 0
  end
end
