defmodule Plan.SimpleExecutorTest do
  use ExUnit.Case, async: true
  doctest Plan.SimpleExecutor

  alias Plan.SimpleExecutor
  alias AriaEngineCore.Domain
  alias AriaState.RelationalState, as: State

  setup do
    # Setup a basic domain and state for testing
    domain = Domain.new("test_domain")
    state = State.new()

    {:ok, %{domain: domain, state: state}}
  end

  test "execute a simple action", %{domain: domain, state: state} do
    # Define a simple action
    action_name = :test_action
    action_fn = fn s, _args -> {:ok, State.add_fact(s, "test", "fact", "value")} end
    domain = Domain.add_action(domain, action_name, action_fn)

    plan = [{action_name, []}]
    {:ok, new_state, trace} = SimpleExecutor.execute(domain, state, plan)

    assert State.get_fact(new_state, "test", "fact") == "value"
    assert length(trace) == 2
    assert List.last(trace) == {{action_name, []}, new_state}
  end
end
