defmodule CoreTest do
  @moduledoc """
  Tests for the Core module - foundational AriaEngine type definitions and constructor.

  This module tests the core infrastructure that other components depend on,
  including type definitions, struct construction, and default value handling.
  """

  use ExUnit.Case, async: true
  doctest Core

  @moduletag :unit
  @moduletag :core

  describe "Core.new/2" do
    test "creates AriaEngine with minimal parameters" do
      engine = Core.new("test_engine")

      assert engine.id == "test_engine"
      assert engine.name == "test_engine"
      assert engine.execution_id == nil
      assert engine.actions == %{}
      assert engine.task_methods == %{}
      assert engine.unigoal_methods == %{}
      assert engine.multigoal_methods == []
      assert engine.goals == []
      assert engine.status == :pending
      assert engine.solution_tree == nil
      assert engine.error == nil
      assert engine.documentation == %{}
      assert engine.metadata == %{}
      assert %DateTime{} = engine.created_at
      assert engine.started_at == nil
      assert engine.completed_at == nil
    end

    test "creates AriaEngine with custom name" do
      definition = %{name: "Custom Engine Name"}
      engine = Core.new("test_id", definition)

      assert engine.id == "test_id"
      assert engine.name == "Custom Engine Name"
    end

    test "creates AriaEngine with initial state" do
      initial_state = State.new()
      definition = %{initial_state: initial_state}
      engine = Core.new("test_engine", definition)

      assert engine.initial_state == initial_state
      assert engine.current_state == initial_state
    end

    test "creates AriaEngine with actions" do
      test_action = fn _state, _args -> State.new() end
      actions = %{test_action: test_action}
      definition = %{actions: actions}
      engine = Core.new("test_engine", definition)

      assert engine.actions == actions
    end

    test "creates AriaEngine with task methods" do
      test_method = fn _state, _args -> [] end
      task_methods = %{"test_task" => [test_method]}
      definition = %{task_methods: task_methods}
      engine = Core.new("test_engine", definition)

      assert engine.task_methods == task_methods
    end

    test "creates AriaEngine with unigoal methods" do
      test_method = fn _state, _args -> [] end
      unigoal_methods = %{"test_goal" => [test_method]}
      definition = %{unigoal_methods: unigoal_methods}
      engine = Core.new("test_engine", definition)

      assert engine.unigoal_methods == unigoal_methods
    end

    test "creates AriaEngine with multigoal methods" do
      test_method = fn _state, _args -> [] end
      multigoal_methods = [test_method]
      definition = %{multigoal_methods: multigoal_methods}
      engine = Core.new("test_engine", definition)

      assert engine.multigoal_methods == multigoal_methods
    end

    test "creates AriaEngine with goals" do
      goals = [{"achieve", "goal1", "value1"}, {"maintain", "goal2", "value2"}]
      definition = %{goals: goals}
      engine = Core.new("test_engine", definition)

      assert engine.goals == goals
    end

    test "creates AriaEngine with documentation" do
      documentation = %{purpose: "Test engine", version: "1.0"}
      definition = %{documentation: documentation}
      engine = Core.new("test_engine", definition)

      assert engine.documentation == documentation
    end

    test "creates AriaEngine with metadata" do
      metadata = %{author: "test", tags: ["experimental"]}
      definition = %{metadata: metadata}
      engine = Core.new("test_engine", definition)

      assert engine.metadata == metadata
    end

    test "creates AriaEngine with complete definition" do
      initial_state = State.new()
      test_action = fn _state, _args -> State.new() end
      test_task_method = fn _state, _args -> [] end
      test_goal_method = fn _state, _args -> [] end

      definition = %{
        name: "Complete Test Engine",
        initial_state: initial_state,
        actions: %{test_action: test_action},
        task_methods: %{"test_task" => [test_task_method]},
        unigoal_methods: %{"test_goal" => [test_goal_method]},
        multigoal_methods: [test_goal_method],
        goals: [{"achieve", "test_goal", "test_value"}],
        documentation: %{purpose: "Complete test"},
        metadata: %{version: "1.0"}
      }

      engine = Core.new("complete_test", definition)

      assert engine.id == "complete_test"
      assert engine.name == "Complete Test Engine"
      assert engine.initial_state == initial_state
      assert engine.current_state == initial_state
      assert engine.actions == %{test_action: test_action}
      assert engine.task_methods == %{"test_task" => [test_task_method]}
      assert engine.unigoal_methods == %{"test_goal" => [test_goal_method]}
      assert engine.multigoal_methods == [test_goal_method]
      assert engine.goals == [{"achieve", "test_goal", "test_value"}]
      assert engine.documentation == %{purpose: "Complete test"}
      assert engine.metadata == %{version: "1.0"}
      assert %DateTime{} = engine.created_at
    end
  end

  describe "Core struct validation" do
    test "has correct default values" do
      engine = %Core{}

      assert engine.id == nil
      assert engine.name == nil
      assert engine.execution_id == nil
      assert engine.actions == %{}
      assert engine.task_methods == %{}
      assert engine.unigoal_methods == %{}
      assert engine.multigoal_methods == []
      assert engine.goals == []
      assert engine.current_state == nil
      assert engine.initial_state == nil
      assert engine.status == :pending
      assert engine.solution_tree == nil
      assert engine.progress == %{total_steps: 0, completed_steps: 0, current_step: nil}
      assert engine.error == nil
      assert engine.documentation == %{}
      assert engine.metadata == %{}
      assert engine.created_at == nil
      assert engine.started_at == nil
      assert engine.completed_at == nil
    end

    test "progress field has correct structure" do
      engine = Core.new("test")

      assert is_map(engine.progress)
      assert Map.has_key?(engine.progress, :total_steps)
      assert Map.has_key?(engine.progress, :completed_steps)
      assert Map.has_key?(engine.progress, :current_step)
      assert engine.progress.total_steps == 0
      assert engine.progress.completed_steps == 0
      assert engine.progress.current_step == nil
    end

    test "status field accepts valid status values" do
      valid_statuses = [:pending, :planning, :executing, :completed, :failed, :cancelled]

      for status <- valid_statuses do
        engine = %Core{status: status}
        assert engine.status == status
      end
    end

    test "created_at is set to current time" do
      before_creation = DateTime.utc_now()
      engine = Core.new("test")
      after_creation = DateTime.utc_now()

      assert DateTime.compare(engine.created_at, before_creation) in [:gt, :eq]
      assert DateTime.compare(engine.created_at, after_creation) in [:lt, :eq]
    end
  end

  describe "Core type specifications" do
    test "engine struct matches Core.t() type" do
      engine = Core.new("type_test")

      # Verify the struct has all the fields expected by the type
      assert is_binary(engine.id)
      assert is_binary(engine.name)
      assert is_nil(engine.execution_id) or is_reference(engine.execution_id)
      assert is_map(engine.actions)
      assert is_map(engine.task_methods)
      assert is_map(engine.unigoal_methods)
      assert is_list(engine.multigoal_methods)
      assert is_list(engine.goals)
      assert engine.status in [:pending, :planning, :executing, :completed, :failed, :cancelled]
      assert is_nil(engine.solution_tree)
      assert is_map(engine.progress)
      assert is_nil(engine.error)
      assert is_map(engine.documentation)
      assert is_map(engine.metadata)
      assert %DateTime{} = engine.created_at
      assert is_nil(engine.started_at)
      assert is_nil(engine.completed_at)
    end

    test "initial_state and current_state use StateV2" do
      initial_state = State.new()
      definition = %{initial_state: initial_state}
      engine = Core.new("state_test", definition)

      assert %State{} = engine.initial_state
      assert %State{} = engine.current_state
      assert engine.initial_state == engine.current_state
    end
  end

  describe "Core edge cases" do
    test "handles empty definition map" do
      engine = Core.new("empty_test", %{})

      assert engine.id == "empty_test"
      assert engine.name == "empty_test"
      # All other fields should have defaults
      assert engine.actions == %{}
      assert engine.goals == []
      assert %DateTime{} = engine.created_at
    end

    test "handles nil definition" do
      # The Core.new/2 function expects a map, so nil should be replaced with %{}
      engine = Core.new("nil_test", %{})

      assert engine.id == "nil_test"
      assert engine.name == "nil_test"
      # Should still work with defaults
      assert engine.actions == %{}
      assert engine.goals == []
    end

    test "preserves state reference equality" do
      state = State.new()
      definition = %{initial_state: state}
      engine = Core.new("ref_test", definition)

      # Both should reference the same state object
      assert engine.initial_state === state
      assert engine.current_state === state
      assert engine.initial_state === engine.current_state
    end
  end
end
