# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaWorkflow.WorkflowEngineTest do
  use ExUnit.Case, async: true

  alias AriaEngine.State
  alias AriaWorkflow.{WorkflowEngine, WorkflowDefinition, WorkflowExecution, WorkflowRegistry}

  setup do
    # Start the workflow registry for testing
    {:ok, registry} = start_supervised({WorkflowRegistry, name: :"test_registry_#{:rand.uniform(1000)}"})

    {:ok, registry: registry}
  end

  describe "Workflow Engine Core" do
    test "defines and registers new workflow", %{registry: registry} do
      workflow_definition = %{
        todos: [{"test", "system", "ready"}],
        task_methods: [{"test_task", fn _state, _args -> {:ok, %{}} end}],
        unigoal_methods: [],
        documentation: %{overview: "Test workflow for engine testing"},
        metadata: %{version: "1.0", test: true}
      }

      # Create workflow and register it manually with the test registry
      workflow = WorkflowDefinition.new("engine_test_workflow", workflow_definition)
      :ok = WorkflowRegistry.register(workflow, registry: registry)

      # Verify registration worked
      {:ok, retrieved_workflow} = WorkflowRegistry.get_workflow("engine_test_workflow", registry: registry)

      assert retrieved_workflow.id == "engine_test_workflow"
      assert length(retrieved_workflow.todos) == 1
      assert length(retrieved_workflow.task_methods) == 1
    end

    test "plans workflow with AriaEngine integration", %{registry: registry} do
      {:ok, workflow} = WorkflowEngine.get_workflow("basic_timing", registry: registry)
      initial_state = State.new()

      case WorkflowEngine.plan_workflow(workflow, initial_state) do
        {:ok, execution} ->
          assert %WorkflowExecution{} = execution
          assert execution.workflow_id == "basic_timing"
          assert execution.status == :pending
          assert is_list(execution.steps)
          assert execution.root_span != nil

        {:error, reason} ->
          flunk("Workflow planning failed: #{inspect(reason)}")
      end
    end

    test "executes planned workflow synchronously" do
      {:ok, workflow} = WorkflowEngine.get_workflow("basic_timing")
      initial_state = State.new()

      case WorkflowEngine.plan_workflow(workflow, initial_state) do
        {:ok, execution} ->
          case WorkflowEngine.execute_plan(execution, background: false) do
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

    test "lists available workflows", %{registry: registry} do
      workflows = WorkflowEngine.list_workflows(registry: registry)
      workflow_ids = Enum.map(workflows, & &1.id)

      assert "basic_timing" in workflow_ids
      assert "command_tracing" in workflow_ids
      assert length(workflows) >= 2
    end
  end

  describe "Workflow Execution with Spans" do
    test "execution creates proper span hierarchy" do
      {:ok, workflow} = WorkflowEngine.get_workflow("basic_timing")
      initial_state = State.new()

      {:ok, execution} = WorkflowEngine.plan_workflow(workflow, initial_state)

      # Check initial span setup
      assert execution.root_span != nil
      assert execution.root_span.name == "workflow:basic_timing"
      assert execution.root_span.kind == :server
      assert execution.current_span == execution.root_span
      assert length(execution.spans) == 1
    end

    test "execution tracks progress properly" do
      {:ok, workflow} = WorkflowEngine.get_workflow("basic_timing")
      initial_state = State.new()

      {:ok, execution} = WorkflowEngine.plan_workflow(workflow, initial_state)

      # Initial progress
      assert execution.progress.total_steps >= 0
      assert execution.progress.completed_steps == 0
      assert execution.progress.current_step == nil
    end
  end

  describe "Error Handling" do
    test "handles nonexistent workflow gracefully", %{registry: registry} do
      assert {:error, :not_found} = WorkflowEngine.get_workflow("nonexistent_workflow", registry: registry)
    end

    test "handles invalid workflow definition" do
      invalid_definition = %{
        goals: [],  # Empty goals should cause validation error
        tasks: [],
        methods: [],
        documentation: %{},
        metadata: %{}
      }

      {:error, errors} = WorkflowEngine.define_workflow("invalid_workflow", invalid_definition)
      assert is_list(errors)
      assert length(errors) > 0
    end

    test "planning handles malformed workflow" do
      # Create workflow with malformed goals
      workflow = WorkflowDefinition.new("malformed", %{
        goals: [{"invalid", "goal"}],  # Missing third element
        tasks: [],
        methods: []
      })

      initial_state = State.new()

      case WorkflowEngine.plan_workflow(workflow, initial_state) do
        {:error, _reason} ->
          # Expected to fail
          assert true

        {:ok, _execution} ->
          flunk("Expected planning to fail for malformed workflow")
      end
    end
  end

  describe "Background Execution" do
    test "background execution returns not implemented" do
      {:ok, workflow} = WorkflowEngine.get_workflow("basic_timing")
      initial_state = State.new()

      {:ok, execution} = WorkflowEngine.plan_workflow(workflow, initial_state)

      # Background execution should return not implemented for now
      assert {:error, :background_execution_not_implemented} =
        WorkflowEngine.execute_plan(execution, background: true)
    end
  end

  describe "Execution Monitoring" do
    test "execution status returns not implemented" do
      execution_ref = make_ref()

      assert {:error, :not_implemented} =
        WorkflowEngine.get_execution_status(execution_ref)
    end

    test "execution monitoring logs warning" do
      execution_ref = make_ref()
      callback = fn _status -> :ok end

      assert :ok = WorkflowEngine.monitor_execution(execution_ref, callback)
    end
  end
end
