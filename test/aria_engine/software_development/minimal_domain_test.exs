defmodule AriaEngine.SoftwareDevelopment.MinimalDomainTest do
  use ExUnit.Case, async: true
  alias State
  alias AriaEngine.Planning

  test "plan the development of a single module" do
    initial_state = State.new()
    todos = []
    domain = AriaEngine.SoftwareDevelopment.Domain.build()
    {:ok, plan} = Planning.plan(domain, initial_state, todos, verbose: 3)
    assert %{nodes: _, root_id: _} = plan
    assert map_size(plan.nodes) > 0
  end
end
