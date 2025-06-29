# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngineCore.PlannerTest do
  @moduledoc """
  Tests for AriaEngineCore.Planner with Mox-based dependency injection.

  This test suite demonstrates how to test the planner functionality
  without depending on the actual AriaHybridPlanner.Core implementation.
  """

  use ExUnit.Case, async: true
  import Mox

  # Define the mock for this test module
  Mox.defmock(AriaEngineCore.Mocks.PlannerMock,
    for: AriaEngineCore.Behaviours.PlannerBehaviour)

  # Make sure mocks are verified when the test exits
  setup :verify_on_exit!

  # Helper functions for setting up mocks
  defp expect_successful_planning do
    expect(AriaEngineCore.Mocks.PlannerMock, :new_coordinator, fn -> :mock_coordinator end)
    expect(AriaEngineCore.Mocks.PlannerMock, :plan, fn _coordinator, _domain, _state, _goals ->
      {:ok, %{
        "type" => "solution_tree",
        "root_id" => "root",
        "actions" => [
          %{"name" => "action1", "args" => ["arg1"]},
          %{"name" => "action2", "args" => ["arg2"]}
        ]
      }}
    end)
  end

  defp expect_planning_failure(reason) do
    expect(AriaEngineCore.Mocks.PlannerMock, :new_coordinator, fn -> :mock_coordinator end)
    expect(AriaEngineCore.Mocks.PlannerMock, :plan, fn _coordinator, _domain, _state, _goals ->
      {:error, reason}
    end)
  end

  defp expect_coordinator_creation_failure do
    expect(AriaEngineCore.Mocks.PlannerMock, :new_coordinator, fn ->
      raise RuntimeError, "Mock coordinator creation failure"
    end)
  end

  defp setup_successful_run_lazy_mock do
    expect(AriaEngineCore.Mocks.PlannerMock, :new_coordinator, 2, fn -> :mock_coordinator end)
    expect(AriaEngineCore.Mocks.PlannerMock, :plan, fn _coordinator, _domain, _state, _goals ->
      {:ok, %{
        "type" => "solution_tree",
        "root_id" => "root",
        "actions" => [
          %{"name" => "action1", "args" => ["arg1"]},
          %{"name" => "action2", "args" => ["arg2"]}
        ]
      }}
    end)
    expect(AriaEngineCore.Mocks.PlannerMock, :execute, fn _coordinator, _domain, _state, _solution_tree ->
      {:ok, %{}}
    end)
  end

  defp expect_planning_failure_for_run_lazy(reason) do
    expect(AriaEngineCore.Mocks.PlannerMock, :new_coordinator, fn -> :mock_coordinator end)
    expect(AriaEngineCore.Mocks.PlannerMock, :plan, fn _coordinator, _domain, _state, _goals ->
      {:error, reason}
    end)
  end

  defp setup_execution_timeout_mock do
    expect(AriaEngineCore.Mocks.PlannerMock, :new_coordinator, 2, fn -> :mock_coordinator end)
    expect(AriaEngineCore.Mocks.PlannerMock, :plan, fn _coordinator, _domain, _state, _goals ->
      {:ok, %{
        "type" => "solution_tree",
        "root_id" => "root",
        "actions" => [
          %{"name" => "action1", "args" => ["arg1"]},
          %{"name" => "action2", "args" => ["arg2"]}
        ]
      }}
    end)
    expect(AriaEngineCore.Mocks.PlannerMock, :execute, fn _coordinator, _domain, _state, _solution_tree ->
      {:error, :action_timeout}
    end)
  end

  defp expect_custom_planning(custom_plan, final_state) do
    expect(AriaEngineCore.Mocks.PlannerMock, :new_coordinator, 2, fn -> :mock_coordinator end)
    expect(AriaEngineCore.Mocks.PlannerMock, :plan, fn _coordinator, _domain, _state, _goals ->
      {:ok, custom_plan}
    end)
    expect(AriaEngineCore.Mocks.PlannerMock, :execute, fn _coordinator, _domain, _state, _solution_tree ->
      {:ok, final_state}
    end)
  end

  defp expect_multiple_planning_calls(outcomes) do
    expect(AriaEngineCore.Mocks.PlannerMock, :new_coordinator, length(outcomes), fn -> :mock_coordinator end)

    for outcome <- outcomes do
      case outcome do
        {:success, plan} ->
          expect(AriaEngineCore.Mocks.PlannerMock, :plan, fn _coordinator, _domain, _state, _goals ->
            {:ok, plan}
          end)
        {:failure, reason} ->
          expect(AriaEngineCore.Mocks.PlannerMock, :plan, fn _coordinator, _domain, _state, _goals ->
            {:error, reason}
          end)
        {:error, reason} ->
          expect(AriaEngineCore.Mocks.PlannerMock, :plan, fn _coordinator, _domain, _state, _goals ->
            {:error, reason}
          end)
        {:ok, plan} ->
          expect(AriaEngineCore.Mocks.PlannerMock, :plan, fn _coordinator, _domain, _state, _goals ->
            {:ok, plan}
          end)
      end
    end
  end

  # Set up the mock for this test module
  setup do
    # Configure the test environment to use our mock
    Application.put_env(:aria_engine_core, :planner_adapter, AriaEngineCore.Mocks.PlannerMock)

    on_exit(fn ->
      # Reset to default adapter after tests
      Application.put_env(:aria_engine_core, :planner_adapter, AriaEngineCore.Adapters.HybridPlannerAdapter)
    end)

    # Create mock domain and state for tests
    domain = %AriaEngineCore.Domain.Core{name: "test_domain"}
    state = AriaEngineCore.State.new()
    goals = [{"achieve", "goal1", "value1"}]

    %{domain: domain, state: state, goals: goals}
  end

  describe "plan/3" do
    test "successful planning returns solution tree", %{domain: domain, state: state, goals: goals} do
      expect(AriaEngineCore.Mocks.PlannerMock, :new_coordinator, fn -> :mock_coordinator end)
      expect(AriaEngineCore.Mocks.PlannerMock, :plan, fn _coordinator, _domain, _state, _goals ->
        {:ok, %{
          "type" => "solution_tree",
          "root_id" => "root",
          "actions" => [
            %{"name" => "action1", "args" => ["arg1"]},
            %{"name" => "action2", "args" => ["arg2"]}
          ]
        }}
      end)

      {:ok, solution_tree} = AriaEngineCore.Planner.plan(domain, state, goals)

      assert solution_tree != nil
      # Verify the solution tree structure is created properly
      assert is_map(solution_tree) or is_list(solution_tree)
    end

    test "planning failure returns error", %{domain: domain, state: state, goals: goals} do
      expect_planning_failure(:no_solution_found)

      {:error, :planning_failed} = AriaEngineCore.Planner.plan(domain, state, goals)
    end

    test "coordinator creation failure returns error", %{domain: domain, state: state, goals: goals} do
      expect_coordinator_creation_failure()

      {:error, :planning_error} = AriaEngineCore.Planner.plan(domain, state, goals)
    end

    test "handles empty goals list", %{domain: domain, state: state} do
      expect_successful_planning()

      {:ok, solution_tree} = AriaEngineCore.Planner.plan(domain, state, [])

      assert solution_tree != nil
    end
  end

  describe "run_lazy/3" do
    test "successful planning and execution", %{domain: domain, state: state, goals: goals} do
      setup_successful_run_lazy_mock()

      {:ok, {final_state, solution_tree}} = AriaEngineCore.Planner.run_lazy(domain, state, goals)

      assert final_state != nil
      assert solution_tree != nil
    end

    test "planning failure prevents execution", %{domain: domain, state: state, goals: goals} do
      expect_planning_failure_for_run_lazy(:insufficient_resources)

      {:error, :planning_failed} = AriaEngineCore.Planner.run_lazy(domain, state, goals)
    end

    test "execution failure after successful planning", %{domain: domain, state: state, goals: goals} do
      setup_execution_timeout_mock()

      {:error, :action_timeout} = AriaEngineCore.Planner.run_lazy(domain, state, goals)
    end
  end

  describe "run_lazy_tree/3" do
    test "executes pre-made solution tree", %{domain: domain, state: state} do
      # Create a mock solution tree
      solution_tree = %{
        "type" => "solution_tree",
        "actions" => [
          %{"name" => "action1", "args" => ["arg1"]},
          %{"name" => "action2", "args" => ["arg2"]}
        ]
      }

      # Set up expectations for execution only (no planning)
      expect(AriaEngineCore.Mocks.PlannerMock, :new_coordinator, fn -> :mock_coordinator end)
      expect(AriaEngineCore.Mocks.PlannerMock, :execute, fn _coordinator, _domain, _state, _plan ->
        {:ok, :executed_final_state}
      end)

      {:ok, {final_state, updated_tree}} = AriaEngineCore.Planner.run_lazy_tree(domain, state, solution_tree)

      assert final_state == :executed_final_state
      assert updated_tree != nil
    end

    test "execution failure with pre-made tree", %{domain: domain, state: state} do
      solution_tree = %{"actions" => [%{"name" => "failing_action", "args" => []}]}

      expect(AriaEngineCore.Mocks.PlannerMock, :new_coordinator, fn -> :mock_coordinator end)
      expect(AriaEngineCore.Mocks.PlannerMock, :execute, fn _coordinator, _domain, _state, _plan ->
        {:error, :execution_failed}
      end)

      {:error, :execution_failed} = AriaEngineCore.Planner.run_lazy_tree(domain, state, solution_tree)
    end
  end

  describe "custom planning scenarios" do
    test "planning with custom plan structure", %{domain: domain, state: state, goals: goals} do
      custom_plan = %{
        "actions" => [
          %{"name" => "custom_action", "args" => ["custom_arg"]},
          %{"name" => "another_action", "args" => ["arg1", "arg2"]}
        ],
        "metadata" => %{
          "planning_time" => 0.5,
          "complexity" => "high",
          "resource_usage" => %{"cpu" => 0.8, "memory" => 0.6}
        }
      }

      expect_custom_planning(custom_plan, :custom_final_state)

      {:ok, {final_state, solution_tree}} = AriaEngineCore.Planner.run_lazy(domain, state, goals)

      assert final_state == :custom_final_state
      assert solution_tree != nil
    end

    test "multiple planning attempts with different outcomes", %{domain: domain, state: state, goals: goals} do
      expect_multiple_planning_calls([
        {:error, :resource_unavailable},
        {:error, :timeout},
        {:ok, %{"actions" => [%{"name" => "success_action", "args" => []}]}}
      ])

      # First attempt fails
      {:error, :planning_failed} = AriaEngineCore.Planner.plan(domain, state, goals)

      # Second attempt also fails
      {:error, :planning_failed} = AriaEngineCore.Planner.plan(domain, state, goals)

      # Third attempt succeeds
      {:ok, solution_tree} = AriaEngineCore.Planner.plan(domain, state, goals)
      assert solution_tree != nil
    end
  end

  describe "error handling and edge cases" do
    test "handles malformed goals gracefully", %{domain: domain, state: state} do
      malformed_goals = [
        "invalid_goal_format",
        {:incomplete, "tuple"},
        %{"invalid" => "goal_map"}
      ]

      expect_successful_planning()

      {:ok, solution_tree} = AriaEngineCore.Planner.plan(domain, state, malformed_goals)
      assert solution_tree != nil
    end

    test "handles nil domain gracefully", %{state: state, goals: goals} do
      expect_successful_planning()

      {:ok, solution_tree} = AriaEngineCore.Planner.plan(nil, state, goals)
      assert solution_tree != nil
    end

    test "handles nil state gracefully", %{domain: domain, goals: goals} do
      expect_successful_planning()

      {:ok, solution_tree} = AriaEngineCore.Planner.plan(domain, nil, goals)
      assert solution_tree != nil
    end

    test "planning exception is caught and converted to error", %{domain: domain, state: state, goals: goals} do
      expect(AriaEngineCore.Mocks.PlannerMock, :new_coordinator, fn -> :mock_coordinator end)
      expect(AriaEngineCore.Mocks.PlannerMock, :plan, fn _coordinator, _domain, _state, _goals ->
        raise "Unexpected planning exception"
      end)

      {:error, :planning_error} = AriaEngineCore.Planner.plan(domain, state, goals)
    end

    test "execution exception is caught and converted to error", %{domain: domain, state: state, goals: goals} do
      expect(AriaEngineCore.Mocks.PlannerMock, :new_coordinator, 2, fn -> :mock_coordinator end)
      expect(AriaEngineCore.Mocks.PlannerMock, :plan, fn _coordinator, _domain, _state, _goals ->
        {:ok, %{"actions" => []}}
      end)
      expect(AriaEngineCore.Mocks.PlannerMock, :execute, fn _coordinator, _domain, _state, _plan ->
        raise "Unexpected execution exception"
      end)

      {:error, :execution_error} = AriaEngineCore.Planner.run_lazy(domain, state, goals)
    end
  end

  describe "integration with AriaEngineCore main module" do
    test "AriaEngineCore.plan/3 uses injected adapter", %{domain: domain, state: state, goals: goals} do
      expect_successful_planning()

      {:ok, solution_tree} = AriaEngineCore.plan(domain, state, goals)
      assert solution_tree != nil
    end

    test "AriaEngineCore.run_lazy/3 uses injected adapter", %{domain: domain, state: state, goals: goals} do
      setup_successful_run_lazy_mock()

      {:ok, {final_state, solution_tree}} = AriaEngineCore.run_lazy(domain, state, goals)
      assert final_state != nil
      assert solution_tree != nil
    end

    test "AriaEngineCore.run_lazy_tree/3 uses injected adapter", %{domain: domain, state: state} do
      solution_tree = %{"actions" => []}

      expect(AriaEngineCore.Mocks.PlannerMock, :new_coordinator, fn -> :mock_coordinator end)
      expect(AriaEngineCore.Mocks.PlannerMock, :execute, fn _coordinator, _domain, _state, _plan ->
        {:ok, :tree_execution_state}
      end)

      {:ok, {final_state, updated_tree}} = AriaEngineCore.run_lazy_tree(domain, state, solution_tree)
      assert final_state == :tree_execution_state
      assert updated_tree != nil
    end
  end
end
