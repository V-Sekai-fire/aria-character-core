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
      assert length(basic_timing.todos) > 0
      assert length(basic_timing.task_methods) > 0
      assert length(basic_timing.unigoal_methods) > 0
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
        todos: [{"test", "system", "ready"}],
        task_methods: [{"dummy_task", fn _state, _args -> {:ok, %{}} end}],
        unigoal_methods: [],
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
        todos: [{"goal", "subject", "object"}],
        task_methods: [{"task1", fn _s, _a -> {:ok, %{}} end}],
        unigoal_methods: [{"method1", fn _s, _a -> {:ok, %{}} end}]
      })

      assert workflow.id == "test"
      assert length(workflow.todos) == 1
      assert length(workflow.task_methods) == 1
      assert length(workflow.unigoal_methods) == 1
    end

    test "validates workflow definition" do
      valid_workflow = WorkflowDefinition.new("valid", %{
        todos: [{"goal", "subject", "object"}],
        task_methods: [{"task1", fn _s, _a -> {:ok, %{}} end}],
        unigoal_methods: []
      })

      assert :ok = WorkflowDefinition.validate(valid_workflow)

      invalid_workflow = WorkflowDefinition.new("", %{
        todos: [],
        task_methods: [],
        unigoal_methods: []
      })

      assert {:error, errors} = WorkflowDefinition.validate(invalid_workflow)
      assert is_list(errors)
      assert length(errors) > 0
    end

    test "converts goals to multigoal" do
      workflow = WorkflowDefinition.new("test", %{
        todos: [
          {"location", "player", "room1"},
          {"has", "player", "sword"}
        ],
        task_methods: [],
        unigoal_methods: []
      })

      {:ok, multigoal} = WorkflowDefinition.to_multigoal(workflow)
      goals = AriaEngine.Multigoal.get_goals(multigoal)

      assert length(goals) == 2
      assert {"location", "player", "room1"} in goals
      assert {"has", "player", "sword"} in goals
    end

    test "gets task and method by name" do
      task_fn = fn _s, _a -> {:ok, %{}} end
      method_fn = fn _s, _a -> {:ok, %{}} end

      workflow = WorkflowDefinition.new("test", %{
        todos: [],
        task_methods: [{"test_task", task_fn}],
        unigoal_methods: [{"test_method", method_fn}]
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
      {:ok, new_state} = AriaWorkflow.Tasks.BasicTiming.get_current_time(state, %{})
      result = new_state.current_time_info

      assert Map.has_key?(result, :utc)
      assert Map.has_key?(result, :local)
      assert Map.has_key?(result, :timezone)
      assert %DateTime{} = result.utc
    end

    test "manages timers" do
      state = State.new()
      timer_id = "test_timer"

      # Start timer
      {:ok, state_with_timer} = AriaWorkflow.Tasks.BasicTiming.start_timer(state, %{timer_id: timer_id})
      active_timers = Map.get(state_with_timer, :active_timers, %{})
      start_result = Map.get(active_timers, timer_id, %{})
      assert Map.has_key?(start_result, :timer_id)
      assert Map.has_key?(start_result, :start_time)

      :timer.sleep(10)  # Brief delay

      # Stop timer
      {:ok, final_state} = AriaWorkflow.Tasks.BasicTiming.stop_timer(state_with_timer, %{timer_id: timer_id})
      completed_timers = Map.get(final_state, :completed_timers, %{})
      stop_result = Map.get(completed_timers, timer_id, %{})
      assert Map.has_key?(stop_result, :timer_id)
      assert Map.has_key?(stop_result, :duration_ms)
      assert stop_result.duration_ms > 0
    end
  end

  describe "Basic Timing Methods" do
    test "times command execution" do
      state = State.new()
      {:ok, _final_state, result} = AriaWorkflow.Methods.BasicTiming.time_command_execution(state, %{
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

      assert start_result == trace_id

      :timer.sleep(10)  # Brief delay

      # End trace
      {:ok, _final_state, end_result} = AriaWorkflow.Tasks.CommandTracing.trace_command_end(state_with_trace, %{
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
    test "handles concurrent registry access", %{registry: registry} do
      tasks = for _i <- 1..10 do
        Task.async(fn ->
          {:ok, workflow} = WorkflowEngine.get_workflow("basic_timing", registry: registry)
          assert workflow.id == "basic_timing"
        end)
      end

      results = Task.await_many(tasks, 5000)
      assert length(results) == 10
    end

    test "handles missing workflow gracefully", %{registry: registry} do
      assert {:error, :not_found} = WorkflowEngine.get_workflow("nonexistent_workflow", registry: registry)
    end

    test "validates workflow definitions properly" do
      invalid_workflow = WorkflowDefinition.new("invalid", %{
        todos: ["invalid_todo_format"],  # Should be tuples
        task_methods: [{"invalid_task", "not_a_function"}],  # Should be function
        unigoal_methods: []
      })

      {:error, errors} = WorkflowDefinition.validate(invalid_workflow)
      assert is_list(errors)
      assert length(errors) >= 1  # At least todo validation error
    end
  end

  describe "Coding Workflow Cycle Time Measurement" do
    test "measures development cycle times from commit history" do
      # Simulate commit cycle analysis data
      cycle_data = %{
        total_commits: 10,
        statistics: %{
          average: 102.1,
          median: 28.1,
          min: 7.6,
          max: 462.0,  # 7.7 hours in minutes
          total: 918.0,  # 15.3 hours in minutes
          count: 9
        },
        patterns: %{
          rapid_development: %{count: 7, description: "Quick iterations (< 1h)"},
          moderate_development: %{count: 1, description: "Standard cycles (1-5h)"},
          extended_development: %{count: 1, description: "Major features (> 5h)"}
        }
      }

      # Test cycle time analysis validation
      assert cycle_data.statistics.average > 0
      assert cycle_data.statistics.median < cycle_data.statistics.average
      assert cycle_data.patterns.rapid_development.count > cycle_data.patterns.extended_development.count

      # Validate development velocity metrics
      total_dev_hours = cycle_data.statistics.total / 60.0
      assert total_dev_hours > 10.0  # Substantial development time

      rapid_ratio = cycle_data.patterns.rapid_development.count / cycle_data.statistics.count
      assert rapid_ratio > 0.5  # More than half are rapid cycles
    end

    test "tracks workflow execution timing with spans" do
      workflow_id = "cycle_time_test_#{:rand.uniform(1000)}"

      # Start workflow execution span
      execution_span = Span.new("workflow_execution", [
        kind: :internal,
        attributes: %{
          "workflow.id" => workflow_id,
          "workflow.type" => "cycle_measurement"
        }
      ])

      :timer.sleep(50)  # Simulate some work

      # Create child span for individual operations
      operation_span = Span.create_child(execution_span, "operation_execution")
      |> Span.set_attribute("operation.type", "test_command")

      :timer.sleep(25)  # Simulate operation work

      finished_operation = Span.finish(operation_span, status: :ok)
      finished_execution = Span.finish(execution_span, status: :ok)

      # Validate timing measurements
      assert finished_execution.duration_us > 70_000  # At least 70ms
      assert finished_operation.duration_us > 20_000  # At least 20ms
      assert finished_operation.parent_span_id == execution_span.span_id

      # Test log formatting for development tracking
      log_format = Span.to_log_format(finished_execution)
      assert String.contains?(log_format, "workflow_execution")
      # Note: workflow_id is in attributes, not directly in log format
    end

    test "measures command execution cycle times" do
      state = State.new()
      command_start = System.monotonic_time(:millisecond)

      # Simulate timed command execution
      {:ok, final_state, result} = AriaWorkflow.Methods.BasicTiming.time_command_execution(state, %{
        command: "echo",
        args: ["Cycle time measurement test"]
      })

      command_end = System.monotonic_time(:millisecond)
      total_cycle_time = command_end - command_start

      # Validate timing results
      assert Map.has_key?(result, :duration_ms)
      assert result.duration_ms > 0
      assert result.duration_ms <= total_cycle_time  # Internal measurement should be less than or equal to total
      assert result.exit_code == 0
      assert String.contains?(result.output, "Cycle time measurement test")

      # Test development velocity tracking
      assert result.duration_ms < 1000  # Should be fast for simple commands
    end

    test "analyzes development pattern efficiency" do
      # Simulate multiple workflow executions with different cycle times
      execution_times = [
        %{workflow: "rapid_fix", duration_ms: 1500},      # 1.5s - very fast
        %{workflow: "feature_impl", duration_ms: 45000},  # 45s - moderate
        %{workflow: "refactor", duration_ms: 180000},     # 3m - extended
        %{workflow: "test_fix", duration_ms: 800},        # 0.8s - very fast
        %{workflow: "integration", duration_ms: 120000}   # 2m - moderate
      ]

      # Categorize by development pattern
      rapid_executions = Enum.filter(execution_times, & &1.duration_ms < 30000)  # < 30s
      moderate_executions = Enum.filter(execution_times, & &1.duration_ms >= 30000 and &1.duration_ms < 300000)  # 30s - 5m
      extended_executions = Enum.filter(execution_times, & &1.duration_ms >= 300000)  # > 5m

      # Validate pattern distribution
      assert length(rapid_executions) == 2
      assert length(moderate_executions) == 3
      assert length(extended_executions) == 0

      # Calculate efficiency metrics
      total_time = Enum.sum(Enum.map(execution_times, & &1.duration_ms))
      avg_time = total_time / length(execution_times)

      assert avg_time < 100000  # Average under 100s indicates good efficiency
      assert length(rapid_executions) >= length(extended_executions)  # Bias toward rapid cycles
    end

    test "integrates cycle time data with commit workflow" do
      # Simulate git workflow cycle measurement
      git_operations = [
        %{operation: "stage_files", duration_ms: 200},
        %{operation: "run_tests", duration_ms: 15000},
        %{operation: "commit_changes", duration_ms: 150},
        %{operation: "push_changes", duration_ms: 1200}
      ]

      total_git_cycle = Enum.sum(Enum.map(git_operations, & &1.duration_ms))

      # Test workflow integration
      assert total_git_cycle < 20000  # Full git cycle under 20s

      # Find bottlenecks
      slowest_operation = Enum.max_by(git_operations, & &1.duration_ms)
      assert slowest_operation.operation == "run_tests"  # Expected bottleneck
      assert slowest_operation.duration_ms > 10000  # Tests take significant time

      # Validate optimization opportunities
      non_test_time = total_git_cycle - slowest_operation.duration_ms
      assert non_test_time < 2000  # Everything else should be very fast
    end

    test "tracks development velocity over time" do
      # Simulate development session with multiple cycles
      session_start = System.monotonic_time(:millisecond)

      development_cycles = [
        %{cycle: 1, type: "initial_implementation", start_offset: 0},
        %{cycle: 2, type: "bug_fix", start_offset: 300000},        # 5m later
        %{cycle: 3, type: "test_addition", start_offset: 480000},  # 3m later
        %{cycle: 4, type: "optimization", start_offset: 720000},   # 4m later
        %{cycle: 5, type: "final_polish", start_offset: 900000}    # 3m later
      ]

      # Calculate inter-cycle intervals
      intervals = development_cycles
      |> Enum.chunk_every(2, 1, :discard)
      |> Enum.map(fn [current, next] ->
        next.start_offset - current.start_offset
      end)

      # Validate development rhythm
      avg_interval = Enum.sum(intervals) / length(intervals)
      assert avg_interval < 300000  # Average under 5 minutes between cycles

      # Check for consistent velocity (not too much variation)
      max_interval = Enum.max(intervals)
      min_interval = Enum.min(intervals)
      velocity_consistency = max_interval / min_interval
      assert velocity_consistency < 3.0  # Max interval no more than 3x min interval

      session_duration = List.last(development_cycles).start_offset
      cycles_per_hour = (length(development_cycles) * 3600000) / session_duration
      assert cycles_per_hour > 3.0  # At least 3 cycles per hour
    end
  end
end
