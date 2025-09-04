defmodule AriaInteractivity.FlowControl do
  @moduledoc """
  glTF Flow Control Operations Domain

  Implements flow control operations from glTF Interactivity Extension as planning domain methods.
  Supports sequence, branch, and loop constructs for complex workflow orchestration.

  Based on glTF Specification.adoc flow nodes
  """

  use AriaCore.ActionAttributes

  # ============================================================================
  # SEQUENCE OPERATIONS
  # ============================================================================

  # Sequence - n-to-n mapping of tasks to todo_items
  @task_method true
  @spec sequence(AriaState.t(), [term()]) :: {:ok, [AriaEngine.todo_item()]} | {:error, atom()}
  def sequence(state, tasks) do
    # Generate n-to-n mapping: each input task becomes a todo_item
    todo_items = Enum.map(tasks, fn task_spec ->
      case task_spec do
        {task_name, args} -> {:task, {task_name, args}}
        task_name when is_atom(task_name) -> {:task, {task_name, []}}
        _ -> {:task, {:execute_task, [task_spec]}}
      end
    end)

    {:ok, todo_items}
  end

  # ============================================================================
  # BRANCHING OPERATIONS
  # ============================================================================

  # Branch
  @task_method true
  @spec branch(AriaState.t(), [term]) :: {:ok, [AriaEngine.todo_item()]} | {:error, atom()}
  def branch(state, [condition, true_branch, false_branch]) do
    if condition do
      {:ok, [{:task, {:execute_branch, [true_branch]}}]}
    else
      {:ok, [{:task, {:execute_branch, [false_branch]}}]}
    end
  end

  # Switch/Case
  @task_method true
  @spec switch(AriaState.t(), [term]) :: {:ok, [AriaEngine.todo_item()]} | {:error, atom()}
  def switch(state, [value | cases]) do
    # Find matching case
    matching_case = Enum.find(cases, fn {case_value, _} -> case_value == value end)

    case matching_case do
      {_, task} -> {:ok, [{:task, {:execute_case, [task]}}]}
      nil ->
        # Default case - last element if it exists
        default_case = List.last(cases)
        case default_case do
          {_value, task} -> {:ok, [{:task, {:execute_case, [task]}}]}
          _ -> {:ok, []}
        end
    end
  end

  # ============================================================================
  # LOOP OPERATIONS
  # ============================================================================

  # While Loop
  @task_method true
  @spec while_loop(AriaState.t(), [term]) :: {:ok, [AriaEngine.todo_item()]} | {:error, atom()}
  def while_loop(state, [condition_fn, body_tasks]) do
    # For now, execute once - full loop logic would need state tracking
    {:ok, [{:task, {:execute_while_body, [body_tasks]}}]}
  end

  # For Loop
  @task_method true
  @spec for_loop(AriaState.t(), [term]) :: {:ok, [AriaEngine.todo_item()]} | {:error, atom()}
  def for_loop(state, [start, stop, step, body_tasks]) do
    # Generate iterations based on range
    iterations = Enum.take_every(start..stop, step)

    todo_items = Enum.map(iterations, fn i ->
      {:task, {:execute_iteration, [i, body_tasks]}}
    end)

    {:ok, todo_items}
  end

  # Repeat N Times
  @task_method true
  @spec repeat_n(AriaState.t(), [term]) :: {:ok, [AriaEngine.todo_item()]} | {:error, atom()}
  def repeat_n(state, [n, body_tasks]) do
    todo_items = Enum.map(1..n, fn i ->
      {:task, {:execute_iteration, [i, body_tasks]}}
    end)

    {:ok, todo_items}
  end

  # ============================================================================
  # MULTI-GATE OPERATIONS
  # ============================================================================

  # Wait All - wait for multiple conditions
  @task_method true
  @spec wait_all(AriaState.t(), [term]) :: {:ok, [AriaEngine.todo_item()]} | {:error, atom()}
  def wait_all(state, conditions) do
    # Create goals for each condition
    goals = Enum.map(conditions, fn condition ->
      {:condition_met, condition, true}
    end)

    {:ok, goals}
  end

  # Wait Any - wait for any of multiple conditions
  @task_method true
  @spec wait_any(AriaState.t(), [term]) :: {:ok, [AriaEngine.todo_item()]} | {:error, atom()}
  def wait_any(state, conditions) do
    # Create goals where any condition being met satisfies the requirement
    goals = Enum.map(conditions, fn condition ->
      {:condition_met, condition, true}
    end)

    {:ok, goals}
  end

  # ============================================================================
  # DELAY OPERATIONS
  # ============================================================================

  # Delay execution
  @task_method true
  @spec delay(AriaState.t(), [term]) :: {:ok, [AriaEngine.todo_item()]} | {:error, atom()}
  def delay(state, [duration, delayed_tasks]) do
    {:ok, [
      {:temporal_action, {:delay_execution, [duration, delayed_tasks]}}
    ]}
  end

  # Timeout
  @task_method true
  @spec timeout(AriaState.t(), [term]) :: {:ok, [AriaEngine.todo_item()]} | {:error, atom()}
  def timeout(state, [duration, timeout_tasks, normal_tasks]) do
    {:ok, [
      {:temporal_action, {:timeout_execution, [duration, timeout_tasks, normal_tasks]}}
    ]}
  end

  # ============================================================================
  # PARALLEL EXECUTION
  # ============================================================================

  # Parallel execution of multiple tasks
  @task_method true
  @spec parallel(AriaState.t(), [term]) :: {:ok, [AriaEngine.todo_item()]} | {:error, atom()}
  def parallel(state, task_groups) do
    # Flatten all tasks into parallel execution
    all_tasks = List.flatten(task_groups)

    todo_items = Enum.map(all_tasks, fn task_spec ->
      case task_spec do
        {task_name, args} -> {:task, {task_name, args}}
        task_name when is_atom(task_name) -> {:task, {task_name, []}}
        _ -> {:task, {:execute_task, [task_spec]}}
      end
    end)

    {:ok, todo_items}
  end

  # ============================================================================
  # CONDITIONAL EXECUTION
  # ============================================================================

  # Execute if condition is true
  @task_method true
  @spec execute_if(AriaState.t(), [term]) :: {:ok, [AriaEngine.todo_item()]} | {:error, atom()}
  def execute_if(state, [condition, true_tasks, false_tasks]) do
    if condition do
      {:ok, Enum.map(true_tasks, fn task -> {:task, {task, []}} end)}
    else
      {:ok, Enum.map(false_tasks, fn task -> {:task, {task, []}} end)}
    end
  end

  # Execute unless condition is true
  @task_method true
  @spec execute_unless(AriaState.t(), [term]) :: {:ok, [AriaEngine.todo_item()]} | {:error, atom()}
  def execute_unless(state, [condition, tasks]) do
    unless condition do
      {:ok, Enum.map(tasks, fn task -> {:task, {task, []}} end)}
    else
      {:ok, []}
    end
  end
end
