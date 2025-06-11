# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngine.DomainDefinitionTest do
  use ExUnit.Case, async: true

  alias AriaEngine.{DomainDefinition, Domain, State, Actions}

  describe "DomainDefinition creation" do
    test "creates a new domain definition with default values" do
      domain_def = DomainDefinition.new("test_domain")

      assert domain_def.id == "test_domain"
      assert domain_def.name == "test_domain"
      assert domain_def.status == :pending
      assert domain_def.todos == []
      assert domain_def.actions == %{}
      assert domain_def.current_todo_index == 0
      assert is_nil(domain_def.trace_id)
      assert is_nil(domain_def.current_span)
      assert domain_def.todo_spans == %{}
    end

    test "creates domain definition with custom properties" do
      actions = %{echo: &Actions.echo/2}
      todos = [{:echo, ["Hello"]}, {"goal", "subject", "object"}]

      domain_def = DomainDefinition.new("custom_domain", %{
        name: "Custom Domain",
        actions: actions,
        todos: todos
      })

      assert domain_def.id == "custom_domain"
      assert domain_def.name == "Custom Domain"
      assert domain_def.actions == actions
      assert domain_def.todos == todos
      assert length(domain_def.todos) == 2
    end

    test "creates domain definition from existing domain" do
      domain = Domain.new("test")
      |> Domain.add_action(:echo, &Actions.echo/2)

      todos = [{:echo, ["From domain"]}]
      initial_state = State.new()

      domain_def = DomainDefinition.from_domain(domain, todos, initial_state)

      assert domain_def.id == "test"
      assert domain_def.name == "test"
      assert domain_def.actions[:echo] == domain.actions[:echo]
      assert domain_def.todos == todos
      assert domain_def.initial_state == initial_state
    end

    test "converts domain definition back to domain" do
      domain_def = DomainDefinition.new("convert_test", %{
        actions: %{echo: &Actions.echo/2},
        task_methods: %{"test_task" => [fn _s, _a -> [] end]}
      })

      domain = DomainDefinition.to_domain(domain_def)

      assert domain.name == "convert_test"
      assert domain.actions == domain_def.actions
      assert domain.task_methods == domain_def.task_methods
    end
  end

  describe "Execution lifecycle with span tracing" do
    setup do
      todos = [
        {:echo, ["Starting"]},
        {"test_goal", "subject", "object"},
        {:echo, ["Finishing"]}
      ]

      domain_def = DomainDefinition.new("lifecycle_test", %{
        todos: todos,
        actions: %{echo: &Actions.echo/2}
      })

      {:ok, domain_def: domain_def}
    end

    test "starts execution and creates trace_id and first span", %{domain_def: domain_def} do
      started = DomainDefinition.start(domain_def)

      assert started.status == :executing
      assert is_binary(started.trace_id)
      assert started.current_todo_index == 0
      assert started.progress.total_steps == 3

      # Should have started span for first todo
      assert not is_nil(started.current_span)
      assert started.current_span.status == :active
      assert started.current_span.trace_id == started.trace_id
      assert started.current_span.attributes["todo.type"] == "action"
      assert started.current_span.attributes["todo.index"] == 0
    end

    test "advances through todos with span tracking", %{domain_def: domain_def} do
      started = DomainDefinition.start(domain_def)

      # Complete first todo
      after_first = DomainDefinition.complete_current_todo(started)

      assert after_first.current_todo_index == 1
      assert length(after_first.completed_todos) == 1
      assert after_first.progress.completed_steps == 1

      # First span should be completed
      first_span = after_first.todo_spans[0]
      assert first_span.status == :completed
      assert is_integer(first_span.duration_ms)

      # Second span should be active
      assert not is_nil(after_first.current_span)
      assert after_first.current_span.status == :active
      assert after_first.current_span.attributes["todo.type"] == "goal"

      # Complete second todo
      after_second = DomainDefinition.complete_current_todo(after_first)

      assert after_second.current_todo_index == 2
      assert length(after_second.completed_todos) == 2

      # Third span should be active
      assert after_second.current_span.attributes["todo.type"] == "action"
      assert after_second.current_span.attributes["todo.index"] == 2
    end

    test "handles todo failure with span error tracking", %{domain_def: domain_def} do
      started = DomainDefinition.start(domain_def)
      error_reason = "Test failure"

      failed = DomainDefinition.fail_current_todo(started, error_reason)

      assert failed.status == :failed
      assert failed.error == error_reason
      assert length(failed.failed_todos) == 1
      assert failed.metadata[:failure_reason] == error_reason

      # Failed span should be marked as failed
      failed_span = failed.todo_spans[0]
      assert failed_span.status == :failed
      assert failed_span.attributes["error"] == inspect(error_reason)
    end

    test "completes execution", %{domain_def: domain_def} do
      started = DomainDefinition.start(domain_def)

      completed = DomainDefinition.complete(started)

      assert completed.status == :completed
      assert not is_nil(completed.completed_at)
    end

    test "checks if todos are completed", %{domain_def: domain_def} do
      started = DomainDefinition.start(domain_def)

      assert not DomainDefinition.todos_completed?(started)

      # Complete all todos
      final = started
      |> DomainDefinition.complete_current_todo()
      |> DomainDefinition.complete_current_todo()
      |> DomainDefinition.complete_current_todo()

      assert DomainDefinition.todos_completed?(final)
    end
  end

  describe "Todo and span utilities" do
    setup do
      todos = [
        {:echo, ["Action"]},
        {"goal", "subject", "object"},
        {"task_name", ["arg1", "arg2"]}
      ]

      domain_def = DomainDefinition.new("utils_test", %{todos: todos})
      |> DomainDefinition.start()

      {:ok, domain_def: domain_def}
    end

    test "gets current and next todos", %{domain_def: domain_def} do
      current = DomainDefinition.get_current_todo(domain_def)
      next = DomainDefinition.get_next_todo(domain_def)

      assert current == {:echo, ["Action"]}
      assert next == {"goal", "subject", "object"}

      # After advancing
      advanced = DomainDefinition.next_todo(domain_def)
      current_2 = DomainDefinition.get_current_todo(advanced)
      next_2 = DomainDefinition.get_next_todo(advanced)

      assert current_2 == {"goal", "subject", "object"}
      assert next_2 == {"task_name", ["arg1", "arg2"]}
    end

    test "calculates progress percentage", %{domain_def: domain_def} do
      assert DomainDefinition.progress(domain_def) == 0.0

      after_one = DomainDefinition.complete_current_todo(domain_def)
      progress_after_one = DomainDefinition.progress(after_one)
      assert_in_delta progress_after_one, 33.33, 0.1

      after_two = DomainDefinition.complete_current_todo(after_one)
      progress_after_two = DomainDefinition.progress(after_two)
      assert_in_delta progress_after_two, 66.67, 0.1
    end

    test "gets execution summary with span information", %{domain_def: domain_def} do
      # Complete some todos to generate spans
      after_completion = domain_def
      |> DomainDefinition.complete_current_todo()
      |> DomainDefinition.complete_current_todo()
      |> DomainDefinition.complete()

      summary = DomainDefinition.get_summary(after_completion)

      assert summary.id == "utils_test"
      assert summary.status == :completed
      assert summary.total_todos == 3
      assert summary.completed_todos == 2
      assert summary.failed_todos == 0
      assert is_binary(summary.trace_id)
      assert summary.total_spans == 2
      assert summary.completed_spans == 2
      assert is_float(summary.average_span_duration)
      assert is_integer(summary.duration_ms)
    end

    test "gets trace log formatting", %{domain_def: domain_def} do
      # Complete first todo to have some span data
      after_first = DomainDefinition.complete_current_todo(domain_def)

      trace_log = DomainDefinition.get_trace_log(after_first)

      assert is_binary(trace_log)
      assert String.contains?(trace_log, "Todo 0")
      assert String.contains?(trace_log, "action")
      assert String.contains?(trace_log, "✓")  # Completed symbol
    end

    test "gets completed spans", %{domain_def: domain_def} do
      # Start with no completed spans
      completed_spans = DomainDefinition.get_completed_spans(domain_def)
      assert completed_spans == []

      # Complete first todo
      after_first = DomainDefinition.complete_current_todo(domain_def)
      completed_spans = DomainDefinition.get_completed_spans(after_first)

      assert length(completed_spans) == 1
      assert hd(completed_spans).status == :completed
      assert is_integer(hd(completed_spans).duration_ms)
    end
  end

  describe "Validation" do
    test "validates valid domain definition" do
      domain_def = DomainDefinition.new("valid", %{
        todos: [{:echo, ["test"]}, {"goal", "subj", "obj"}],
        actions: %{echo: &Actions.echo/2}
      })

      assert :ok = DomainDefinition.validate(domain_def)
    end

    test "validates invalid domain definition" do
      domain_def = DomainDefinition.new("", %{
        todos: [],
        actions: %{bad_action: "not_a_function"}
      })

      assert {:error, errors} = DomainDefinition.validate(domain_def)
      assert is_list(errors)
      assert length(errors) >= 2
      assert "Domain ID cannot be empty" in errors
      assert "Domain must have at least one todo item" in errors
    end

    test "validates todo formats" do
      valid_todos = [
        {:echo, ["test"]},           # Valid action
        {"task", ["arg"]},           # Valid task
        {"pred", "subj", "obj"}      # Valid goal
      ]

      invalid_todos = [
        {:bad_atom},                 # Invalid format
        {"incomplete"},              # Missing args
        {"too", "many", "args", "here"}  # Invalid goal format
      ]

      valid_def = DomainDefinition.new("valid", %{todos: valid_todos})
      assert :ok = DomainDefinition.validate(valid_def)

      invalid_def = DomainDefinition.new("invalid", %{todos: invalid_todos})
      assert {:error, errors} = DomainDefinition.validate(invalid_def)
      assert length(errors) >= 3
    end
  end

  describe "State management" do
    test "updates current state" do
      domain_def = DomainDefinition.new("state_test")
      new_state = State.new() |> State.set_object("test", "key", "value")

      updated = DomainDefinition.update_state(domain_def, new_state)

      assert updated.current_state == new_state
      assert State.get_object(updated.current_state, "test", "key") == "value"
    end

    test "preserves initial state" do
      initial_state = State.new() |> State.set_object("initial", "data", "preserved")
      domain_def = DomainDefinition.new("state_test", %{initial_state: initial_state})

      new_state = State.new() |> State.set_object("new", "data", "updated")
      updated = DomainDefinition.update_state(domain_def, new_state)

      assert updated.initial_state == initial_state
      assert updated.current_state == new_state
      assert State.get_object(updated.initial_state, "initial", "data") == "preserved"
    end
  end
end
