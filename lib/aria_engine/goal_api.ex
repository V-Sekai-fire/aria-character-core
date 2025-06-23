defmodule GoalAPI do
  @moduledoc "Provides functions for managing goals within the Aria Engine.\n"
  alias Core
  @type t :: Core.t()
  @type todo_item :: Core.todo_item()
  @type goal :: Core.goal()
  @doc "Sets the initial state for planning.\n"
  @spec set_initial_state(t(), AriaEngine.State.t()) :: t()
  def set_initial_state(%Core{} = engine, %AriaEngine.State{} = state) do
    %{engine | initial_state: state, current_state: state}
  end

  @doc "Adds a goal to the definition.\n"
  @spec add_goal(t(), todo_item()) :: t()
  def add_goal(%Core{goals: goals} = engine, goal) do
    %{engine | goals: goals ++ [goal]}
  end

  @doc "Adds multiple goals to the definition.\n"
  @spec add_goals(t(), [todo_item()]) :: t()
  def add_goals(%Core{goals: goals} = engine, new_goals) do
    %{engine | goals: goals ++ new_goals}
  end

  @doc "Sets goals (replaces existing goals).\n"
  @spec set_goals(t(), [todo_item()]) :: t()
  def set_goals(%Core{} = engine, goals) do
    %{engine | goals: goals}
  end

  @doc "Creates a goal from predicate, subject, and fact_value.\n"
  @spec create_goal(String.t(), String.t(), AriaEngine.State.fact_value()) :: goal()
  def create_goal(predicate, subject, fact_value) do
    {predicate, subject, fact_value}
  end

  @doc "Creates a task from name and arguments.\n"
  @spec create_task(String.t(), list()) :: Core.task()
  def create_task(name, args \\ []) do
    {name, args}
  end

  @doc "Validates whether goals are satisfied in the given state.\n"
  @spec goals_satisfied?(AriaEngine.State.t(), [goal()]) :: boolean()
  def goals_satisfied?(%AriaEngine.State{} = state, goals) do
    Enum.all?(goals, fn {predicate, subject, fact_value} ->
      AriaEngine.State.get_fact(state, predicate, subject) == fact_value
    end)
  end
end