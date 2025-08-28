# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaCore.ActionAttributesTest do
  use ExUnit.Case, async: true
  doctest AriaCore.ActionAttributes

  alias AriaCore.Domain

  defmodule TestDomain do
    use AriaCore.Domain

    @action duration: "PT1H", requires_entities: [%{type: "agent", capabilities: [:cooking]}]
    def cook_meal(state, [meal_id]) do
      AriaState.set_fact(state, "meal_status", meal_id, "ready")
    end

    @command true
    def validate_oven(state, []) do
      {:ok, state}
    end

    @task_method true
    def prepare_meal(_state, [meal_id]) do
      {:ok, [{:cook_meal, [meal_id]}]}
    end

    @unigoal_method predicate: "meal_status"
    def achieve_meal_status(_state, {subject, _value}) do
      {:ok, [{:cook_meal, [subject]}]}
    end

    @multigoal_method true
    def optimize_goals(_state, multigoal) do
      {:ok, multigoal}
    end

    @multitodo_method true
    def optimize_todos(_state, todo_list) do
      {:ok, todo_list}
    end
  end

  test "create_domain_from_module correctly processes all action attributes" do
    domain = AriaCore.create_domain_from_module(TestDomain)

    # Verify action
    assert %{cook_meal: action_spec} = domain.actions
    assert action_spec.duration == {:fixed, 3600}
    assert action_spec.entity_requirements == [%{type: "agent", capabilities: [:cooking], constraints: %{}, properties: %{}}]

    initial_state = AriaState.new()
    result_state = action_spec.action_fn.(initial_state, ["pasta"])

    # Verify the action correctly set the fact (ignore timestamp differences in metadata)
    assert AriaState.get_fact(result_state, "meal_status", "pasta") == {:ok, "ready"}
    assert map_size(result_state.facts) == 1

    # Verify command
    assert validate_oven_spec = Domain.get_action(domain, :validate_oven)
    assert validate_oven_spec.command == true

    command_initial_state = AriaState.new()
    assert validate_oven_spec.action_fn.(command_initial_state, []) == {:ok, command_initial_state}

    # Verify task method
    assert method_spec = Domain.get_method(domain, :prepare_meal)
    task_state = AriaState.new()
    assert method_spec.decomposition_fn.(task_state, ["pasta"]) == {:ok, [{:cook_meal, ["pasta"]}]}

    # Verify unigoal method
    assert unigoal_spec = Domain.get_unigoal_method(domain, :achieve_meal_status)
    assert unigoal_spec.predicate == "meal_status"
    unigoal_state = AriaState.new()
    assert unigoal_spec.goal_fn.(unigoal_state, {"pasta", "ready"}) == {:ok, [{:cook_meal, ["pasta"]}]}

    # Verify multigoal method
    assert multigoal_spec = Domain.get_method(domain, :optimize_goals)
    multigoal_state = AriaState.new()
    assert multigoal_spec.multigoal_fn.(multigoal_state, :multigoal_data) == {:ok, :multigoal_data}

    # Verify multitodo method
    assert multitodo_spec = Domain.get_method(domain, :optimize_todos)
    multitodo_state = AriaState.new()
    assert multitodo_spec.multitodo_fn.(multitodo_state, [:todo1, :todo2]) == {:ok, [:todo1, :todo2]}
  end
end
