# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaWorkflow.WorkflowSystemTest do
  use ExUnit.Case, async: true

  alias AriaEngine.State
  alias AriaWorkflow.{WorkflowRegistry, WorkflowEngine, WorkflowDefinition, Span}

  setup do
    # Start the workflow registry for testing
    {:ok, registry} = start_supervised({WorkflowRegistry, name: :"test_registry_#{:rand.uniform(1000)}"})

    {:ok, registry: registry}
  end

  describe "Workflow Registry" do
    test "starts successfully", %{registry: registry} do
      assert Process.alive?(registry)
    end

    test "loads built-in workflows", %{registry: registry} do
      {:ok, basic_timing} = WorkflowRegistry.get_workflow("basic_timing", registry: registry)
      assert basic_timing.id == "basic_timing"
      assert length(basic_timing.goals) > 0
      assert length(basic_timing.tasks) > 0
      assert length(basic_timing.methods) > 0
    end

    test "lists all workflows", %{registry: registry} do
      workflows = WorkflowRegistry.list_all(registry: registry)
      workflow_ids = Enum.map(workflows, & &1.id)

      assert "basic_timing" in workflow_ids
      assert "command_tracing" in workflow_ids
      assert length(workflows) >= 2
    end

    test "registers custom workflow", %{registry: registry} do
      custom_workflow = WorkflowDefinition.new("test_workflow", %{
        goals: [{"test", "system", "ready"}],
        tasks: [{"dummy_task", fn _state, _args -> {:ok, %{}, %{}} end}],
        methods: [],
        documentation: %{overview: "Test workflow"},
        metadata: %{version: "1.0"}
      })

      assert :ok = WorkflowRegistry.register(custom_workflow, registry: registry)

      {:ok, retrieved} = WorkflowRegistry.get_workflow("test_workflow", registry: registry)
      assert retrieved.id == "test_workflow"
    end
  end

  describe "Workflow Engine" do
    test "gets workflow by ID", %{registry: registry} do
      {:ok, workflow} = WorkflowEngine.get_workflow("basic_timing", registry: registry)
      assert workflow.id == "basic_timing"
    end

    test "plans workflow execution", %{registry: registry} do
      {:ok, workflow} = WorkflowEngine.get_workflow("basic_timing", registry: registry)
      initial_state = State.new()

      case WorkflowEngine.plan_workflow(workflow, initial_state) do
        {:ok, execution_plan} ->
          assert is_map(execution_plan)
          assert Map.has_key?(execution_plan, :workflow_id)
          assert Map.has_key?(execution_plan, :steps)
          assert execution_plan.workflow_id == "basic_timing"

        {:error, reason} ->
          flunk("Workflow planning failed: #{inspect(reason)}")
      end
    end

    test "executes workflow operations", %{registry: registry} do
      {:ok, workflow} = WorkflowEngine.get_workflow("basic_timing", registry: registry)
      initial_state = State.new()

      case WorkflowEngine.plan_workflow(workflow, initial_state) do
        {:ok, execution_plan} ->
          case WorkflowEngine.execute_plan(execution_plan, background: false) do
            :ok ->
              # Execution completed successfully
              assert true

            {:error, reason} ->
              flunk("Workflow execution failed: #{inspect(reason)}")
          end

        {:error, reason} ->
          flunk("Workflow planning failed: #{inspect(reason)}")
      end
    end
  end

  describe "Workflow Definition" do
    test "creates new workflow definition" do
      workflow = WorkflowDefinition.new("test", %{
        goals: [{"goal", "subject", "object"}],
        tasks: [{"task1", fn _s, _a -> {:ok, %{}, %{}} end}],
        methods: [{"method1", fn _s, _a -> {:ok, %{}, %{}} end}]
      })

      assert workflow.id == "test"
      assert length(workflow.goals) == 1
      assert length(workflow.tasks) == 1
      assert length(workflow.methods) == 1
    end

    test "validates workflow definition" do
      valid_workflow = WorkflowDefinition.new("valid", %{
        goals: [{"goal", "subject", "object"}],
        tasks: [{"task1", fn _s, _a -> {:ok, %{}, %{}} end}],
        methods: []
      })

      assert :ok = WorkflowDefinition.validate(valid_workflow)

      invalid_workflow = WorkflowDefinition.new("", %{
        goals: [],
        tasks: [],
        methods: []
      })

      assert {:error, errors} = WorkflowDefinition.validate(invalid_workflow)
      assert is_list(errors)
      assert length(errors) > 0
    end

    test "converts goals to multigoal" do
      workflow = WorkflowDefinition.new("test", %{
        goals: [
          {"location", "player", "room1"},
          {"has", "player", "sword"}
        ],
        tasks: [],
        methods: []
      })

      {:ok, multigoal} = WorkflowDefinition.to_multigoal(workflow)
      goals = AriaEngine.Multigoal.get_goals(multigoal)

      assert length(goals) == 2
      assert {"location", "player", "room1"} in goals
      assert {"has", "player", "sword"} in goals
    end

    test "gets task and method by name" do
      task_fn = fn _s, _a -> {:ok, %{}, %{}} end
      method_fn = fn _s, _a -> {:ok, %{}, %{}} end

      workflow = WorkflowDefinition.new("test", %{
        goals: [],
        tasks: [{"test_task", task_fn}],
        methods: [{"test_method", method_fn}]
      })

      {:ok, retrieved_task} = WorkflowDefinition.get_task(workflow, "test_task")
      assert retrieved_task == task_fn

      {:ok, retrieved_method} = WorkflowDefinition.get_method(workflow, "test_method")
      assert retrieved_method == method_fn

      assert {:error, :not_found} = WorkflowDefinition.get_task(workflow, "nonexistent")
      assert {:error, :not_found} = WorkflowDefinition.get_method(workflow, "nonexistent")
    end
  end

  describe "Span Tracing" do
    test "creates and manages spans" do
      span = Span.new("test_operation", [
        kind: :internal,
        attributes: %{"test.attr" => "value"}
      ])

      assert is_binary(span.span_id)
      assert is_binary(span.trace_id)
      assert span.name == "test_operation"
      assert span.kind == :internal
      assert span.status == :unset
      assert span.attributes["test.attr"] == "value"
      assert is_nil(span.end_time)
    end

    test "finishes spans with timing" do
      span = Span.new("test_operation")
      :timer.sleep(10)  # Brief delay

      finished_span = Span.finish(span, status: :ok)

      assert finished_span.status == :ok
      assert is_integer(finished_span.duration_us)
      assert finished_span.duration_us > 0
      assert finished_span.end_time != nil
    end

    test "creates child spans" do
      parent_span = Span.new("parent_operation")
      child_span = Span.create_child(parent_span, "child_operation")

      assert child_span.parent_span_id == parent_span.span_id
      assert child_span.trace_id == parent_span.trace_id
      assert child_span.name == "child_operation"
    end

    test "adds events and attributes" do
      span = Span.new("test_operation")
      |> Span.set_attribute("key1", "value1")
      |> Span.add_event("test_event", %{"event.key" => "event.value"})

      assert span.attributes["key1"] == "value1"
      assert length(span.events) == 1

      event = hd(span.events)
      assert event.name == "test_event"
      assert event.attributes["event.key"] == "event.value"
    end

    test "records exceptions" do
      span = Span.new("test_operation")
      exception = %RuntimeError{message: "Test error"}

      span_with_exception = Span.record_exception(span, exception)

      assert span_with_exception.attributes["error"] == true
      assert span_with_exception.attributes["exception.type"] == "Elixir.RuntimeError"
      assert span_with_exception.attributes["exception.message"] == "Test error"
      assert length(span_with_exception.events) == 1
    end

    test "formats span for logging" do
      span = Span.new("test_operation")
      |> Span.finish(status: :ok)

      log_format = Span.to_log_format(span)

      assert is_binary(log_format)
      assert String.contains?(log_format, "test_operation")
      assert String.contains?(log_format, "ok")
    end
  end

  describe "Basic Timing Tasks" do
    test "gets current time" do
      state = State.new()
      {:ok, new_state, result} = AriaWorkflow.Tasks.BasicTiming.get_current_time(state, %{})

      assert Map.has_key?(result, :utc_time)
      assert Map.has_key?(result, :local_time)
      assert Map.has_key?(result, :timezone)
      assert %DateTime{} = result.utc_time
    end

    test "manages timers" do
      state = State.new()
      timer_id = "test_timer"

      # Start timer
      {:ok, state_with_timer, start_result} = AriaWorkflow.Tasks.BasicTiming.start_timer(state, %{timer_id: timer_id})
      assert Map.has_key?(start_result, :timer_id)
      assert Map.has_key?(start_result, :start_time)

      :timer.sleep(10)  # Brief delay

      # Stop timer
      {:ok, final_state, stop_result} = AriaWorkflow.Tasks.BasicTiming.stop_timer(state_with_timer, %{timer_id: timer_id})
      assert Map.has_key?(stop_result, :timer_id)
      assert Map.has_key?(stop_result, :duration_ms)
      assert stop_result.duration_ms > 0
    end
  end

  describe "Basic Timing Methods" do
    test "times command execution" do
      state = State.new()
      {:ok, final_state, result} = AriaWorkflow.Methods.BasicTiming.time_command_execution(state, %{
        command: "echo",
        args: ["Hello, World!"]
      })

      assert Map.has_key?(result, :output)
      assert Map.has_key?(result, :exit_code)
      assert Map.has_key?(result, :duration_ms)
      assert result.exit_code == 0
      assert String.contains?(result.output, "Hello, World!")
    end
  end

  describe "Command Tracing Tasks" do
    test "traces command start and end" do
      state = State.new()
      trace_id = "test_trace_#{:rand.uniform(1000)}"

      # Start trace
      {:ok, state_with_trace, start_result} = AriaWorkflow.Tasks.CommandTracing.trace_command_start(state, %{
        trace_id: trace_id,
        command: "echo",
        args: ["test"]
      })

      assert Map.has_key?(start_result, :trace_id)
      assert start_result.trace_id == trace_id

      :timer.sleep(10)  # Brief delay

      # End trace
      {:ok, final_state, end_result} = AriaWorkflow.Tasks.CommandTracing.trace_command_end(state_with_trace, %{
        trace_id: trace_id,
        exit_code: 0,
        output: "test output"
      })

      assert Map.has_key?(end_result, :trace_id)
      assert Map.has_key?(end_result, :duration_ms)
      assert end_result.duration_ms > 0
    end
  end

  describe "Performance and Reliability" do
    test "handles concurrent registry access" do
      tasks = for _i <- 1..10 do
        Task.async(fn ->
          {:ok, workflow} = WorkflowEngine.get_workflow("basic_timing")
          assert workflow.id == "basic_timing"
        end)
      end

      results = Task.await_many(tasks, 5000)
      assert length(results) == 10
    end

    test "handles missing workflow gracefully" do
      assert {:error, :not_found} = WorkflowEngine.get_workflow("nonexistent_workflow")
    end

    test "validates workflow definitions properly" do
      invalid_workflow = WorkflowDefinition.new("invalid", %{
        goals: ["invalid_goal_format"],  # Should be tuples
        tasks: [{"invalid_task", "not_a_function"}],  # Should be function
        methods: []
      })

      {:error, errors} = WorkflowDefinition.validate(invalid_workflow)
      assert is_list(errors)
      assert length(errors) >= 2  # At least goal and task validation errors
    end
  end
end
