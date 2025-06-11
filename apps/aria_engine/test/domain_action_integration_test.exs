# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngine.DomainActionIntegrationTest do
  use ExUnit.Case, async: true

  alias AriaEngine.{DomainDefinition, Actions, State, Domain}

  describe "Domain/Action split integration" do
    test "creates domain with mixed todo types" do
      todos = [
        {:echo, ["Starting integration test"]},     # Action
        {"system", "ready", true},                  # Goal
        {:execute_command, ["echo", "Hello"]},     # Action
        {"file_exists", "/tmp", true},             # Goal
        {:echo, ["Test completed"]}                # Action
      ]

      domain_def = DomainDefinition.new("integration_test", %{
        name: "Domain/Action Integration Test",
        actions: %{
          echo: &Actions.echo/2,
          execute_command: &Actions.execute_command/2
        },
        todos: todos,
        initial_state: State.new()
      })

      assert length(domain_def.todos) == 5
      assert domain_def.actions[:echo] == &Actions.echo/2
      assert domain_def.actions[:execute_command] == &Actions.execute_command/2
    end

    test "executes simple todo workflow with span tracing" do
      todos = [
        {:echo, ["Step 1"]},
        {:echo, ["Step 2"]},
        {:echo, ["Step 3"]}
      ]

      domain_def = DomainDefinition.new("simple_workflow", %{
        actions: %{echo: &Actions.echo/2},
        todos: todos,
        initial_state: State.new()
      })

      # Start execution
      started = DomainDefinition.start(domain_def)
      assert started.status == :executing
      assert is_binary(started.trace_id)
      assert not is_nil(started.current_span)

      # Execute each todo with span tracking
      final_state = todos
      |> Enum.with_index()
      |> Enum.reduce(started, fn {_todo, _index}, acc ->
        # Simulate todo execution by completing it
        DomainDefinition.complete_current_todo(acc)
      end)

      # Complete the execution
      completed = DomainDefinition.complete(final_state)

      assert completed.status == :completed
      assert length(completed.completed_todos) == 3
      assert length(completed.failed_todos) == 0
      assert DomainDefinition.todos_completed?(completed)

      # Check span tracking
      spans = DomainDefinition.get_completed_spans(completed)
      assert length(spans) == 3
      Enum.each(spans, fn span ->
        assert span.status == :completed
        assert is_integer(span.duration_ms)
        assert span.duration_ms >= 0
      end)
    end

    test "converts between Domain and DomainDefinition" do
      # Create original Domain
      domain = Domain.new("conversion_test")
      |> Domain.add_action(:echo, &Actions.echo/2)
      |> Domain.add_action(:execute_command, &Actions.execute_command/2)
      |> Domain.add_task_methods("test_task", [fn _s, _a -> [] end])

      todos = [{:echo, ["Convert test"]}]
      initial_state = State.new()

      # Convert to DomainDefinition
      domain_def = DomainDefinition.from_domain(domain, todos, initial_state)

      assert domain_def.name == "conversion_test"
      assert domain_def.actions[:echo] == domain.actions[:echo]
      assert domain_def.actions[:execute_command] == domain.actions[:execute_command]
      assert domain_def.task_methods == domain.task_methods
      assert domain_def.todos == todos

      # Convert back to Domain
      converted_domain = DomainDefinition.to_domain(domain_def)

      assert converted_domain.name == domain.name
      assert converted_domain.actions == domain.actions
      assert converted_domain.task_methods == domain.task_methods
    end

    test "handles execution failure with span error tracking" do
      todos = [
        {:echo, ["Before failure"]},
        {"will_fail", "this", "todo"},
        {:echo, ["After failure"]}
      ]

      domain_def = DomainDefinition.new("failure_test", %{
        actions: %{echo: &Actions.echo/2},
        todos: todos,
        initial_state: State.new()
      })

      started = DomainDefinition.start(domain_def)

      # Complete first todo successfully
      after_first = DomainDefinition.complete_current_todo(started)
      assert length(after_first.completed_todos) == 1

      # Fail second todo
      error_reason = "Simulated failure"
      failed = DomainDefinition.fail_current_todo(after_first, error_reason)

      assert failed.status == :failed
      assert failed.error == error_reason
      assert length(failed.failed_todos) == 1
      assert length(failed.completed_todos) == 1

      # Check span error tracking
      failed_span = failed.todo_spans[1]  # Second todo span
      assert failed_span.status == :failed
      assert failed_span.attributes["error"] == inspect(error_reason)
    end

    test "generates comprehensive execution summary" do
      todos = [
        {:echo, ["Action 1"]},
        {"goal", "subject", "object"},
        {:echo, ["Action 2"]}
      ]

      domain_def = DomainDefinition.new("summary_test", %{
        name: "Summary Test Domain",
        actions: %{echo: &Actions.echo/2},
        todos: todos,
        initial_state: State.new()
      })

      # Execute with mixed success/failure
      executed = domain_def
      |> DomainDefinition.start()
      |> DomainDefinition.complete_current_todo()  # Success
      |> DomainDefinition.fail_current_todo("Test failure")  # Failure

      summary = DomainDefinition.get_summary(executed)

      assert summary.id == "summary_test"
      assert summary.name == "Summary Test Domain"
      assert summary.status == :failed
      assert summary.total_todos == 3
      assert summary.completed_todos == 1
      assert summary.failed_todos == 1
      assert is_binary(summary.trace_id)
      assert summary.total_spans == 2
      assert summary.completed_spans == 2
      assert is_float(summary.average_span_duration)
      assert is_integer(summary.duration_ms)
    end

    test "generates trace log with span information" do
      todos = [
        {:echo, ["Log test"]},
        {"goal", "test", "value"}
      ]

      domain_def = DomainDefinition.new("trace_log_test", %{
        actions: %{echo: &Actions.echo/2},
        todos: todos
      })

      executed = domain_def
      |> DomainDefinition.start()
      |> DomainDefinition.complete_current_todo()
      |> DomainDefinition.complete_current_todo()

      trace_log = DomainDefinition.get_trace_log(executed)

      assert is_binary(trace_log)
      assert String.contains?(trace_log, "Todo 0")
      assert String.contains?(trace_log, "Todo 1")
      assert String.contains?(trace_log, "action")
      assert String.contains?(trace_log, "goal")
      assert String.contains?(trace_log, "✓")  # Completed symbols
    end

    test "validates comprehensive domain definition" do
      # Valid definition
      valid_def = DomainDefinition.new("valid_test", %{
        todos: [
          {:echo, ["test"]},
          {"goal", "subject", "object"},
          {"task", ["arg1"]}
        ],
        actions: %{
          echo: &Actions.echo/2,
          execute_command: &Actions.execute_command/2
        },
        task_methods: %{
          "test_task" => [fn _s, _a -> [] end]
        },
        unigoal_methods: %{
          "test_goal" => [fn _s, _a -> [] end]
        }
      })

      assert :ok = DomainDefinition.validate(valid_def)

      # Invalid definition
      invalid_def = DomainDefinition.new("", %{
        todos: [
          {:bad_format},
          {"incomplete_goal"},
          {"too", "many", "args", "for", "goal"}
        ],
        actions: %{
          bad_action: "not_a_function"
        },
        task_methods: %{
          123 => [fn _s, _a -> [] end]  # Bad key type
        }
      })

      assert {:error, errors} = DomainDefinition.validate(invalid_def)
      assert is_list(errors)
      assert length(errors) >= 5  # Multiple validation errors
    end
  end

  describe "Performance and edge cases" do
    test "handles empty todos gracefully" do
      domain_def = DomainDefinition.new("empty_test", %{
        todos: []
      })

      started = DomainDefinition.start(domain_def)

      assert started.status == :executing
      assert DomainDefinition.todos_completed?(started)
      assert DomainDefinition.get_current_todo(started) == nil
      assert DomainDefinition.progress(started) == 100.0
    end

    test "handles large number of todos efficiently" do
      large_todos = Enum.map(1..1000, fn i -> {:echo, ["Todo #{i}"]} end)

      domain_def = DomainDefinition.new("large_test", %{
        actions: %{echo: &Actions.echo/2},
        todos: large_todos
      })

      started = DomainDefinition.start(domain_def)

      assert length(started.todos) == 1000
      assert started.progress.total_steps == 1000
      assert DomainDefinition.progress(started) == 0.0

      # Complete first 100 todos
      after_100 = Enum.reduce(1..100, started, fn _i, acc ->
        DomainDefinition.complete_current_todo(acc)
      end)

      assert length(after_100.completed_todos) == 100
      assert DomainDefinition.progress(after_100) == 10.0
    end

    test "maintains span ordering and indexing" do
      todos = Enum.map(1..10, fn i -> {:echo, ["Step #{i}"]} end)

      domain_def = DomainDefinition.new("ordering_test", %{
        actions: %{echo: &Actions.echo/2},
        todos: todos
      })

      # Execute all todos
      final = todos
      |> Enum.with_index()
      |> Enum.reduce(DomainDefinition.start(domain_def), fn {_todo, _i}, acc ->
        DomainDefinition.complete_current_todo(acc)
      end)

      # Check span ordering
      spans = final.todo_spans
      assert map_size(spans) == 10

      Enum.each(0..9, fn i ->
        span = spans[i]
        assert span.attributes["todo.index"] == i
        assert span.status == :completed
      end)
    end
  end
end
