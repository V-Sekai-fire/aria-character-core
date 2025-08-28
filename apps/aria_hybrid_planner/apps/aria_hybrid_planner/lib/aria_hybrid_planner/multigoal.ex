# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaEngineCore.Multigoal do
  @moduledoc "Represents a collection of goals in the GTPyhop planner.\n\nA multigoal is essentially a desired state represented as a collection of\npredicate-subject-fact triples that should be true in the world AriaState.\n\nExample:\n```elixir\nmultigoal = AriaEngineCore.Multigoal.new()\n|> AriaEngineCore.Multigoal.add_goal(\"location\", \"player\", \"treasure_room\")\n|> AriaEngineCore.Multigoal.add_goal(\"has\", \"player\", \"treasure\")\n\n# Check if goals are satisfied in current state\nsatisfied? = AriaEngineCore.Multigoal.satisfied?(multigoal, current_state)\n```\n"
  @type goal :: {AriaState.predicate(), AriaState.subject(), AriaState.fact_value()}
  @type t :: %__MODULE__{goals: [goal()]}
  defstruct goals: []
  @doc "Creates a new empty multigoal.\n"
  @spec new() :: t()
  def new do
    %__MODULE__{}
  end

  @doc "Creates a multigoal from a list of goals.\n"
  @spec new([goal()]) :: t()
  def new(goals) when is_list(goals) do
    %__MODULE__{goals: goals}
  end

  @doc "Creates a multigoal from a State (all triples become goals).\n"
  @spec from_state(AriaState.t()) :: t()
  def from_state(state) do
    goals = AriaState.to_triples(state)
    %__MODULE__{goals: goals}
  end

  @doc "Adds a single goal to the multigoal.\n"
  @spec add_goal(t(), AriaState.predicate(), AriaState.subject(), AriaState.fact_value()) :: t()
  def add_goal(%__MODULE__{goals: goals} = multigoal, predicate, subject, fact_value) do
    new_goal = {predicate, subject, fact_value}
    %{multigoal | goals: [new_goal | goals]}
  end

  @doc "Adds multiple goals to the multigoal.\n"
  @spec add_goals(t(), [goal()]) :: t()
  def add_goals(%__MODULE__{goals: current_goals} = multigoal, new_goals) do
    %{multigoal | goals: new_goals ++ current_goals}
  end

  @doc "Removes a goal from the multigoal.\n"
  @spec remove_goal(t(), AriaState.predicate(), AriaState.subject(), AriaState.fact_value()) :: t()
  def remove_goal(%__MODULE__{goals: goals} = multigoal, predicate, subject, fact_value) do
    target_goal = {predicate, subject, fact_value}
    filtered_goals = Enum.reject(goals, fn goal -> goal == target_goal end)
    %{multigoal | goals: filtered_goals}
  end

  @doc "Checks if all goals in the multigoal are satisfied by the given AriaState.\n"
  @spec satisfied?(t(), AriaState.t()) :: boolean()
  def satisfied?(%__MODULE__{goals: goals}, state) do
    Enum.all?(goals, fn {predicate, subject, fact_value} ->
      AriaState.get_fact(state, predicate, subject) == fact_value
    end)
  end

  @doc "Returns goals that are not yet satisfied in the given AriaState.\n"
  @spec unsatisfied_goals(t(), AriaState.t()) :: [goal()]
  def unsatisfied_goals(%__MODULE__{goals: goals}, state) do
    Enum.reject(goals, fn {predicate, subject, fact_value} ->
      AriaState.get_fact(state, predicate, subject) == fact_value
    end)
  end

  @doc "Returns goals that are satisfied in the given AriaState.\n"
  @spec satisfied_goals(t(), AriaState.t()) :: [goal()]
  def satisfied_goals(%__MODULE__{goals: goals}, state) do
    Enum.filter(goals, fn {predicate, subject, fact_value} ->
      AriaState.get_fact(state, predicate, subject) == fact_value
    end)
  end

  @doc "Checks if the multigoal is empty (has no goals).\n"
  @spec empty?(t()) :: boolean()
  def empty?(%__MODULE__{goals: goals}) do
    Enum.empty?(goals)
  end

  @doc "Returns the number of goals in the multigoal.\n"
  @spec size(t()) :: non_neg_integer()
  def size(%__MODULE__{goals: goals}) do
    length(goals)
  end

  @doc "Converts the multigoal to a AriaState.\n"
  @spec to_state(t()) :: AriaState.t()
  def to_state(%__MODULE__{goals: goals}) do
    AriaState.from_triples(goals)
  end

  @doc "Gets all goals as a list.\n"
  @spec to_list(t()) :: [goal()]
  def to_list(%__MODULE__{goals: goals}) do
    goals
  end


  @doc "Merges two multigoals, combining their goals.\n"
  @spec merge(t(), t()) :: t()
  def merge(%__MODULE__{goals: goals1}, %__MODULE__{goals: goals2}) do
    combined_goals = (goals1 ++ goals2) |> Enum.uniq()
    %__MODULE__{goals: combined_goals}
  end

  @doc "Creates a copy of the multigoal.\n"
  @spec copy(t()) :: t()
  def copy(%__MODULE__{goals: goals}) do
    %__MODULE__{goals: List.duplicate(goals, 1) |> List.flatten()}
  end

  @doc "Filters goals based on a predicate function.\n"
  @spec filter(t(), (goal() -> boolean())) :: t()
  def filter(%__MODULE__{goals: goals}, predicate_fn) do
    filtered_goals = Enum.filter(goals, predicate_fn)
    %__MODULE__{goals: filtered_goals}
  end

  @doc "Maps over goals, transforming each one.\n"
  @spec map(t(), (goal() -> goal())) :: t()
  def map(%__MODULE__{goals: goals}, transform_fn) do
    transformed_goals = Enum.map(goals, transform_fn)
    %__MODULE__{goals: transformed_goals}
  end

  @doc "Built-in method to split a multigoal into individual unigoals.\n\nThis method takes a list of goals and returns them as individual\nunigoals to be achieved sequentially. This is useful when no\ndomain-specific multigoal method is available.\n\n## Parameters\n- state: The current planning state\n- goals: A list of goal specifications\n\n## Returns\n- A list of individual goals to be achieved in order\n- `false` if the goals cannot be split or are invalid\n\n## Examples\n\n    iex> state = create_state()\n    iex> goals = [[\"on\", \"a\", \"b\"], [\"on\", \"b\", \"table\"]]\n    iex> Multigoal.split_multigoal(state, goals)\n    [[\"on\", \"a\", \"b\"], [\"on\", \"b\", \"table\"]]\n"
  @spec split_multigoal(AriaState.t(), list()) :: list() | false
  def split_multigoal(_state, goals) when is_list(goals) do
    valid_goals = Enum.filter(goals, &valid_goal?/1)

    case valid_goals do
      [] -> []
      _ -> valid_goals
    end
  end

  def split_multigoal(_state, _goals) do
    false
  end

  @doc "Check if a goal specification is valid.\n\nA valid goal should be a list with at least one element.\n"
  @spec valid_goal?(term()) :: boolean()
  def valid_goal?(goal) when is_list(goal) and length(goal) > 0 do
    true
  end

  def valid_goal?(_) do
    false
  end
end
