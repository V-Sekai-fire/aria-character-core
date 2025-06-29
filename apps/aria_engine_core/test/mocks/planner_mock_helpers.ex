# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngineCore.Mocks.PlannerMockHelpers do
  @moduledoc """
  Helper functions for setting up planner mocks in tests.

  This module provides convenience functions for configuring mock expectations
  and creating test data structures for planner testing.
  """

  import Mox
  alias AriaEngineCore.Mocks.PlannerMock

  @doc """
  Sets up a successful planning mock that returns a solution tree.
  For plan/3 only (1 coordinator call).
  """
  def setup_successful_planning_mock do
    expect(PlannerMock, :new_coordinator, fn -> :mock_coordinator end)
    expect(PlannerMock, :plan, fn _coordinator, _domain, _state, _goals ->
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

  @doc """
  Sets up a successful planning mock for run_lazy/3 (2 coordinator calls).
  """
  def setup_successful_run_lazy_mock do
    expect(PlannerMock, :new_coordinator, 2, fn -> :mock_coordinator end)
    expect(PlannerMock, :plan, fn _coordinator, _domain, _state, _goals ->
      {:ok, %{
        "type" => "solution_tree",
        "root_id" => "root",
        "actions" => [
          %{"name" => "action1", "args" => ["arg1"]},
          %{"name" => "action2", "args" => ["arg2"]}
        ]
      }}
    end)
    expect(PlannerMock, :execute, fn _coordinator, _domain, _state, _solution_tree ->
      {:ok, AriaEngineCore.State.new()}
    end)
  end

  @doc """
  Sets up a planning failure mock that returns an error.
  """
  def setup_planning_failure_mock do
    expect(PlannerMock, :new_coordinator, fn -> :mock_coordinator end)
    expect(PlannerMock, :plan, fn _coordinator, _domain, _state, _goals ->
      {:error, "Planning failed"}
    end)
  end

  @doc """
  Sets up a successful execution mock.
  """
  def setup_successful_execution_mock do
    expect(PlannerMock, :execute, fn _coordinator, _domain, _state, _solution_tree ->
      {:ok, AriaEngineCore.State.new()}
    end)
  end

  @doc """
  Sets up an execution failure mock.
  """
  def setup_execution_failure_mock do
    expect(PlannerMock, :execute, fn _coordinator, _domain, _state, _solution_tree ->
      {:error, :execution_failed}
    end)
  end

  @doc """
  Sets up a coordinator creation failure mock.
  """
  def setup_coordinator_failure_mock do
    expect(PlannerMock, :new_coordinator, fn ->
      raise RuntimeError, "Mock coordinator creation failure"
    end)
  end

  @doc """
  Sets up a planning exception mock.
  """
  def setup_planning_exception_mock do
    expect(PlannerMock, :new_coordinator, fn -> :mock_coordinator end)
    expect(PlannerMock, :plan, fn _coordinator, _domain, _state, _goals ->
      raise RuntimeError, "Mock planning exception"
    end)
  end

  @doc """
  Sets up an execution exception mock.
  """
  def setup_execution_exception_mock do
    expect(PlannerMock, :execute, fn _coordinator, _domain, _state, _solution_tree ->
      raise RuntimeError, "Mock execution exception"
    end)
  end

  @doc """
  Creates a sample domain for testing.
  """
  def create_test_domain do
    AriaEngineCore.Domain.Core.new("test_domain")
  end

  @doc """
  Creates a sample state for testing.
  """
  def create_test_state do
    AriaEngineCore.State.new()
    |> AriaEngineCore.State.set_fact("location", "player", "room1")
    |> AriaEngineCore.State.set_fact("has", "player", "sword")
  end

  @doc """
  Creates sample goals for testing.
  """
  def create_test_goals do
    [{"achieve", "location", "player", "room2"}]
  end

  @doc """
  Creates a sample solution tree for testing.
  """
  def create_test_solution_tree do
    %{
      "type" => "solution_tree",
      "root_id" => "root",
      "actions" => [
        %{"name" => "action1", "args" => ["arg1"]},
        %{"name" => "action2", "args" => ["arg2"]}
      ]
    }
  end

  @doc """
  Creates a failing solution tree for testing execution failures.
  """
  def create_failing_solution_tree do
    %{
      "type" => "solution_tree",
      "root_id" => "root",
      "actions" => [
        %{"name" => "failing_action", "args" => []}
      ]
    }
  end

  @doc """
  Sets up successful planning expectations.
  """
  def expect_successful_planning do
    setup_successful_planning_mock()
  end

  @doc """
  Sets up planning failure expectations with a specific reason.
  """
  def expect_planning_failure(reason) do
    expect(PlannerMock, :new_coordinator, fn -> :mock_coordinator end)
    expect(PlannerMock, :plan, fn _coordinator, _domain, _state, _goals ->
      {:error, reason}
    end)
  end

  @doc """
  Sets up execution failure expectations with a specific reason.
  """
  def expect_execution_failure(reason) do
    expect(PlannerMock, :new_coordinator, 2, fn -> :mock_coordinator end)
    expect(PlannerMock, :plan, fn _coordinator, _domain, _state, _goals ->
      {:ok, %{
        "type" => "solution_tree",
        "root_id" => "root",
        "actions" => [
          %{"name" => "action1", "args" => ["arg1"]},
          %{"name" => "action2", "args" => ["arg2"]}
        ]
      }}
    end)
    expect(PlannerMock, :execute, fn _coordinator, _domain, _state, _solution_tree ->
      {:error, reason}
    end)
  end

  @doc """
  Sets up coordinator creation failure expectations.
  """
  def expect_coordinator_creation_failure do
    setup_coordinator_failure_mock()
  end

  @doc """
  Sets up custom planning expectations with specific plan and final state.
  """
  def expect_custom_planning(custom_plan, final_state) do
    expect(PlannerMock, :new_coordinator, 2, fn -> :mock_coordinator end)
    expect(PlannerMock, :plan, fn _coordinator, _domain, _state, _goals ->
      {:ok, custom_plan}
    end)
    expect(PlannerMock, :execute, fn _coordinator, _domain, _state, _solution_tree ->
      {:ok, final_state}
    end)
  end

  @doc """
  Sets up multiple planning call expectations with different outcomes.
  """
  def expect_multiple_planning_calls(outcomes) do
    expect(PlannerMock, :new_coordinator, length(outcomes), fn -> :mock_coordinator end)

    for outcome <- outcomes do
      case outcome do
        {:success, plan} ->
          expect(PlannerMock, :plan, fn _coordinator, _domain, _state, _goals ->
            {:ok, plan}
          end)
        {:failure, reason} ->
          expect(PlannerMock, :plan, fn _coordinator, _domain, _state, _goals ->
            {:error, reason}
          end)
        {:error, reason} ->
          expect(PlannerMock, :plan, fn _coordinator, _domain, _state, _goals ->
            {:error, reason}
          end)
        {:ok, plan} ->
          expect(PlannerMock, :plan, fn _coordinator, _domain, _state, _goals ->
            {:ok, plan}
          end)
      end
    end
  end
end
