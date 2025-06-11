# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

ExUnit.start()

# Configure test environment
ExUnit.configure(
  exclude: [:integration, :slow],
  formatters: [ExUnit.CLIFormatter],
  max_cases: System.schedulers_online() * 2,
  timeout: 30_000,
  trace: false
)

# Test helper functions for workflow testing
defmodule AriaWorkflow.TestHelpers do
  @moduledoc """
  Helper functions for workflow testing.
  """

  alias AriaEngine.State
  alias AriaWorkflow.{WorkflowDefinition, Span}

  @doc """
  Creates a test workflow definition.
  """
  def create_test_workflow(id, opts \\ []) do
    goals = Keyword.get(opts, :goals, [{"test", "system", "ready"}])
    tasks = Keyword.get(opts, :tasks, [{"test_task", &test_task/2}])
    methods = Keyword.get(opts, :methods, [])

    WorkflowDefinition.new(id, %{
      goals: goals,
      tasks: tasks,
      methods: methods,
      documentation: %{overview: "Test workflow"},
      metadata: %{version: "test", created_by: "test_helper"}
    })
  end

  @doc """
  Creates a test state with common predicates.
  """
  def create_test_state(facts \\ []) do
    state = State.new()

    Enum.reduce(facts, state, fn {pred, subj, obj}, acc ->
      State.set_object(acc, pred, subj, obj)
    end)
  end

  @doc """
  Test task function that always succeeds.
  """
  def test_task(state, args) do
    result = Map.merge(%{status: :success, task: "test_task"}, args)
    {:ok, state, result}
  end

  @doc """
  Test task function that always fails.
  """
  def failing_test_task(_state, args) do
    error = Map.get(args, :error, "Test failure")
    {:error, error}
  end

  @doc """
  Creates a test span with common attributes.
  """
  def create_test_span(name, opts \\ []) do
    attributes = Keyword.get(opts, :attributes, %{"test" => true})
    kind = Keyword.get(opts, :kind, :internal)

    Span.new(name, kind: kind, attributes: attributes)
  end

  @doc """
  Waits for a condition to be true with timeout.
  """
  def wait_until(fun, timeout \\ 1000) do
    wait_until(fun, timeout, 50)
  end

  defp wait_until(fun, timeout, interval) when timeout > 0 do
    if fun.() do
      :ok
    else
      :timer.sleep(interval)
      wait_until(fun, timeout - interval, interval)
    end
  end

  defp wait_until(_fun, _timeout, _interval) do
    {:error, :timeout}
  end

  @doc """
  Captures log messages during test execution.
  """
  def capture_logs(fun) do
    ExUnit.CaptureLog.capture_log(fun)
  end
end
