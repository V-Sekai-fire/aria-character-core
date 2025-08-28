# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaCoreComplianceTest do
  use ExUnit.Case, async: true
  doctest AriaCore

  alias AriaCore
  alias AriaCore.Domain

  # Define a test domain module for compliance testing
  defmodule TestDomain do
    use AriaCore.Domain

    # Pattern 1: Instant action, anytime
    @action true
    @spec instant_action(AriaState.t(), []) :: {:ok, AriaState.t()} | {:error, atom()}
    def instant_action(state, []), do: {:ok, state}

    # Pattern 2: Floating duration
    @action duration: "PT2H"
    @spec floating_duration_action(AriaState.t(), []) :: {:ok, AriaState.t()} | {:error, atom()}
    def floating_duration_action(state, []), do: {:ok, state}

    # Pattern 3: Deadline constraint (not directly supported by @action, but can be inferred)
    # This will be tested by checking if the planner can infer the start time.
    @action end: "2025-06-22T14:00:00-07:00"
    @spec deadline_action(AriaState.t(), []) :: {:ok, AriaState.t()} | {:error, atom()}
    def deadline_action(state, []), do: {:ok, state}

    # Pattern 4: Calculated start (end - duration)
    @action end: "2025-06-22T14:00:00-07:00", duration: "PT2H"
    @spec calculated_start_action(AriaState.t(), []) :: {:ok, AriaState.t()} | {:error, atom()}
    def calculated_start_action(state, []), do: {:ok, state}

    # Pattern 5: Open start (not directly supported by @action, but can be inferred)
    # This will be tested by checking if the planner can infer the end time.
    @action start: "2025-06-22T10:00:00-07:00"
    @spec open_start_action(AriaState.t(), []) :: {:ok, AriaState.t()} | {:error, atom()}
    def open_start_action(state, []), do: {:ok, state}

    # Pattern 6: Calculated end (start + duration)
    @action start: "2025-06-22T10:00:00-07:00", duration: "PT2H"
    @spec calculated_end_action(AriaState.t(), []) :: {:ok, AriaState.t()} | {:error, atom()}
    def calculated_end_action(state, []), do: {:ok, state}

    # Pattern 7: Fixed interval
    @action start: "2025-06-22T10:00:00-07:00", end: "2025-06-22T12:00:00-07:00"
    @spec fixed_interval_action(AriaState.t(), []) :: {:ok, AriaState.t()} | {:error, atom()}
    def fixed_interval_action(state, []), do: {:ok, state}

    # Pattern 8: Constraint validation (start + duration = end)
    @action start: "2025-06-22T10:00:00-07:00", end: "2025-06-22T12:00:00-07:00", duration: "PT2H"
    @spec constraint_validation_action(AriaState.t(), []) :: {:ok, AriaState.t()} | {:error, atom()}
    def constraint_validation_action(state, []), do: {:ok, state}

    # Action with entity requirements
    @action requires_entities: [%{type: "agent", capabilities: [:cooking]}]
    @spec cook_meal(AriaState.t(), []) :: {:ok, AriaState.t()} | {:error, atom()}
    def cook_meal(state, []), do: {:ok, state}

    # Command method
    @command true
    @spec validate_equipment(AriaState.t(), []) :: {:ok, AriaState.t()} | {:error, atom()}
    def validate_equipment(state, []), do: {:ok, state}

    # Task method
    @task_method true
    @spec prepare_meal(AriaState.t(), []) :: {:ok, [AriaEngineCore.todo_item()]} | {:error, atom()}
    def prepare_meal(_state, []), do: {:ok, [{:cook_meal, []}]}

    # Unigoal method
    @unigoal_method predicate: "location"
    @spec move_to_location(AriaState.t(), {AriaState.subject(), AriaState.value()}) :: {:ok, [AriaEngineCore.todo_item()]} | {:error, atom()}
    def move_to_location(_state, {_, _}), do: {:ok, []}

    # Multigoal method
    @multigoal_method true
    @spec optimize_goals(AriaState.t(), AriaEngineCore.multigoal()) :: {:ok, AriaEngineCore.multigoal()} | {:error, atom()}
    def optimize_goals(_state, multigoal), do: {:ok, multigoal}

    # Multitodo method
    @multitodo_method true
    @spec optimize_todos(AriaState.t(), [AriaEngineCore.todo_item()]) :: {:ok, [AriaEngineCore.todo_item()]} | {:error, atom()}
    def optimize_todos(_state, todo_list), do: {:ok, todo_list}
  end

  setup do
    domain = AriaCore.UnifiedDomain.create_from_module(TestDomain)
    initial_state = AriaState.new()
    {:ok, %{domain: domain, initial_state: initial_state}}
  end

  # Phase 1: Attribute System Testing
  test "recognizes all 6 method types with attributes", %{domain: domain} do
    assert Map.has_key?(domain.actions, :instant_action)
    assert Map.has_key?(domain.actions, :floating_duration_action)
    assert Map.has_key?(domain.actions, :cook_meal)
    assert Map.has_key?(domain.actions, :validate_equipment) # Commands are actions internally
    assert Map.has_key?(domain.methods, :prepare_meal)
    assert Map.has_key?(domain.unigoal_methods, :move_to_location)
    assert Map.has_key?(domain.methods, :optimize_goals) # Multigoal methods are methods internally
    assert Map.has_key?(domain.methods, :optimize_todos) # Multitodo methods are methods internally
  end

  test "correctly processes temporal patterns", %{domain: domain} do
    # Pattern 1: Instant action, anytime
    assert {:fixed, 1} = Domain.get_action(domain, :instant_action).duration

    # Pattern 2: Floating duration
    assert {:fixed, 7200} = Domain.get_action(domain, :floating_duration_action).duration

    # Pattern 3: Deadline constraint (end only)
    deadline_action_spec = Domain.get_action(domain, :deadline_action)
    assert {:fixed, 1} = deadline_action_spec.duration # Default duration
    assert "2025-06-22T14:00:00-07:00" == deadline_action_spec.end_time

    # Pattern 4: Calculated start (end - duration)
    calculated_start_spec = Domain.get_action(domain, :calculated_start_action)
    assert {:fixed, 7200} = calculated_start_spec.duration
    assert "2025-06-22T14:00:00-07:00" == calculated_start_spec.end_time

    # Pattern 5: Open start (start only)
    open_start_spec = Domain.get_action(domain, :open_start_action)
    assert {:fixed, 1} = open_start_spec.duration # Default duration
    assert "2025-06-22T10:00:00-07:00" == open_start_spec.start_time

    # Pattern 6: Calculated end (start + duration)
    calculated_end_spec = Domain.get_action(domain, :calculated_end_action)
    assert {:fixed, 7200} = calculated_end_spec.duration
    assert "2025-06-22T10:00:00-07:00" == calculated_end_spec.start_time

    # Pattern 7: Fixed interval
    fixed_interval_spec = Domain.get_action(domain, :fixed_interval_action)
    assert {:fixed, 7200} = fixed_interval_spec.duration
    assert "2025-06-22T10:00:00-07:00" == fixed_interval_spec.start_time
    assert "2025-06-22T12:00:00-07:00" == fixed_interval_spec.end_time

    # Pattern 8: Constraint validation (start + duration = end)
    constraint_validation_spec = Domain.get_action(domain, :constraint_validation_action)
    assert {:fixed, 7200} = constraint_validation_spec.duration
    assert "2025-06-22T10:00:00-07:00" == constraint_validation_spec.start_time
    assert "2025-06-22T12:00:00-07:00" == constraint_validation_spec.end_time
  end

  test "processes entity requirements correctly", %{domain: domain} do
    cook_meal_spec = Domain.get_action(domain, :cook_meal)
    assert [%{type: "agent", capabilities: [:cooking]}] == cook_meal_spec.entity_requirements
  end

  test "unigoal method has correct predicate", %{domain: domain} do
    unigoal_spec = Domain.get_unigoal_method(domain, :move_to_location)
    assert "location" == unigoal_spec.predicate
  end

  # Phase 2: API Compliance Testing (requires AriaEngineCore for plan/run_lazy)
  # These tests will be more integration-focused and might need to be in AriaEngineCore's test suite
  # or require mocking AriaEngineCore. For now, I'll focus on AriaCore's direct responsibilities.

  # Test goal format enforcement (AriaState.satisfies_goal?)
  test "AriaState.satisfies_goal? uses correct goal format", %{initial_state: initial_state} do
    state = AriaState.set_fact(initial_state, "status", "chef_1", "available")
    assert AriaState.satisfies_goal?(state, {"status", "chef_1", "available"})
    refute AriaState.satisfies_goal?(state, %{predicate: "status", subject: "chef_1", value: "available"})
  end

  # Test state validation (AriaState.get_fact)
  test "AriaState.get_fact retrieves facts correctly", %{initial_state: initial_state} do
    state = AriaState.set_fact(initial_state, "status", "chef_1", "available")
    assert {:ok, "available"} == AriaState.get_fact(state, "status", "chef_1")
    assert {:error, :not_found} == AriaState.get_fact(state, "status", "chef_2")
  end

  # Test command attribute recognition
  test "command attribute is recognized", %{domain: domain} do
    validate_equipment_spec = Domain.get_action(domain, :validate_equipment)
    assert validate_equipment_spec.command == true
  end

  # Test multigoal and multitodo methods are recognized as methods
  test "multigoal and multitodo methods are recognized as methods", %{domain: domain} do
    assert Map.has_key?(domain.methods, :optimize_goals)
    assert Map.has_key?(domain.methods, :optimize_todos)
  end
end
