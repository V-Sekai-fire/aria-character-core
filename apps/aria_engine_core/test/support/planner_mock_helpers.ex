# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngineCore.Mocks.PlannerMockHelpers do
  @moduledoc """
  Helper functions for setting up planner mocks in tests.
  """

  import Mox
  alias AriaEngineCore.Mocks.PlannerMock

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
      {:ok, %{}}
    end)
  end

  def expect_successful_planning do
    setup_successful_planning_mock()
  end

  def expect_planning_failure(reason) do
    expect(PlannerMock, :new_coordinator, fn -> :mock_coordinator end)
    expect(PlannerMock, :plan, fn _coordinator, _domain, _state, _goals ->
      {:error, reason}
    end)
  end

  def expect_planning_failure_for_run_lazy(reason) do
    expect(PlannerMock, :new_coordinator, fn -> :mock_coordinator end)
    expect(PlannerMock, :plan, fn _coordinator, _domain, _state, _goals ->
      {:error, reason}
    end)
  end

  def expect_coordinator_creation_failure do
    expect(PlannerMock, :new_coordinator, fn ->
      raise RuntimeError, "Mock coordinator creation failure"
    end)
  end

  def expect_custom_planning(custom_plan, final_state) do
    expect(PlannerMock, :new_coordinator, 2, fn -> :mock_coordinator end)
    expect(PlannerMock, :plan, fn _coordinator, _domain, _state, _goals ->
      {:ok, custom_plan}
    end)
    expect(PlannerMock, :execute, fn _coordinator, _domain, _state, _solution_tree ->
      {:ok, final_state}
    end)
  end

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

  def setup_execution_timeout_mock do
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
      {:error, :action_timeout}
    end)
  end
end
