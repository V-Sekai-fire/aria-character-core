# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule Multigoal do
  @moduledoc """
  Represents a collection of goals in the GTPyhop planner.

  A multigoal is essentially a desired state represented as a collection of
  predicate-subject-fact triples that should be true in the world state.

  Example:
  ```elixir
  multigoal = Multigoal.new()
  |> Multigoal.add_goal("location", "player", "treasure_room")
  |> Multigoal.add_goal("has", "player", "treasure")

  # Check if goals are satisfied in current state
  satisfied? = Multigoal.satisfied?(multigoal, current_state)
  ```
  """

  alias AriaEngine.StateV2

  @type goal :: {StateV2.predicate(), StateV2.subject(), AriaEngine.StateV2.fact_value()}
  @type t :: %__MODULE__{
    goals: [goal()]
  }

  defstruct goals: []

  @doc """
  Creates a new empty multigoal.
  """
  @spec new() :: t()
  def new do
    %__MODULE__{}
  end

  @doc """
  Creates a multigoal from a list of goals.
  """
  @spec new([goal()]) :: t()
  def new(goals) when is_list(goals) do
    %__MODULE__{goals: goals}
  end

  @doc """
  Creates a multigoal from a StateV2 (all triples become goals).
  """
  @spec from_state(AriaEngine.StateV2.t()) :: t()
  def from_state(%AriaEngine.StateV2{} = state) do
    goals = StateV2.to_triples(state)
    %__MODULE__{goals: goals}
  end

  @doc """
  Adds a single goal to the multigoal.
  """
  @spec add_goal(t(), StateV2.predicate(), StateV2.subject(), AriaEngine.StateV2.fact_value()) :: t()
  def add_goal(%__MODULE__{goals: goals} = multigoal, predicate, subject, fact_value) do
    new_goal = {predicate, subject, fact_value}
    %{multigoal | goals: [new_goal | goals]}
  end

  @doc """
  Adds multiple goals to the multigoal.
  """
  @spec add_goals(t(), [goal()]) :: t()
  def add_goals(%__MODULE__{goals: current_goals} = multigoal, new_goals) do
    %{multigoal | goals: new_goals ++ current_goals}
  end

  @doc """
  Removes a goal from the multigoal.
  """
  @spec remove_goal(t(), StateV2.predicate(), StateV2.subject(), AriaEngine.StateV2.fact_value()) :: t()
  def remove_goal(%__MODULE__{goals: goals} = multigoal, predicate, subject, fact_value) do
    target_goal = {predicate, subject, fact_value}
    filtered_goals = Enum.reject(goals, fn goal -> goal == target_goal end)
    %{multigoal | goals: filtered_goals}
  end

  @doc """
  Checks if all goals in the multigoal are satisfied by the given state.
  """
  @spec satisfied?(t(), AriaEngine.StateV2.t()) :: boolean()
  def satisfied?(%__MODULE__{goals: goals}, %AriaEngine.StateV2{} = state) do
    Enum.all?(goals, fn {predicate, subject, fact_value} ->
      AriaEngine.StateV2.get_fact(state, subject, predicate) == fact_value
    end)
  end

  @doc """
  Returns goals that are not yet satisfied in the given state.
  """
  @spec unsatisfied_goals(t(), AriaEngine.StateV2.t()) :: [goal()]
  def unsatisfied_goals(%__MODULE__{goals: goals}, %AriaEngine.StateV2{} = state) do
    Enum.reject(goals, fn {predicate, subject, fact_value} ->
      AriaEngine.StateV2.get_fact(state, subject, predicate) == fact_value
    end)
  end

  @doc """
  Returns goals that are satisfied in the given state.
  """
  @spec satisfied_goals(t(), AriaEngine.StateV2.t()) :: [goal()]
  def satisfied_goals(%__MODULE__{goals: goals}, %AriaEngine.StateV2{} = state) do
    Enum.filter(goals, fn {predicate, subject, fact_value} ->
      AriaEngine.StateV2.get_fact(state, subject, predicate) == fact_value
    end)
  end

  @doc """
  Checks if the multigoal is empty (has no goals).
  """
  @spec empty?(t()) :: boolean()
  def empty?(%__MODULE__{goals: goals}) do
    Enum.empty?(goals)
  end

  @doc """
  Returns the number of goals in the multigoal.
  """
  @spec size(t()) :: non_neg_integer()
  def size(%__MODULE__{goals: goals}) do
    length(goals)
  end

  @doc """
  Converts the multigoal to a State.
  """
  @spec to_state(t()) :: AriaEngine.StateV2.t()
  def to_state(%__MODULE__{goals: goals}) do
    StateV2.from_triples(goals)
  end

  @doc """
  Gets all goals as a list.
  """
  @spec to_list(t()) :: [goal()]
  def to_list(%__MODULE__{goals: goals}) do
    goals
  end

  @doc """
  Gets all goals as a list (alias for to_list for compatibility).
  """
  @spec get_goals(t()) :: [goal()]
  def get_goals(%__MODULE__{goals: goals}) do
    goals
  end

  @doc """
  Gets all goals as a list (alias for to_list for compatibility).
  """
  @spec to_goals(t()) :: [goal()]
  def to_goals(%__MODULE__{goals: goals}) do
    goals
  end

  @doc """
  Merges two multigoals, combining their goals.
  """
  @spec merge(t(), t()) :: t()
  def merge(%__MODULE__{goals: goals1}, %__MODULE__{goals: goals2}) do
    # Remove duplicates when merging
    combined_goals = (goals1 ++ goals2) |> Enum.uniq()
    %__MODULE__{goals: combined_goals}
  end

  @doc """
  Creates a copy of the multigoal.
  """
  @spec copy(t()) :: t()
  def copy(%__MODULE__{goals: goals}) do
    %__MODULE__{goals: List.duplicate(goals, 1) |> List.flatten()}
  end

  @doc """
  Filters goals based on a predicate function.
  """
  @spec filter(t(), (goal() -> boolean())) :: t()
  def filter(%__MODULE__{goals: goals}, predicate_fn) do
    filtered_goals = Enum.filter(goals, predicate_fn)
    %__MODULE__{goals: filtered_goals}
  end

  @doc """
  Maps over goals, transforming each one.
  """
  @spec map(t(), (goal() -> goal())) :: t()
  def map(%__MODULE__{goals: goals}, transform_fn) do
    transformed_goals = Enum.map(goals, transform_fn)
    %__MODULE__{goals: transformed_goals}
  end

  @doc """
  Built-in method to split a multigoal into individual unigoals.

  This method takes a list of goals and returns them as individual
  unigoals to be achieved sequentially. This is useful when no
  domain-specific multigoal method is available.

  ## Parameters
  - state: The current planning state
  - goals: A list of goal specifications

  ## Returns
  - A list of individual goals to be achieved in order
  - `false` if the goals cannot be split or are invalid

  ## Examples

      iex> state = create_state()
      iex> goals = [["on", "a", "b"], ["on", "b", "table"]]
      iex> Multigoal.split_multigoal(state, goals)
      [["on", "a", "b"], ["on", "b", "table"]]
  """
  @spec split_multigoal(AriaEngine.StateV2.t(), list()) :: list() | false
  def split_multigoal(%AriaEngine.StateV2{} = _state, goals) when is_list(goals) do
    # Filter out any nil or invalid goals
    valid_goals = Enum.filter(goals, &valid_goal?/1)

    case valid_goals do
      [] -> []
      _ -> valid_goals
    end
  end

  def split_multigoal(%AriaEngine.StateV2{} = _state, _goals), do: false

  @doc """
  Check if a goal specification is valid.

  A valid goal should be a list with at least one element.
  """
  @spec valid_goal?(term()) :: boolean()
  def valid_goal?(goal) when is_list(goal) and length(goal) > 0, do: true
  def valid_goal?(_), do: false
end
