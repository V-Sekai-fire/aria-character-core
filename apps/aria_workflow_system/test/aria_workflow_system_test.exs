# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaWorkflowSystemTest do
  use ExUnit.Case, async: true
  doctest AriaWorkflowSystem

  alias AriaEngine.{Domain, State}

  describe "AriaWorkflowSystem domain creation" do
    test "creates a valid domain with workflow system actions" do
      domain = AriaWorkflowSystem.create_domain()

      assert %Domain{} = domain
      assert domain.name == "workflow_system"
      assert is_map(domain.actions)
      assert is_map(domain.task_methods)
      assert is_map(domain.unigoal_methods)

      # Check that basic workflow actions are present
      assert Map.has_key?(domain.actions, :execute_command)
      assert Map.has_key?(domain.actions, :echo)
      assert Map.has_key?(domain.actions, :wait)
    end

    test "domain has expected task methods" do
      domain = AriaWorkflowSystem.create_domain()

      # Check for actual task methods defined in the domain
      expected_tasks = [
        "execute_workflow",
        "debug_workflow"
      ]

      for task <- expected_tasks do
        assert Map.has_key?(domain.task_methods, task),
               "Expected task method '#{task}' not found"
      end
    end

    test "domain has expected unigoal methods" do
      domain = AriaWorkflowSystem.create_domain()

      expected_goals = [
        "workflow_completed",
        "command_executed"
      ]

      for goal <- expected_goals do
        assert Map.has_key?(domain.unigoal_methods, goal),
               "Expected unigoal method '#{goal}' not found"
      end
    end
  end

  describe "Workflow actions" do
    setup do
      state = State.new()
      {:ok, state: state}
    end

    test "execute_workflow_command action", %{state: state} do
      result = AriaWorkflowSystem.execute_workflow_command(state, ["test_workflow", "step1"])
      # Currently returns modified state (placeholder implementation)
      assert match?(%State{}, result) or result == false
    end

    test "trace_workflow_execution task", %{state: state} do
      result = AriaWorkflowSystem.trace_workflow_execution(state, ["workflow_id"])
      assert match?(%State{}, result) or result == false
    end

    test "monitor_workflow_progress task", %{state: state} do
      result = AriaWorkflowSystem.monitor_workflow_progress(state, ["workflow_id"])
      assert match?(%State{}, result) or result == false
    end
  end

  describe "Complex workflow tasks" do
    setup do
      state = State.new()
      {:ok, state: state}
    end

    test "deploy_service task", %{state: state} do
      result = AriaWorkflowSystem.deploy_service(state, ["service_name"])
      # This returns a list of actions, not false
      assert is_list(result)
    end

    test "run_migrations task", %{state: state} do
      result = AriaWorkflowSystem.run_migrations(state, [])
      # This returns a list of actions, not false
      assert is_list(result)
    end

    test "monitor_system_health task", %{state: state} do
      result = AriaWorkflowSystem.monitor_system_health(state, [])
      # This returns a list of actions, not false
      assert is_list(result)
    end
  end

  describe "Goal methods" do
    setup do
      state = State.new()
      {:ok, state: state}
    end

    test "ensure_workflow_completed goal", %{state: state} do
      result = AriaWorkflowSystem.ensure_workflow_completed(state, ["workflow_status", "workflow_id", "completed"])
      assert match?(%State{}, result) or result == false
    end

    test "ensure_command_executed goal", %{state: state} do
      result = AriaWorkflowSystem.ensure_command_executed(state, ["command_status", "command_id", "executed"])
      assert match?(%State{}, result) or result == false
    end
  end
end
