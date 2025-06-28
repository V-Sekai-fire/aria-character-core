# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngineCore.Mocks.PlannerMockHelpers do
  @moduledoc """
  Helper functions for setting up planner mocks in tests.

  This module provides convenient functions for configuring the PlannerMock
  with common scenarios, making tests easier to write and maintain.

  ## Usage

      import AriaEngineCore.Mocks.PlannerMockHelpers

      test "successful planning" do
        expect_successful_planning()

        {:ok, solution_tree} = AriaEngineCore.plan(domain, state, goals)
        assert solution_tree != nil
      end

  ## Mock Scenarios

  - `expect_successful_planning/1` - Mock successful planning and execution
  - `expect_planning_failure/2` - Mock planning failure with specific reason
  - `expect_execution_failure/2` - Mock execution failure with specific reason
  - `expect_coordinator_creation_failure/1` - Mock coordinator creation failure
  """

  import Mox

  @mock_module AriaEngineCore.Mocks.PlannerMock

  @doc """
  Set up mock expectations for successful planning and execution.

  This is the most common test scenario where all operations succeed.

  ## Parameters

  - `mock` - Mock module (defaults to PlannerMock)

  ## Example

      test "successful planning workflow" do
        expect_successful_planning()

        {:ok, {final_state, solution_tree}} = AriaEngineCore.run_lazy(domain, state, goals)
        assert final_state != nil
        assert solution_tree != nil
      end
  """
  @spec expect_successful_planning(module()) :: :ok
  def expect_successful_planning(mock \\ @mock_module) do
    expect(mock, :new_coordinator, fn -> :mock_coordinator end)

    expect(mock, :plan, fn _coordinator, _domain, _state, _goals ->
      {:ok, %{
        "actions" => [
          %{"name" => "mock_action_1", "args" => ["arg1"]},
          %{"name" => "mock_action_2", "args" => ["arg2"]}
        ],
        "metadata" => %{"planning_time" => 0.1}
      }}
    end)

    expect(mock, :execute, fn _coordinator, _domain, _state, _plan ->
      {:ok, :mock_final_state}
    end)

    :ok
  end

  @doc """
  Set up mock expectations for planning failure.

  ## Parameters

  - `reason` - Atom describing the failure reason
  - `mock` - Mock module (defaults to PlannerMock)

  ## Example

      test "planning failure handling" do
        expect_planning_failure(:no_solution_found)

        {:error, :planning_failed} = AriaEngineCore.plan(domain, state, goals)
      end
  """
  @spec expect_planning_failure(atom(), module()) :: :ok
  def expect_planning_failure(reason, mock \\ @mock_module) do
    expect(mock, :new_coordinator, fn -> :mock_coordinator end)

    expect(mock, :plan, fn _coordinator, _domain, _state, _goals ->
      {:error, reason}
    end)

    :ok
  end

  @doc """
  Set up mock expectations for execution failure.

  Planning succeeds but execution fails with the specified reason.

  ## Parameters

  - `reason` - Atom describing the execution failure reason
  - `mock` - Mock module (defaults to PlannerMock)

  ## Example

      test "execution failure handling" do
        expect_execution_failure(:action_failed)

        {:error, :action_failed} = AriaEngineCore.run_lazy(domain, state, goals)
      end
  """
  @spec expect_execution_failure(atom(), module()) :: :ok
  def expect_execution_failure(reason, mock \\ @mock_module) do
    expect(mock, :new_coordinator, fn -> :mock_coordinator end)

    expect(mock, :plan, fn _coordinator, _domain, _state, _goals ->
      {:ok, %{"actions" => [%{"name" => "failing_action", "args" => []}]}}
    end)

    expect(mock, :execute, fn _coordinator, _domain, _state, _plan ->
      {:error, reason}
    end)

    :ok
  end

  @doc """
  Set up mock expectations for coordinator creation failure.

  ## Parameters

  - `mock` - Mock module (defaults to PlannerMock)

  ## Example

      test "coordinator creation failure" do
        expect_coordinator_creation_failure()

        assert_raise RuntimeError, fn ->
          AriaEngineCore.plan(domain, state, goals)
        end
      end
  """
  @spec expect_coordinator_creation_failure(module()) :: :ok
  def expect_coordinator_creation_failure(mock \\ @mock_module) do
    expect(mock, :new_coordinator, fn ->
      raise "Mock coordinator creation failure"
    end)

    :ok
  end

  @doc """
  Set up mock expectations for multiple planning calls.

  Useful for testing scenarios where planning is called multiple times
  with different results.

  ## Parameters

  - `results` - List of tuples `{:ok, plan}` or `{:error, reason}`
  - `mock` - Mock module (defaults to PlannerMock)

  ## Example

      test "multiple planning attempts" do
        expect_multiple_planning_calls([
          {:error, :no_solution},
          {:ok, %{"actions" => []}}
        ])

        # First call fails
        {:error, :planning_failed} = AriaEngineCore.plan(domain, state, goals)

        # Second call succeeds
        {:ok, solution_tree} = AriaEngineCore.plan(domain, state, goals)
      end
  """
  @spec expect_multiple_planning_calls([{:ok, map()} | {:error, atom()}], module()) :: :ok
  def expect_multiple_planning_calls(results, mock \\ @mock_module) do
    # Set up coordinator creation for each call
    Enum.each(results, fn _ ->
      expect(mock, :new_coordinator, fn -> :mock_coordinator end)
    end)

    # Set up planning results in sequence
    Enum.each(results, fn result ->
      expect(mock, :plan, fn _coordinator, _domain, _state, _goals ->
        result
      end)
    end)

    :ok
  end

  @doc """
  Set up mock expectations with custom plan data.

  Allows testing with specific plan structures.

  ## Parameters

  - `plan_data` - Custom plan data structure
  - `final_state` - Expected final state after execution
  - `mock` - Mock module (defaults to PlannerMock)

  ## Example

      test "custom plan execution" do
        custom_plan = %{
          "actions" => [%{"name" => "custom_action", "args" => ["custom_arg"]}],
          "metadata" => %{"custom_field" => "custom_value"}
        }

        expect_custom_planning(custom_plan, :custom_final_state)

        {:ok, {final_state, _}} = AriaEngineCore.run_lazy(domain, state, goals)
        assert final_state == :custom_final_state
      end
  """
  @spec expect_custom_planning(map(), any(), module()) :: :ok
  def expect_custom_planning(plan_data, final_state, mock \\ @mock_module) do
    expect(mock, :new_coordinator, fn -> :mock_coordinator end)

    expect(mock, :plan, fn _coordinator, _domain, _state, _goals ->
      {:ok, plan_data}
    end)

    expect(mock, :execute, fn _coordinator, _domain, _state, _plan ->
      {:ok, final_state}
    end)

    :ok
  end

  @doc """
  Verify that all expected mock calls were made.

  Call this at the end of tests to ensure all expectations were satisfied.

  ## Parameters

  - `mock` - Mock module (defaults to PlannerMock)

  ## Example

      test "planning workflow" do
        expect_successful_planning()

        AriaEngineCore.plan(domain, state, goals)

        verify_mock_calls()
      end
  """
  @spec verify_mock_calls(module()) :: :ok
  def verify_mock_calls(mock \\ @mock_module) do
    verify!(mock)
    :ok
  end
end
