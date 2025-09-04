defmodule AriaInteractivity.Domain do
  @moduledoc """
  glTF Interactivity Domain for IPyHOP Planning

  This module defines the planning domain based on the glTF Interactivity
  Extension Specification, mapping nodes to IPyHOP actions, commands, and methods.
  """

  use AriaCore.ActionAttributes

  # Math Operations - Action/Command pairs
  @action def math_add(a, b), do: {:ok, a + b}
  @command def math_add(a, b), do: a + b

  @action def math_subtract(a, b), do: {:ok, a - b}
  @command def math_subtract(a, b), do: a - b

  @action def math_multiply(a, b), do: {:ok, a * b}
  @command def math_multiply(a, b), do: a * b

  # Control Flow Operations - Task Methods
  @task_method def flow_sequence(tasks) do
    # Decompose sequence into individual tasks
    Enum.map(tasks, fn task -> {:task, task} end)
  end

  @task_method def flow_branch(condition, branches) do
    # Conditional task decomposition
    case condition do
      true -> [{:task, branches.true}]
      false -> [{:task, branches.false}]
    end
  end

  # State Operations - Unigoal Methods
  @unigoal_method def variable_set(goal) do
    # Achieve goal by setting variable
    {:variable_set, goal.variable, goal.value}
  end

  @unigoal_method def pointer_get(goal) do
    # Achieve goal by getting pointer value
    {:pointer_get, goal.pointer}
  end

  # Placeholder for additional operations to be implemented
  # - Animation operations (multigoal methods)
  # - Event operations (multitodo methods)
  # - Temporal operations with duration constraints
end
