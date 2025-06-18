# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngine.GoalAPI do
  @moduledoc """
  Provides functions for managing goals within the Aria Engine.
  """
  alias AriaEngine.Core
  alias AriaEngine.State

  @type t :: Core.t()
  @type todo_item :: Core.todo_item()
  @type goal :: Core.goal()

  @doc """
  Sets the initial state for planning.
  """
  @spec set_initial_state(t(), State.t()) :: t()
  def set_initial_state(%Core{} = engine, %State{} = state) do
    %{engine | initial_state: state, current_state: state}
  end

  @doc """
  Adds a goal to the definition.
  """
  @spec add_goal(t(), todo_item()) :: t()
  def add_goal(%Core{goals: goals} = engine, goal) do
    %{engine | goals: goals ++ [goal]}
  end

  @doc """
  Adds multiple goals to the definition.
  """
  @spec add_goals(t(), [todo_item()]) :: t()
  def add_goals(%Core{goals: goals} = engine, new_goals) do
    %{engine | goals: goals ++ new_goals}
  end

  @doc """
  Sets goals (replaces existing goals).
  """
  @spec set_goals(t(), [todo_item()]) :: t()
  def set_goals(%Core{} = engine, goals) do
    %{engine | goals: goals}
  end

  @doc """
  Creates a goal from predicate, subject, and fact_value.
  """
  @spec create_goal(String.t(), String.t(), State.fact_value()) :: goal()
  def create_goal(predicate, subject, fact_value) do
    {predicate, subject, fact_value}
  end

  @doc """
  Creates a task from name and arguments.
  """
  @spec create_task(String.t(), list()) :: Core.task()
  def create_task(name, args \\ []) do
    {name, args}
  end

  @doc """
  Validates whether goals are satisfied in the given state.
  """
  @spec goals_satisfied?(State.t(), [goal()]) :: boolean()
  def goals_satisfied?(%State{} = state, goals) do
    Enum.all?(goals, fn {predicate, subject, fact_value} ->
      State.get_fact(state, predicate, subject) == fact_value
    end)
  end
end
